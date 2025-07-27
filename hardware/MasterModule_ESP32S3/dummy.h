//perfectly working code that stores imu data on sd card and when boot button is pressed, transmits to server successfully.
#include <Wire.h>
#include <SD.h>
#include <SPI.h>
#include "Kalman.h"
#include "kalman_orientation.h"
#define TINY_GSM_MODEM_BG96
#include <TinyGsmClient.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include <WiFi.h>

// --- Modem configuration ---
#define MODEM_RST          5
#define MODEM_PWRKEY       4
#define MODEM_POWER_ON     23
#define MODEM_TX           13
#define MODEM_RX           12
#define MODEM_BAUDRATE     115200

// --- SD Card configuration ---
#define SD_MOSI 15
#define SD_MISO 16
#define SD_SCK  17
#define SD_CS   18
const char* SD_FILE = "/data.csv";

// --- Button and LED pins ---
#define BUTTON_PIN 0  // BOOT button
#define LED_PIN 2     // LED during transmission

// --- APN and server config ---
const char apn[]  = "airtelgprs.com";
const char user[] = "";
const char pass[] = "";
const char server[] = "9cf7-2401-4900-1f2b-b4a6-a9fd-9fcf-c39c-d9d1.ngrok-free.app"; //ngrok http url. obtain by running ngrok from terminal- "ngrok htttp --scheme http 5000"

// --- Serial setup ---
#define SerialMon Serial
#define SerialAT  Serial2

TinyGsm modem(SerialAT);
TinyGsmClient client(modem);

// --- MPU6500 address ---
const uint8_t MPU_ADDR = 0x68;

// --- Kalman filters ---
Kalman kalAccX, kalAccY, kalAccZ;
Kalman kalGyroX, kalGyroY, kalGyroZ;
KalmanOrientation kalRoll, kalPitch;

// --- FreeRTOS components ---
TaskHandle_t sensorTaskHandle, sdTaskHandle, transmitTaskHandle;
SemaphoreHandle_t modemMutex;

// --- Sensor variables ---
uint8_t i2cData[14];
uint32_t timer;
float vel_x = 0, vel_y = 0, vel_z = 0;
float prev_accel_x = 0, prev_accel_y = 0, prev_accel_z = 0;
unsigned long last_zupt = 0;
float gyro_offset_x = 0, gyro_offset_y = 0, gyro_offset_z = 0;

// --- SD Card SPI instance ---
SPIClass spiSD(HSPI);

// --- Sensor data structure ---
typedef struct {
  unsigned long timestamp;
  float accel_x;
  float accel_y;
  float accel_z;
  float gx_c;
  float gy_c;
  float gz_c;
} SensorData_t;

// --- Queue for sensor data ---
#define QUEUE_LENGTH 50
#define QUEUE_ITEM_SIZE sizeof(SensorData_t)
QueueHandle_t sensorQueue;

// --- SD write buffer ---
#define SD_BUFFER_SIZE 100
#define MAX_ENTRY_LEN 120
char sdBuffer[SD_BUFFER_SIZE][MAX_ENTRY_LEN];
int sdBufferIndex = 0;

// --- Mode flag ---
volatile bool transmitMode = false;
volatile bool setup_complete = false;

// Define Hotspot credentials
const char* ssid = "ESP32S3-Hotspot";      // Network SSID
const char* password = "esp32s3pass";      // Must be 8 or more characters


// --- I2C functions ---
bool i2cWrite(uint8_t reg, uint8_t data, bool sendStop) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(data);
  return Wire.endTransmission(sendStop);
}
bool i2cWrite(uint8_t reg, uint8_t *data, uint8_t length, bool sendStop) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(data, length);
  return Wire.endTransmission(sendStop);
}
bool i2cRead(uint8_t reg, uint8_t *data, uint8_t length) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false)) return true;
  Wire.requestFrom(MPU_ADDR, length);
  uint8_t i = 0;
  while (Wire.available()) data[i++] = Wire.read();
  return false;
}

// --- Modem initialization ---
void modemInit() {
  pinMode(MODEM_PWRKEY, OUTPUT);
  pinMode(MODEM_RST, OUTPUT);
  pinMode(MODEM_POWER_ON, OUTPUT);

  digitalWrite(MODEM_PWRKEY, LOW);
  digitalWrite(MODEM_RST, HIGH);
  digitalWrite(MODEM_POWER_ON, HIGH);

  delay(100);
  SerialAT.begin(MODEM_BAUDRATE, SERIAL_8N1, MODEM_RX, MODEM_TX);
  delay(3000);

  SerialMon.println("Initializing modem...");
  modem.restart();
  delay(3000);

  modem.sendAT("+QHTTPTERM");
  modem.waitResponse(2000);
  modem.sendAT("+QHTTPCFG=\"reset\"");
  modem.waitResponse(2000);

  SerialMon.print("Modem: ");
  SerialMon.println(modem.getModemInfo());

  SerialMon.print("Waiting for network...");
  if (!modem.waitForNetwork()) {
    SerialMon.println(" fail");
    return;
  }
  SerialMon.println(" OK");

  SerialMon.print("Connecting to ");
  SerialMon.print(apn);
  if (!modem.gprsConnect(apn, user, pass)) {
    SerialMon.println(" fail");
    return;
  }
  SerialMon.println(" OK");

  if (!modem.isNetworkConnected()) {
    SerialMon.println("GPRS not connected properly!");
    return;
  }
  SerialMon.println("Modem setup complete");
}

// --- SD card initialization ---
void sdInit() {
  spiSD.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
  if (!SD.begin(SD_CS, spiSD)) {
    SerialMon.println("SD Card initialization failed!");
    while (1);
  }
  SerialMon.println("SD Card initialized.");
  if (!SD.exists(SD_FILE)) {
    File dataFile = SD.open(SD_FILE, FILE_WRITE);
    dataFile.close();
  }
}

// --- Sensor reading task ---
void sensorReadTask(void *pvParameters) {
  while (!setup_complete) vTaskDelay(10);
  while (1) {
    if (transmitMode) {
      vTaskSuspend(NULL);
      //contiue;
    }

    while (i2cRead(0x3B, i2cData, 14));
    

    int16_t accX = (i2cData[0] << 8) | i2cData[1];
    int16_t accY = (i2cData[2] << 8) | i2cData[3];
    int16_t accZ = (i2cData[4] << 8) | i2cData[5];
    int16_t gyroX = (i2cData[8] << 8) | i2cData[9];
    int16_t gyroY = (i2cData[10] << 8) | i2cData[11];
    int16_t gyroZ = (i2cData[12] << 8) | i2cData[13];

    double dt = (double)(micros() - timer) / 1000000.0;
    timer = micros();

    double filtAccX = kalAccX.filter(accX, dt);
    double filtAccY = kalAccY.filter(accY, dt);
    double filtAccZ = kalAccZ.filter(accZ, dt);
    double filtGyroX = kalGyroX.filter(gyroX, dt);
    double filtGyroY = kalGyroY.filter(gyroY, dt);
    double filtGyroZ = kalGyroZ.filter(gyroZ, dt);

    // Calibration and conversion
    float ax0=0.00, ay0=0.00, az0=0.03, 
          kax=1.00202, kay=1.0004, kaz=0.9902971,
          sax1=-0.02020, sax2=-0.01010305,
          say1=-0.010004, say2=0.010004,
          saz1=-0.000198, saz2=0.01981;
    filtAccX /= 16384;
    filtAccY /= 16384;
    filtAccZ /= 16384;
    float ax_c = (((kax * (filtAccX - ax0)) + (sax1 * (filtAccY - ay0)) + (sax2 * (filtAccZ - az0))))*9.80665;
    float ay_c = (((say1* (filtAccX - ax0)) + (kay * (filtAccY - ay0)) + (say2 * (filtAccZ - az0))))*9.80665;
    float az_c = (((saz1 * (filtAccX - ax0)) + (saz2 * (filtAccY - ay0)) + (kaz * (filtAccZ - az0))))*9.80665;

    float gx_c = (filtGyroX/131) - gyro_offset_x; 
    float gy_c = (filtGyroY/131) - gyro_offset_y;
    float gz_c = (filtGyroZ/131) - gyro_offset_z;

    float rollAcc = atan2(ay_c, az_c) * RAD_TO_DEG;
    float pitchAcc = atan2(-ax_c, sqrt(ay_c * ay_c + az_c * az_c)) * RAD_TO_DEG;

    float roll = kalRoll.filter(rollAcc, gx_c, dt);
    float pitch = kalPitch.filter(pitchAcc, gy_c, dt);

    float gravity_x = -9.80665 * sin(pitch * DEG_TO_RAD);
    float gravity_y = 9.80665 * sin(roll * DEG_TO_RAD) * cos(pitch * DEG_TO_RAD);
    float gravity_z = 9.80665 * cos(roll * DEG_TO_RAD) * cos(pitch * DEG_TO_RAD);

    float accel_x = ax_c - gravity_x;
    float accel_y = ay_c - gravity_y;
    float accel_z = az_c - gravity_z;

    vel_x += (prev_accel_x + accel_x) * dt / 2.0;
    vel_y += (prev_accel_y + accel_y) * dt / 2.0;
    vel_z += (prev_accel_z + accel_z) * dt / 2.0; 

    prev_accel_x = accel_x;
    prev_accel_y = accel_y;
    prev_accel_z = accel_z;

    // Zero velocity update
    float x_threshold = 9.80665*0.03;
    float y_threshold = 9.80665*0.03;
    float z_threshold = 9.80665*0.03;
    if (abs(accel_x) < x_threshold && abs(accel_y) < y_threshold && abs(accel_z) < z_threshold) {
      if (millis() - last_zupt > 500) {
        vel_x = 0;
        vel_y = 0;
        vel_z = 0;
      }
    } else {
      last_zupt = millis();
    }

    // Prepare sensor data struct (ALWAYS copy, never reference)
    SensorData_t sensorData = {
      .timestamp = millis(),
      .accel_x = accel_x,
      .accel_y = accel_y,
      .accel_z = accel_z,
      .gx_c = gx_c,
      .gy_c = gy_c,
      .gz_c = gz_c
    };

    SerialMon.printf("T:%lu, X:%.6f, Y:%.6f, Z:%.6f, GX:%.6f, GY:%.6f, GZ:%.6f\n",
    sensorData.timestamp,
    sensorData.accel_x,
    sensorData.accel_y,
    sensorData.accel_z,
    sensorData.gx_c,
    sensorData.gy_c,
    sensorData.gz_c
    );



    // Send to queue (non-blocking)
    if (xQueueSend(sensorQueue, &sensorData, 0) != pdPASS) {
      SerialMon.println("Queue full! Dropping data");
    }

    vTaskDelay(pdMS_TO_TICKS(10)); // 100Hz sampling
  }
}

// --- SD write task ---
void sdWriteTask(void *pvParameters) {
  SensorData_t receivedData;
  while (1) {
    if (transmitMode) {
  // Final flush
  if (sdBufferIndex > 0) {
    File dataFile = SD.open(SD_FILE, FILE_APPEND);
    if (dataFile) {
      for (int i = 0; i < sdBufferIndex; i++) {
        dataFile.println(sdBuffer[i]);
      }
      dataFile.close();
      sdBufferIndex = 0;
    }
  }
  vTaskDelete(NULL); // Kill SD task permanently after switching to transmit
}


    if (xQueueReceive(sensorQueue, &receivedData, pdMS_TO_TICKS(100)) == pdPASS) {
      snprintf(sdBuffer[sdBufferIndex], sizeof(sdBuffer[0]),
               "%lu,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f",
               receivedData.timestamp,
               receivedData.accel_x,
               receivedData.accel_y,
               receivedData.accel_z,
               receivedData.gx_c,
               receivedData.gy_c,
               receivedData.gz_c);
      sdBufferIndex++;

      // Write buffer to SD when full
      if (sdBufferIndex >= SD_BUFFER_SIZE) {
        File dataFile = SD.open(SD_FILE, FILE_APPEND);
        if (dataFile) {
          for (int i = 0; i < SD_BUFFER_SIZE; i++) {
            dataFile.println(sdBuffer[i]);
          }
          dataFile.close();
          sdBufferIndex = 0;
        } else {
          SerialMon.println("SD write error! Clearing buffer to avoid repetition.");
          sdBufferIndex = 0; // Clear buffer on error to avoid repeated data
        }
      }
    }
  }
}

// --- Transmission task ---
void transmitTask(void *pvParameters) {
  while (!setup_complete) vTaskDelay(10);
  for (;;) {
    if (!transmitMode) {
      digitalWrite(LED_PIN, LOW);
      vTaskDelay(500 / portTICK_PERIOD_MS);
      continue;
    }
    digitalWrite(LED_PIN, HIGH);

    // --- Transmission code ---
    File dataFile = SD.open(SD_FILE, FILE_READ);
    if (!dataFile) {
      SerialMon.println("No SD data for transmission");
      vTaskDelay(2000 / portTICK_PERIOD_MS);
      continue;
    }

    const int MAX_LINES_PER_BATCH = 800;
    while (dataFile.available()) {
      String jsonData = "{\"id\":\"ESP32_MPU6500\",\"data\":[";
      int lineCount = 0;
      bool first = true;
      while (dataFile.available() && lineCount < MAX_LINES_PER_BATCH) {
        String line = dataFile.readStringUntil('\n');
        line.trim();
        if (line.length() == 0) continue;

        unsigned long timestamp;
        float ax, ay, az, gx, gy, gz;
        int parsed = sscanf(line.c_str(), "%lu,%f,%f,%f,%f,%f,%f", &timestamp, &ax, &ay, &az, &gx, &gy, &gz);
        if (parsed == 7) {
          if (!first) jsonData += ",";
          jsonData += "{\"t\":" + String(timestamp) +
                      ",\"x\":" + String(ax, 3) +
                      ",\"y\":" + String(ay, 3) +
                      ",\"z\":" + String(az, 3) +
                      ",\"gx\":" + String(gx, 3) +
                      ",\"gy\":" + String(gy, 3) +
                      ",\"gz\":" + String(gz, 3) + "}";
          first = false;
          lineCount++;
        }
      }
      jsonData += "]}";

      SerialMon.println("Sending batch...");
      modem.sendAT("+QICSGP=1,1,\"airtelgprs.com\",\"\",\"\",1");
      modem.waitResponse(2000);
      modem.sendAT("+QIACT=1");
      modem.waitResponse(10000);
      modem.sendAT("+QHTTPCFG=\"contextid\",1");
      modem.waitResponse(2000);

      String url = "http://" + String(server) + "/api";
      modem.sendAT("+QHTTPURL=" + String(url.length()) + ",60");
      if (modem.waitResponse(5000, "CONNECT") == 1) {
        modem.stream.print(url);
        modem.waitResponse(10000);
      } else {
        SerialMon.println("URL setup failed");
        break;
      }
      modem.sendAT("+QHTTPPARA=\"USERDATA\",\"ngrok-skip-browser-warning: true\"");
      modem.waitResponse(2000);

      modem.sendAT("+QHTTPPOST=" + String(jsonData.length()) + ",60,60");
      if (modem.waitResponse(10000, "CONNECT") != 1) {
        SerialMon.println("POST setup failed");
        break;
      }
      modem.stream.print(jsonData);

      String postResponse;
      if (modem.waitResponse(30000, postResponse) == 1) {
        SerialMon.println("POST OK: " + postResponse);
      } else {
        SerialMon.println("POST failed");
      }
      vTaskDelay(3000 / portTICK_PERIOD_MS);
    }
    dataFile.close();
    digitalWrite(LED_PIN, LOW);

    SD.remove(SD_FILE);
    File f = SD.open(SD_FILE, FILE_WRITE);
    f.close();
    SerialMon.println("All data sent and SD cleared.");

    SerialMon.println("Transmission complete. Halting system...");
    digitalWrite(LED_PIN, LOW);

    // Optionally power off modem or signal done
    // digitalWrite(MODEM_POWER_ON, LOW);

    vTaskDelete(NULL); // Kill transmission task

  }
}

void setup() {
  SerialMon.begin(115200);
  delay(1000);

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  modemMutex = xSemaphoreCreateMutex();

  Wire.begin(6, 7); // SDA=6, SCL=7
  Wire.setClock(400000);

  // MPU6500 init
  uint8_t initData[4] = {7, 0x00, 0x00, 0x00};
  while (i2cWrite(0x19, 0x07, true));
  while (i2cWrite(0x19, initData, 4, false));
  while (i2cWrite(0x6B, 0x01, true));
  while (i2cRead(0x75, i2cData, 1));
  if (i2cData[0] != 0x70) {
    SerialMon.println("MPU6500 not found!");
    while (1);
  }
  SerialMon.println("MPU6500 initialized");

  sdInit();

  kalAccX = Kalman();
  kalAccY = Kalman();
  kalAccZ = Kalman();
  kalGyroX = Kalman();
  kalGyroY = Kalman();
  kalGyroZ = Kalman();
  kalRoll = KalmanOrientation();
  kalPitch = KalmanOrientation();

  timer = micros();
  delay(2000);

  // Calibration
  for (int i=1; i<=3000; i++){
    while (i2cRead(0x3B, i2cData, 14));
    int16_t gyroX_cal = (i2cData[8] << 8) | i2cData[9];
    int16_t gyroY_cal = (i2cData[10] << 8) | i2cData[11];
    int16_t gyroZ_cal = (i2cData[12] << 8) | i2cData[13];

    double dtx = (double)(micros() - timer) / 1000000.0;
    timer = micros();

    double filtGyroX_cal = kalGyroX.filter(gyroX_cal, dtx);
    double filtGyroY_cal = kalGyroY.filter(gyroY_cal, dtx);
    double filtGyroZ_cal = kalGyroZ.filter(gyroZ_cal, dtx);

    gyro_offset_x += filtGyroX_cal/131;
    gyro_offset_y += filtGyroY_cal/131;
    gyro_offset_z += filtGyroZ_cal/131;
    delayMicroseconds(1000);
  }
  gyro_offset_x /= 3000;
  gyro_offset_y /= 3000;
  gyro_offset_z /= 3000;
  SerialMon.println("Calibration complete");
  Serial.println(gyro_offset_x); 
  Serial.println(gyro_offset_y); 
  Serial.println(gyro_offset_z);

  modemInit();

  sensorQueue = xQueueCreate(QUEUE_LENGTH, QUEUE_ITEM_SIZE);
  if (!sensorQueue) {
    SerialMon.println("Queue creation failed!");
    while(1);
  }

  xTaskCreatePinnedToCore(sensorReadTask, "SensorTask", 4096, NULL, 2, &sensorTaskHandle, 0);
  xTaskCreatePinnedToCore(sdWriteTask, "SDTask", 8192, NULL, 1, &sdTaskHandle, 1);
  xTaskCreatePinnedToCore(transmitTask, "TransmitTask", 8192, NULL, 2, &transmitTaskHandle, 1);

  setup_complete = true;
}

void loop() {
  static bool wasPressed = false;
  if (digitalRead(BUTTON_PIN) == LOW && !wasPressed) {
    // Flush SD buffer before switching modes
    transmitMode = true;
    wasPressed = true;
    SerialMon.println("Button pressed -> STARTING TRANSMISSION MODE");
  }
  if (digitalRead(BUTTON_PIN) == HIGH && wasPressed) {
    wasPressed = false;
  }
  delay(100);
}
