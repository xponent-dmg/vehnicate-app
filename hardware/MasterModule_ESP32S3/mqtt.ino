/*

//works well but only can transmit small chunks of data- caused by limitations of mqtt. Advised to use http instead to transmit huge chunks of data! So, reverting back to using
//ngrok for transmission and http requests!

#define TINY_GSM_MODEM_BG96  // EC200U is compatible with BG96 AT profile
#include <TinyGsmClient.h>
#include <PubSubClient.h>
#include <Wire.h>
#include "Kalman.h"
#include "kalman_orientation.h"
#include <SD.h>
#include <SPI.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>

// Modem pins and config
#define MODEM_RST          5
#define MODEM_PWRKEY       4
#define MODEM_POWER_ON     23
#define MODEM_TX           13
#define MODEM_RX           12
#define MODEM_BAUDRATE     115200
#define SerialMon          Serial
#define SerialAT           Serial2

// MQTT + GPRS
const char apn[]      = "airtelgprs.com";
const char* broker    = "broker.hivemq.com";  // Public MQTT broker
const int mqttPort    = 1883;
const char* topic     = "esp32s3/hnPdata";

// Globals
TinyGsm modem(SerialAT);
TinyGsmClient client(modem);
PubSubClient mqtt(client);

// MPU6500 and Kalman
const uint8_t MPU_ADDR = 0x68;
Kalman kalAccX, kalAccY, kalAccZ;
Kalman kalGyroX, kalGyroY, kalGyroZ;
KalmanOrientation kalRoll, kalPitch;
uint8_t i2cData[14];

// FreeRTOS
TaskHandle_t sensorTaskHandle, transmitTaskHandle;
SemaphoreHandle_t modemMutex;

// IMU State
float vel_x = 0, vel_y = 0, vel_z = 0;
float prev_accel_x = 0, prev_accel_y = 0, prev_accel_z = 0;
unsigned long last_zupt = 0;
uint32_t timer;

// Buffer
#define BUFFER_SIZE 2
#define MAX_ENTRY_LEN 120
char dataBuffer[BUFFER_SIZE][MAX_ENTRY_LEN];
int bufferIndex = 0;

// I2C read/write
bool i2cRead(uint8_t reg, uint8_t *data, uint8_t len) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false)) return true;
  Wire.requestFrom(MPU_ADDR, len);
  for (uint8_t i = 0; i < len; i++) {
    data[i] = Wire.read();
  }
  return false;
}

// Modem init
void modemInit() {
  pinMode(MODEM_PWRKEY, OUTPUT);
  pinMode(MODEM_RST, OUTPUT);
  pinMode(MODEM_POWER_ON, OUTPUT);
  digitalWrite(MODEM_PWRKEY, LOW);
  digitalWrite(MODEM_RST, HIGH);
  digitalWrite(MODEM_POWER_ON, HIGH);

  SerialAT.begin(MODEM_BAUDRATE, SERIAL_8N1, MODEM_RX, MODEM_TX);
  delay(3000);
  modem.restart();
  SerialMon.println(modem.getModemInfo());

  if (!modem.waitForNetwork()) {
    SerialMon.println("Network failed");
    return;
  }

  if (!modem.gprsConnect(apn, "", "")) {
    SerialMon.println("GPRS failed");
    return;
  }

  mqtt.setServer(broker, mqttPort);
}

// MQTT reconnect
void reconnectMQTT() {
  while (!mqtt.connected()) {
    String clientId = "ESP32EC200U-" + String(random(0xffff), HEX);
    if (mqtt.connect(clientId.c_str())) {
      SerialMon.println("MQTT connected");
    } else {
      SerialMon.print("MQTT failed, rc=");
      SerialMon.print(mqtt.state());
      delay(3000);
    }
  }
}

// IMU data collection
void dataCollectionTask(void *pvParameters) {
  while (1) {
    while (i2cRead(0x3B, i2cData, 14));
    int16_t accX = (i2cData[0] << 8) | i2cData[1];
    int16_t accY = (i2cData[2] << 8) | i2cData[3];
    int16_t accZ = (i2cData[4] << 8) | i2cData[5];
    int16_t gyroX = (i2cData[8] << 8) | i2cData[9];
    int16_t gyroY = (i2cData[10] << 8) | i2cData[11];
    int16_t gyroZ = (i2cData[12] << 8) | i2cData[13];

    double dt = (double)(micros() - timer) / 1000000.0;
    timer = micros();

    double fx = kalAccX.filter(accX, dt);
    double fy = kalAccY.filter(accY, dt);
    double fz = kalAccZ.filter(accZ, dt);
    double gx = kalGyroX.filter(gyroX, dt);
    double gy = kalGyroY.filter(gyroY, dt);
    double gz = kalGyroZ.filter(gyroZ, dt);

    fx /= 16384; fy /= 16384; fz /= 16384;
    float ax_c = fx * 9.81;
    float ay_c = fy * 9.81;
    float az_c = fz * 9.81;

    float gx_c = gx / 131;
    float gy_c = gy / 131;
    float gz_c = gz / 131;

    float roll = kalRoll.filter(atan2(ay_c, az_c) * RAD_TO_DEG, gx_c, dt);
    float pitch = kalPitch.filter(atan2(-ax_c, sqrt(ay_c*ay_c + az_c*az_c)) * RAD_TO_DEG, gy_c, dt);

    float gravity_x = -9.81 * sin(pitch * DEG_TO_RAD);
    float gravity_y =  9.81 * sin(roll * DEG_TO_RAD) * cos(pitch * DEG_TO_RAD);
    float gravity_z =  9.81 * cos(roll * DEG_TO_RAD) * cos(pitch * DEG_TO_RAD);

    float accel_x = ax_c - gravity_x;
    float accel_y = ay_c - gravity_y;
    float accel_z = az_c - gravity_z;

    vel_x += (prev_accel_x + accel_x) * dt / 2;
    vel_y += (prev_accel_y + accel_y) * dt / 2;
    vel_z += (prev_accel_z + accel_z) * dt / 2;

    prev_accel_x = accel_x;
    prev_accel_y = accel_y;
    prev_accel_z = accel_z;

    // Buffer
    if (bufferIndex < BUFFER_SIZE) {
      snprintf(dataBuffer[bufferIndex], MAX_ENTRY_LEN, "%lu,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f",
        millis(), accel_x, accel_y, accel_z, gx_c, gy_c, gz_c);
      bufferIndex++;
    }

    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}

// MQTT transmit task
void transmitTask(void *pvParameters) {
  while (1) {
    if (bufferIndex > 0 && xSemaphoreTake(modemMutex, portMAX_DELAY) == pdTRUE) {
      if (!mqtt.connected()) reconnectMQTT();
      mqtt.loop();

      String json = "{\"imu\":[";
      for (int i = 0; i < bufferIndex; i++) {
        if (i > 0) json += ",";
        json += "\"" + String(dataBuffer[i]) + "\"";
      }
      json += "]}";
      SerialMon.println(json.c_str());

      if (mqtt.publish(topic, json.c_str())) {
        SerialMon.println("MQTT publish OK");
        bufferIndex = 0;
      } else {
        SerialMon.println("MQTT publish failed");
      }

      xSemaphoreGive(modemMutex);
    }
    vTaskDelay(5000 / portTICK_PERIOD_MS);
  }
}

void setup() {
  SerialMon.begin(115200);
  delay(1000);
  Wire.begin(6, 4); Wire.setClock(400000);

  while (i2cRead(0x75, i2cData, 1));
  if (i2cData[0] != 0x70) {
    SerialMon.println("MPU6500 not found!");
    while (1);
  }

  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B); Wire.write(0x01); Wire.endTransmission();  // Wake
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x19); Wire.write(0x07); Wire.endTransmission();  // 1kHz

  timer = micros();
  modemMutex = xSemaphoreCreateMutex();
  modemInit();

  xTaskCreatePinnedToCore(dataCollectionTask, "IMU", 8192, NULL, 2, &sensorTaskHandle, 0);
  xTaskCreatePinnedToCore(transmitTask, "TX", 8192, NULL, 2, &transmitTaskHandle, 1);
}

void loop() {
  delay(1000);
}
*/