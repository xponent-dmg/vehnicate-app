/*
#define TINY_GSM_MODEM_BG96

#include <Wire.h>
#include "Kalman.h"
#include "kalman_orientation.h"
#include <TinyGsmClient.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>

// Hardware Configuration - ESP32-S3 + EC200U
#define MODEM_PWRKEY       4
#define MODEM_TX           13
#define MODEM_RX           12
#define MODEM_BAUDRATE     115200
#define I2C_SDA            6
#define I2C_SCL            4

// Network Configuration
const char apn[] = "airtelgprs.com";
const char server[] = "5b2e-2401-4900-1f2a-50e3-cd1c-3e94-a7f0-9842.ngrok-free.app";

// Global Objects
TinyGsm modem(Serial2);
SemaphoreHandle_t modemMutex;
TaskHandle_t sensorTaskHandle, transmitTaskHandle;

// Data Management
#define BUFFER_SIZE 50
char dataBuffer[BUFFER_SIZE][120];
volatile int bufferIndex = 0;
const unsigned long TRANSMISSION_INTERVAL = 30000;
unsigned long lastTransmissionTime = 0;

// IMU Variables
uint8_t i2cData[14];
uint32_t timer;
Kalman kalAcc[3], kalGyro[3];
KalmanOrientation kalRoll, kalPitch;

// I2C Functions
bool i2cWrite(uint8_t reg, uint8_t data) {
  Wire.beginTransmission(0x68);
  Wire.write(reg);
  Wire.write(data);
  return Wire.endTransmission() == 0;
}

bool i2cRead(uint8_t reg, uint8_t *data, uint8_t length) {
  Wire.beginTransmission(0x68);
  Wire.write(reg);
  if (Wire.endTransmission(false)) return false;
  Wire.requestFrom(0x68, length);
  for (uint8_t i = 0; i < length && Wire.available(); i++) {
    data[i] = Wire.read();
  }
  return true;
}

// Modem Initialization
void modemInit() {
  pinMode(MODEM_PWRKEY, OUTPUT);
  digitalWrite(MODEM_PWRKEY, LOW);
  delay(100);
  digitalWrite(MODEM_PWRKEY, HIGH);
  delay(1000);
  
  Serial2.begin(MODEM_BAUDRATE, SERIAL_8N1, MODEM_RX, MODEM_TX);
  delay(3000);
  
  Serial.println("Initializing modem...");
  modem.restart();
  
  Serial.println("Waiting for network...");
  if (!modem.waitForNetwork(60000)) {
    Serial.println("Network not found!");
    while(1);
  }
  
  Serial.println("Connecting to GPRS...");
  if (!modem.gprsConnect(apn, "", "")) {
    Serial.println("GPRS connection failed!");
    while(1);
  }
  Serial.println("GPRS connected");
}

// Print modem responses for debugging
void printModemResponses() {
  while (Serial2.available()) {
    Serial.write(Serial2.read());
  }
}

// Sensor Data Collection Task
void dataCollectionTask(void *pvParameters) {
  const float calib[3][3] = {
    {0.00, -0.02020, -0.01010305},
    {-0.010004, 0.00, 0.010004},
    {-0.000198, 0.01981, 0.00}
  };
  
  float gyro_offset[3] = {6.05, -2.33, 1.45}; // Calibrated offsets
  
  for(;;) {
    if(i2cRead(0x3B, i2cData, 14)) {
      // Process accelerometer
      float acc[3] = {
        (int16_t)(i2cData[0] << 8 | i2cData[1]),
        (int16_t)(i2cData[2] << 8 | i2cData[3]),
        (int16_t)(i2cData[4] << 8 | i2cData[5])
      };
      
      // Process gyroscope
      float gyro[3] = {
        (int16_t)(i2cData[8] << 8 | i2cData[9]) / 131.0f - gyro_offset[0],
        (int16_t)(i2cData[10] << 8 | i2cData[11]) / 131.0f - gyro_offset[1],
        (int16_t)(i2cData[12] << 8 | i2cData[13]) / 131.0f - gyro_offset[2]
      };
      
      // Kalman filtering
      float dt = (micros() - timer) / 1000000.0f;
      timer = micros();
      
      for (int i = 0; i < 3; i++) {
        acc[i] = kalAcc[i].filter(acc[i], dt) / 16384.0f;
        gyro[i] = kalGyro[i].filter(gyro[i], dt);
      }
      
      // Calibration
      float ax_c = (1.00202*(acc[0]-0.00) + calib[0][1]*(acc[1]-0.00) + calib[0][2]*(acc[2]-0.03)) * 9.80665;
      float ay_c = (calib[1][0]*(acc[0]-0.00) + 1.0004*(acc[1]-0.00) + calib[1][2]*(acc[2]-0.03)) * 9.80665;
      float az_c = (calib[2][0]*(acc[0]-0.00) + calib[2][1]*(acc[1]-0.00) + 0.9902971*(acc[2]-0.03)) * 9.80665;
      
      // Prepare data string
      char dataString[120];
      snprintf(dataString, sizeof(dataString), "%lu,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f",
               millis(), ax_c, ay_c, az_c, gyro[0], gyro[1], gyro[2]);
      
      // Add to buffer (circular buffer)
      if (bufferIndex < BUFFER_SIZE) {
        strncpy(dataBuffer[bufferIndex], dataString, sizeof(dataBuffer[0]));
        bufferIndex++;
      } else {
        // Shift buffer to make space
        memmove(dataBuffer, dataBuffer + 1, sizeof(dataBuffer) - sizeof(dataBuffer[0]));
        strncpy(dataBuffer[BUFFER_SIZE - 1], dataString, sizeof(dataBuffer[0]));
      }
    }
    vTaskDelay(10 / portTICK_PERIOD_MS);  // 100Hz sampling
  }
}


// CORRECTED & SIMPLIFIED Data Transmission Task
void transmitTask(void *pvParameters) {
  for (;;) {
    if (millis() - lastTransmissionTime > TRANSMISSION_INTERVAL && bufferIndex > 0) {
      if (xSemaphoreTake(modemMutex, portMAX_DELAY) == pdTRUE) {
        // Build JSON (unchanged)
        String jsonData = "{\"id\":\"ESP32_MPU6500\",\"data\":[";
        // ... [JSON building code] ...
        jsonData += "]}";
        
        Serial.print("JSON length: ");
        Serial.println(jsonData.length());

        // Configure HTTP
        modem.sendAT("+QHTTPCFG=\"contextid\",1");
        modem.waitResponse(1000);
        
        // Use automatic headers
        modem.sendAT("+QHTTPCFG=\"requestheader\",0");
        modem.waitResponse(1000);
        
        // Set custom headers
        modem.sendAT("+QHTTPHEAD=1,\"Content-Type: application/json\"");
        modem.waitResponse(1000);
        modem.sendAT("+QHTTPHEAD=2,\"ngrok-skip-browser-warning: true\"");
        modem.waitResponse(1000);
        
        // Set URL
        String url = "http://" + String(server) + "/api";
        Serial.print("Setting URL: ");
        Serial.println(url);
        
        modem.sendAT("+QHTTPURL=" + String(url.length()) + ",80");
        if (modem.waitResponse(5000) == 1) {
          // Send URL when modem says CONNECT
          while (!Serial2.available()); // Wait for data
          String response = Serial2.readStringUntil('\n');
          Serial.print("<<< ");
          Serial.println(response);
          
          if (response.indexOf("CONNECT") >= 0) {
            Serial2.print(url);
            Serial2.flush();
            Serial.println("URL sent");
            
            // Wait for URL confirmation
            modem.waitResponse(5000);
          }
        }

        // Send POST
        Serial.println("Sending POST command");
        modem.sendAT("+QHTTPPOST=" + String(jsonData.length()) + ",80,80");
        
        if (modem.waitResponse(5000) == 1) {
          // Wait for CONNECT to send data
          while (!Serial2.available());
          String response = Serial2.readStringUntil('\n');
          Serial.print("<<< ");
          Serial.println(response);
          
          if (response.indexOf("CONNECT") >= 0) {
            // Send ONLY JSON body
            Serial2.print(jsonData);
            Serial2.flush();
            Serial.println("JSON body sent");
            
            // Wait for POST confirmation
            if (modem.waitResponse(10000) == 1) {
              Serial.println("POST successful");
              
              // Read response
              modem.sendAT("+QHTTPREAD=80");
              modem.waitResponse(10000);
              printModemResponses();
            } else {
              Serial.println("POST confirmation timeout");
            }
          }
        } else {
          Serial.println("POST command failed");
        }

        // Reset buffer
        bufferIndex = 0;
        lastTransmissionTime = millis();
        xSemaphoreGive(modemMutex);
      }
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}


void setup() {
  Serial.begin(115200);
  
  // Initialize I2C
  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(400000);
  
  // Initialize MPU6500
  i2cWrite(0x6B, 0x01);
  i2cWrite(0x19, 0x07);
  i2cWrite(0x1A, 0x00);
  
  // Initialize modem
  modemMutex = xSemaphoreCreateMutex();
  modemInit();
  
  // Create tasks
  xTaskCreatePinnedToCore(dataCollectionTask, "DataCollect", 8192, NULL, 3, &sensorTaskHandle, 0);
  xTaskCreatePinnedToCore(transmitTask, "Transmit", 16384, NULL, 2, &transmitTaskHandle, 1);
  
  Serial.println("System initialized");
}

void loop() {
  // Monitor heap and task status
  static unsigned long lastHeapCheck = 0;
  if (millis() - lastHeapCheck > 10000) {
    Serial.print("Free heap: ");
    Serial.println(ESP.getFreeHeap());
    lastHeapCheck = millis();
  }
  delay(1000);
}
*/