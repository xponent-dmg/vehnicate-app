/*
#include <Wire.h>
#include "Kalman.h"
#include "kalman_orientation.h"
#include <SD.h>
#include <SPI.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>

// Sensor data structure for queue
typedef struct {
  unsigned long timestamp;
  float accel_x;
  float accel_y;
  float accel_z;
  float gx_c;
  float gy_c;
  float gz_c;
} SensorData_t;

// Global objects and variables
Kalman kalAccX, kalAccY, kalAccZ;
Kalman kalGyroX, kalGyroY, kalGyroZ;
KalmanOrientation kalRoll, kalPitch;
QueueHandle_t sensorQueue;
TaskHandle_t sensorTaskHandle, sdTaskHandle;

uint8_t i2cData[14];
uint32_t timer;
float vel_x = 0, vel_y = 0, vel_z = 0;
float prev_accel_x = 0, prev_accel_y = 0, prev_accel_z = 0;
unsigned long last_zupt = 0;
float gyro_offset_x=0, gyro_offset_y=0, gyro_offset_z=0;

const uint8_t MPU_ADDR = 0x68;

// SD Card SPI pins
#define SD_MOSI 15
#define SD_MISO 16
#define SD_SCK  17
#define SD_CS   18

#define BUFFER_SIZE 100
#define MAX_ENTRY_LEN 120
char dataBuffer[BUFFER_SIZE][MAX_ENTRY_LEN];
int bufferIndex = 0;

// I2C functions
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

void setup() {
  Serial.begin(115200);
  Wire.begin(6, 4); // SDA=6, SCL=4
  Wire.setClock(400000);

  // Initialize Kalman filters
  kalAccX = Kalman();
  kalAccY = Kalman();
  kalAccZ = Kalman();
  kalGyroX = Kalman();
  kalGyroY = Kalman();
  kalGyroZ = Kalman();
  kalRoll = KalmanOrientation();
  kalPitch = KalmanOrientation();

  // MPU6500 initialization
  i2cData[0] = 7; // Set dlpf to 3600Hz bandwidth
  i2cData[1] = 0x00;
  i2cData[2] = 0x00;
  i2cData[3] = 0x00;
  while (i2cWrite(0x19, i2cData, 4, false));
  while (i2cWrite(0x6B, 0x01, true)); // Wake up MPU6500

  while (i2cRead(0x75, i2cData, 1));
  if (i2cData[0] != 0x70) {
    Serial.println("MPU6500 not found!");
    while (1);
  }

  delay(100);
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
  Serial.println(gyro_offset_x); 
  Serial.println(gyro_offset_y); 
  Serial.println(gyro_offset_z);

  
  // Initialize SD Card
  SPIClass spi = SPIClass(HSPI);
  spi.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);
  if (!(SD.begin(SD_CS, spi))) {
    Serial.println("SD Card initialization failed!");
    while (1);
  }
  Serial.println("SD Card initialized.");
  

  // Create queue (holds 50 sensor readings)
  sensorQueue = xQueueCreate(50, sizeof(SensorData_t));
  if (!sensorQueue) {
    Serial.println("Queue creation failed!");
    while(1);
  }

  // Create tasks
  xTaskCreatePinnedToCore(
    sensorReadTask,    // Task function
    "SensorTask",      // Task name
    4096,              // Stack size (bytes)
    NULL,              // Parameters
    2,                 // Priority (higher)
    &sensorTaskHandle, // Task handle
    0                  // Core 0
  );
  
  
  xTaskCreatePinnedToCore(
    sdWriteTask,       // Task function
    "SDTask",          // Task name
    8192,              // Larger stack for SD ops
    NULL,              // Parameters
    1,                 // Priority (lower)
    &sdTaskHandle,     // Task handle
    1                  // Core 1
  );
  
  
  // Delete default Arduino loop task
  vTaskDelete(NULL);
}

void sensorReadTask(void *pvParameters) {
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

    double filtAccX = kalAccX.filter(accX, dt);
    double filtAccY = kalAccY.filter(accY, dt);
    double filtAccZ = kalAccZ.filter(accZ, dt);

    double filtGyroX = kalGyroX.filter(gyroX, dt);
    double filtGyroY = kalGyroY.filter(gyroY, dt);
    double filtGyroZ = kalGyroZ.filter(gyroZ, dt);

    // Calibration and conversion
    float ax0=0.00, ay0=0.00, az0=0.03, kax=1.00202, kay=1.0004, kaz=0.9902971, 
          sax1=-0.02020, sax2=-0.01010305, say1=-0.010004, say2=0.010004, 
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

    float rollAcc  = atan2(ay_c, az_c) * RAD_TO_DEG;
    float pitchAcc = atan2(-ax_c, sqrt(ay_c * ay_c + az_c * az_c)) * RAD_TO_DEG;

    float roll  = kalRoll.filter(rollAcc, gx_c, dt);
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

    float accel_magnitude = sqrt(accel_x*accel_x + accel_y*accel_y + accel_z*accel_z);
    float x_threshold = 9.80665 * 0.03;
    float y_threshold = 9.80665 * 0.03;
    float z_threshold = 9.80665 * 0.03;
    if (abs(accel_x) < x_threshold && abs(accel_y) < y_threshold && abs(accel_z) < z_threshold) {
      if (millis() - last_zupt > 500) {
        vel_x = 0;
        vel_y = 0;
        vel_z = 0;
      }
    } else {
      last_zupt = millis();
    }

    // Prepare data for queue
    SensorData_t sensorData = {
      .timestamp = millis(),
      .accel_x = accel_x,
      .accel_y = accel_y,
      .accel_z = accel_z,
      .gx_c = gx_c,
      .gy_c = gy_c,
      .gz_c = gz_c
    };

    Serial.printf("T:%lu, X:%.6f, Y:%.6f, Z:%.6f, GX:%.6f, GY:%.6f, GZ:%.6f\n",
    sensorData.timestamp,
    sensorData.accel_x,
    sensorData.accel_y,
    sensorData.accel_z,
    sensorData.gx_c,
    sensorData.gy_c,
    sensorData.gz_c
    );

    //delay(10);
    // Send to queue (non-blocking)
    if (xQueueSend(sensorQueue, &sensorData, 0) != pdPASS) {
      Serial.println("Queue full! Dropping data");
    }

    vTaskDelay(pdMS_TO_TICKS(10)); // 1ms delay = 1000Hz sampling
  }
}

void sdWriteTask(void *pvParameters) {
  SensorData_t receivedData;
  
  while (1) {
    // Wait for data with 100ms timeout
    if (xQueueReceive(sensorQueue, &receivedData, pdMS_TO_TICKS(100)) == pdPASS) {
      // Format data string
      char dataString[MAX_ENTRY_LEN];
      snprintf(dataString, MAX_ENTRY_LEN, "%lu,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f",
               receivedData.timestamp,
               receivedData.accel_x, receivedData.accel_y, receivedData.accel_z,
               receivedData.gx_c, receivedData.gy_c, receivedData.gz_c);

      // Print to serial
      Serial.println(dataString);

      // Add to buffer
      if (bufferIndex < BUFFER_SIZE) {
        strncpy(dataBuffer[bufferIndex], dataString, MAX_ENTRY_LEN);
        bufferIndex++;
      }

      // Write buffer to SD when full
      if (bufferIndex >= BUFFER_SIZE) {
        File dataFile = SD.open("/sensor.csv", FILE_APPEND);
        if (dataFile) {
          for (int i = 0; i < BUFFER_SIZE; i++) {
            dataFile.println(dataBuffer[i]);
          }
          dataFile.close();
          bufferIndex = 0;
        } else {
          Serial.println("Error opening file for writing");
        }
      }
    }
  }
}

// Required empty loop
void loop() {}
*/