//transmit imu and gps data
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
#define BUTTON_PIN 0
#define LED_PIN 2

// --- APN and server config ---
const char apn[]  = "airtelgprs.com";
const char user[] = "";
const char pass[] = "";
const char server[] = "a16457b53bf2.ngrok-free.app";

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
TaskHandle_t sensorTaskHandle, sdTaskHandle, transmitTaskHandle, gpsTaskHandle;
SemaphoreHandle_t modemMutex;

// --- Sensor variables ---
uint8_t i2cData[14];
uint32_t timer;
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

// --- GPS data structure ---
typedef struct {
  float latitude;
  float longitude;
  bool valid;
} GpsData_t;

// --- Global GPS data ---
volatile GpsData_t lastGpsData = {0.0f, 0.0f, false};

// --- Queue for sensor data ---
#define QUEUE_LENGTH 50
#define QUEUE_ITEM_SIZE sizeof(SensorData_t)
QueueHandle_t sensorQueue;

// --- SD write buffer ---
#define SD_BUFFER_SIZE 100
#define MAX_ENTRY_LEN 150
char sdBuffer[SD_BUFFER_SIZE][MAX_ENTRY_LEN];
int sdBufferIndex = 0;

// --- Mode flag ---
volatile bool transmitMode = false;
volatile bool setup_complete = false;

// --- I2C functions ---
bool i2cWrite(uint8_t reg, uint8_t data, bool sendStop) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(data);
  return Wire.endTransmission(sendStop) == 0;
}
bool i2cWrite(uint8_t reg, uint8_t *data, uint8_t length, bool sendStop) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(data, length);
  return Wire.endTransmission(sendStop) == 0;
}
bool i2cRead(uint8_t reg, uint8_t *data, uint8_t length) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return true;
  Wire.requestFrom(MPU_ADDR, length);
  uint8_t i = 0;
  while (Wire.available() && i < length) data[i++] = Wire.read();
  return false;
}

// --- Helper: send AT command and wait response with timeout and optional response string ---
bool sendATCommand(const char* cmd, uint32_t delayMs = 200, uint32_t waitMs = 2000, String* response = nullptr) {
  modem.sendAT(cmd);
  delay(delayMs);
  int respCode;
  if (response) {
    respCode = modem.waitResponse(waitMs, *response);
  } else {
    respCode = modem.waitResponse(waitMs);
  }
  SerialMon.printf("AT Command: %s, Response code: %d\n", cmd, respCode);
  if (response && respCode == 1) SerialMon.println("Response: " + *response);
  return respCode == 1;
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

  sendATCommand("+QHTTPTERM");
  sendATCommand("+QHTTPCFG=\"reset\"", 200, 2000);

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

// --- GPS enable and configuration (called once in gpsTask) ---
bool enableGps() {
  if (!sendATCommand("+QGPS=0")) {  // First turn off GPS if on
    SerialMon.println("Warning: Could not turn off GPS first");
  }
  delay(500);

  // Optional cold start GPS for fresh fix
  // sendATCommand("+QGPSCFG=\"coldstart\",1");
  // delay(500);

  bool success = sendATCommand("+QGPS=1");
  if (success) {
    SerialMon.println("GPS enabled");
  } else {
    SerialMon.println("Failed to enable GPS");
  }
  return success;
}

// --- Retrieve GPS fix status ---
int getGpsFixStatus() {
  modem.sendAT("+QGPS?");
  String resp;
  if (modem.waitResponse(2000, resp) == 1) {
    int idx = resp.indexOf("+QGPS:");
    if (idx >= 0) {
      int comma1 = resp.indexOf(',', idx);
      if (comma1 > 0 && resp.length() > comma1 + 1) {
        char fixChar = resp.charAt(comma1 + 1);
        int fix = fixChar - '0';
        return fix;
      }
    }
  }
  return 0;
}

// --- Get GPS location if fix available ---
bool getGpsLocation(float *lat, float *lon) {
  modem.sendAT("+QGPSLOC=2");
  String gpsResp;
  if (modem.waitResponse(5000, gpsResp) == 1) {
    SerialMon.println("Raw GPS Resp: " + gpsResp);
    int idx = gpsResp.indexOf("+QGPSLOC:");
    if (idx >= 0) {
      String fields = gpsResp.substring(idx + 9);
      fields.trim();
      int firstComma = fields.indexOf(',');
      int secondComma = fields.indexOf(',', firstComma + 1);
      int thirdComma = fields.indexOf(',', secondComma + 1);
      if (firstComma > 0 && secondComma > firstComma && thirdComma > secondComma) {
        String latStr = fields.substring(firstComma + 1, secondComma);
        String lonStr = fields.substring(secondComma + 1, thirdComma);
        float flat = latStr.toFloat();
        float flon = lonStr.toFloat();
        if (abs(flat) > 0.01 && abs(flon) > 0.01) {
          *lat = flat;
          *lon = flon;
          return true;
        }
      }
    }
  }
  return false;
}

// --- Task: GPS monitoring ---
void gpsTask(void* pvParameters) {
  while (!setup_complete) vTaskDelay(10);

  xSemaphoreTake(modemMutex, portMAX_DELAY);

  SerialMon.println("⏳ Enabling GPS...");

  modem.sendAT("+QGPSEND");
  modem.waitResponse();

  modem.sendAT("+QGPSCFG=\"priority\",1");
  modem.waitResponse();

  //modem.sendAT("+QGPSCFG=\"gnssconfig\",1");
  //modem.waitResponse();

  modem.sendAT("+QGPSCFG=\"autogps\",1");
  modem.waitResponse();

  // ====== BEGIN AGPS/XTRA SECTION ======
  SerialMon.println("Enabling AGPS (XTRA)...");
  // Enable AGPS/XTRA
  modem.sendAT("+QGPSXTRA=1"); modem.waitResponse();
  // Download AGPS XTRA data
  SerialMon.println("Downloading XTRA data for AGPS...");
  modem.sendAT("+QFOTADL=\"http://xtrapath1.izatcloud.net/xtra3grc.bin\"");
  if (modem.waitResponse(15000) != 1) {
    SerialMon.println("❌ Failed to download XTRA data.");
  } else {
    SerialMon.println("✅ XTRA data downloaded.");
  }
  modem.sendAT("+QGPSXTRADATA?"); modem.waitResponse();
  modem.sendAT("+QLTS=1"); modem.waitResponse();
  modem.sendAT("+QGPSCFG=\"gnssconfig\",3"); modem.waitResponse();
  // ====== END AGPS/XTRA SECTION =======

  modem.sendAT("+QGPS=1");
  modem.waitResponse(10000); // wait longer to allow GPS to power up

  xSemaphoreGive(modemMutex);

  SerialMon.println("✅ GPS initialized, waiting for fix...");

  while (!transmitMode) {
    xSemaphoreTake(modemMutex, portMAX_DELAY);

    modem.sendAT("+QGPSLOC=2");
    String gpsResp;
    if (modem.waitResponse(10000, gpsResp) == 1) {
      int idx = gpsResp.indexOf("+QGPSLOC:");
      if (idx >= 0) {
        String fields = gpsResp.substring(idx + 9);
        fields.trim();
        int firstComma = fields.indexOf(',');
        int secondComma = fields.indexOf(',', firstComma + 1);
        int thirdComma = fields.indexOf(',', secondComma + 1);

        if (firstComma > 0 && secondComma > firstComma && thirdComma > secondComma) {
          String latStr = fields.substring(firstComma + 1, secondComma);
          String lonStr = fields.substring(secondComma + 1, thirdComma);
          float lat = latStr.toFloat();
          float lon = lonStr.toFloat();

          if (abs(lat) > 0.01 && abs(lon) > 0.01) {
            lastGpsData.latitude = lat;
            lastGpsData.longitude = lon;
            lastGpsData.valid = true;
            SerialMon.printf("✅ GPS FIX: LAT=%.6f, LON=%.6f\n", lat, lon);
          } else {
            lastGpsData.valid = false;
            SerialMon.println("⚠️ No fix yet (coords are zeros)");
          }
        }
      } else {
        SerialMon.println("⚠️ +QGPSLOC not found in response");
      }
    } else {
      SerialMon.println("❌ Timeout waiting for +QGPSLOC");
    }

    xSemaphoreGive(modemMutex);
    vTaskDelay(5000 / portTICK_PERIOD_MS);  // wait before next attempt
  }

  // Stop GPS before exiting
  xSemaphoreTake(modemMutex, portMAX_DELAY);
  modem.sendAT("+QGPSEND");
  modem.waitResponse();
  xSemaphoreGive(modemMutex);

  vTaskDelete(NULL);
}


// --- Sensor read task ---
void sensorReadTask(void *pvParameters) {
  while (!setup_complete) vTaskDelay(10);

  while (1) {
    if (transmitMode) vTaskSuspend(NULL);

    while (i2cRead(0x3B, i2cData, 14));

    int16_t accX = (i2cData[0] << 8) | i2cData[1];
    int16_t accY = (i2cData[2] << 8) | i2cData[3];
    int16_t accZ = (i2cData[4] << 8) | i2cData[5];
    int16_t gyroX = (i2cData[8] << 8) | i2cData[9];
    int16_t gyroY = (i2cData[10] << 8) | i2cData[11];
    int16_t gyroZ = (i2cData[12] << 8) | i2cData[13];

    static uint32_t prevMicros = micros();
    double dt = (double)(micros() - prevMicros) / 1000000.0;
    prevMicros = micros();

    double filtAccX = kalAccX.filter(accX, dt);
    double filtAccY = kalAccY.filter(accY, dt);
    double filtAccZ = kalAccZ.filter(accZ, dt);
    double filtGyroX = kalGyroX.filter(gyroX, dt);
    double filtGyroY = kalGyroY.filter(gyroY, dt);
    double filtGyroZ = kalGyroZ.filter(gyroZ, dt);

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

    float gx_c = (float)filtGyroX / 131.0 - gyro_offset_x;
    float gy_c = (float)filtGyroY / 131.0 - gyro_offset_y;
    float gz_c = (float)filtGyroZ / 131.0 - gyro_offset_z;

    float rollAcc = atan2(ay_c, az_c) * RAD_TO_DEG;
    float pitchAcc = atan2(-ax_c, sqrt(ay_c * ay_c + az_c * az_c)) * RAD_TO_DEG;

    float roll = kalRoll.filter(rollAcc, gx_c, dt);
    float pitch = kalPitch.filter(pitchAcc, gy_c, dt);

    float gravity_x = -9.80665 * sin(pitch * DEG_TO_RAD);
    float gravity_y = 9.80665 * sin(roll * DEG_TO_RAD) * cos(pitch * DEG_TO_RAD);
    float gravity_z = 9.80665 * cos(roll * DEG_TO_RAD) * cos(pitch * DEG_TO_RAD);

    float accel_x=ax_c-gravity_x;
    float accel_y=ay_c-gravity_y;
    float accel_z=az_c-gravity_z;


    SensorData_t sensorData = {
      .timestamp = millis(),
      .accel_x = accel_x,
      .accel_y = accel_y,
      .accel_z = accel_z,
      .gx_c = gx_c,
      .gy_c = gy_c,
      .gz_c = gz_c
    };

    // Print IMU and latest GPS data
    if (lastGpsData.valid) {
      SerialMon.printf("T:%lu, Ax: %.6f, Ay: %.6f, Az: %.6f, Gx: %.6f, Gy: %.6f, Gz: %.6f, Lat: %.6f, Lon: %.6f\n",
                       sensorData.timestamp,
                       sensorData.accel_x,
                       sensorData.accel_y,
                       sensorData.accel_z,
                       sensorData.gx_c,
                       sensorData.gy_c,
                       sensorData.gz_c,
                       lastGpsData.latitude,
                       lastGpsData.longitude);
    } else {
      SerialMon.printf("T:%lu, Ax: %.6f, Ay: %.6f, Az: %.6f, Gx: %.6f, Gy: %.6f, Gz: %.6f, GPS: No Fix\n",
                       sensorData.timestamp,
                       sensorData.accel_x,
                       sensorData.accel_y,
                       sensorData.accel_z,
                       sensorData.gx_c,
                       sensorData.gy_c,
                       sensorData.gz_c);
    }

    if (xQueueSend(sensorQueue, &sensorData, 0) != pdPASS) {
      SerialMon.println("Queue full! Dropping data");
    }

    vTaskDelay(pdMS_TO_TICKS(10));
  }
}

// --- SD write task ---
void sdWriteTask(void *pvParameters) {
  SensorData_t receivedData;
  unsigned long lastFlush = millis();

  while (1) {
    if (transmitMode) {
      // Flush remaining buffer on transmit mode start
      if (sdBufferIndex > 0) {
        File dataFile = SD.open(SD_FILE, FILE_APPEND);
        if (dataFile) {
          for (int i = 0; i < sdBufferIndex; i++) {
            dataFile.println(sdBuffer[i]);
          }
          dataFile.close();
          SerialMon.printf("Flushed %d entries on transmit mode start\n", sdBufferIndex);
          sdBufferIndex = 0;
        }
      }
      vTaskDelete(NULL);  // exit task on transmit mode
    }

    // Wait max 100ms for new queue data, to avoid starving CPU
    if (xQueueReceive(sensorQueue, &receivedData, pdMS_TO_TICKS(100)) == pdPASS) {
      snprintf(sdBuffer[sdBufferIndex], sizeof(sdBuffer[0]),
               "%lu,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f",
               receivedData.timestamp,
               receivedData.accel_x,
               receivedData.accel_y,
               receivedData.accel_z,
               receivedData.gx_c,
               receivedData.gy_c,
               receivedData.gz_c,
               lastGpsData.latitude,
               lastGpsData.longitude);
      sdBufferIndex++;
    }

    // Flush if buffer is full or every 3 seconds if buffer has data
    if (sdBufferIndex >= SD_BUFFER_SIZE){//|| (sdBufferIndex > 0 && millis() - lastFlush > 3000)) {
      File dataFile = SD.open(SD_FILE, FILE_APPEND);
      if (dataFile) {
        for (int i = 0; i < sdBufferIndex; i++) {
          dataFile.println(sdBuffer[i]);
        }
        dataFile.close();
        SerialMon.printf("Flushed %d entries to SD\n", sdBufferIndex);
        sdBufferIndex = 0;
        lastFlush = millis();
      } else {
        SerialMon.println("SD write error! Clearing buffer to avoid repetition.");
        sdBufferIndex = 0;
      }
    }
  }
}

/*
// --- Transmission task ---
void transmitTask(void *pvParameters) {
  while (!setup_complete) vTaskDelay(pdMS_TO_TICKS(10));

  for (;;) {
    if (!transmitMode) {
      digitalWrite(LED_PIN, LOW);
      vTaskDelay(pdMS_TO_TICKS(500));
      continue;
    }
    digitalWrite(LED_PIN, HIGH);
    SerialMon.println("Transmission mode started.");

    File dataFile = SD.open(SD_FILE, FILE_READ);
    if (!dataFile) {
      SerialMon.println("No SD data file found for transmission.");
      vTaskDelay(pdMS_TO_TICKS(2000));
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
        float ax, ay, az, gx, gy, gz, lat, lon;
        int parsed = sscanf(line.c_str(), "%lu,%f,%f,%f,%f,%f,%f,%f,%f",
                            &timestamp, &ax, &ay, &az, &gx, &gy, &gz, &lat, &lon);
        if (parsed == 9) {
          if (!first) jsonData += ",";
          jsonData += "{\"t\":" + String(timestamp) +
                      ",\"x\":" + String(ax, 3) +
                      ",\"y\":" + String(ay, 3) +
                      ",\"z\":" + String(az, 3) +
                      ",\"gx\":" + String(gx, 3) +
                      ",\"gy\":" + String(gy, 3) +
                      ",\"gz\":" + String(gz, 3) +
                      ",\"lat\":" + String(lat, 6) +
                      ",\"lon\":" + String(lon, 6) + "}";
          first = false;
          lineCount++;
        }
      }
      jsonData += "]}";

      SerialMon.println("Sending batch...");

      if (!sendATCommand("+QICSGP=1,1,\"airtelgprs.com\",\"\",\"\",1", 500, 2000)) {
        SerialMon.println("Failed to set APN");
        break;
      }
      if (!sendATCommand("+QIACT=1", 1000, 10000)) {
        SerialMon.println("Failed to activate bearer");
        break;
      }
      if (!sendATCommand("+QHTTPCFG=\"contextid\",1", 200, 2000)) {
        SerialMon.println("Failed HTTP context setup");
        break;
      }

      String url = "http://" + String(server) + "/api";
      modem.sendAT("+QHTTPURL=" + String(url.length()) + ",60");
      if (modem.waitResponse(5000, "CONNECT") != 1) {
        SerialMon.println("URL setup failed");
        break;
      }
      modem.stream.print(url);
      if (modem.waitResponse(10000) != 1) {
        SerialMon.println("URL send failed");
        break;
      }

      modem.sendAT("+QHTTPPARA=\"USERDATA\",\"ngrok-skip-browser-warning: true\"");
      if (modem.waitResponse(2000) != 1) {
        SerialMon.println("Failed to set HTTP parameters");
        break;
      }

      modem.sendAT("+QHTTPPOST=" + String(jsonData.length()) + ",60,60");
      if (modem.waitResponse(10000, "CONNECT") != 1) {
        SerialMon.println("HTTP POST setup failed");
        break;
      }
      modem.stream.print(jsonData);

      String postResponse;
      if (modem.waitResponse(30000, postResponse) == 1) {
        SerialMon.println("POST OK: " + postResponse);
      } else {
        SerialMon.println("POST failed");
        break;
      }

      vTaskDelay(pdMS_TO_TICKS(3000));
    }
    dataFile.close();

    if (SD.remove(SD_FILE)) {
      SerialMon.println("Data file deleted after transmission.");
    } else {
      SerialMon.println("Failed to delete data file after transmission.");
    }
    // Create new empty data log file
    File f = SD.open(SD_FILE, FILE_WRITE);
    if (f) f.close();

    SerialMon.println("Transmission complete. Halting transmission task.");
    digitalWrite(LED_PIN, LOW);

    vTaskDelete(NULL);
  }
}
*/
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

    const int MAX_LINES_PER_BATCH = 500;
    while (dataFile.available()) {
      String jsonData = "{\"id\":\"ESP32_MPU6500\",\"data\":[";
      int lineCount = 0;
      bool first = true;
      while (dataFile.available() && lineCount < MAX_LINES_PER_BATCH) {
        String line = dataFile.readStringUntil('\n');
        line.trim();
        if (line.length() == 0) continue;

        unsigned long timestamp;
        float ax, ay, az, gx, gy, gz, lat, lon;
        int parsed = sscanf(line.c_str(), "%lu,%f,%f,%f,%f,%f,%f,%f,%f",
                            &timestamp, &ax, &ay, &az, &gx, &gy, &gz, &lat, &lon);
        if (parsed == 9) {
          if (!first) jsonData += ",";
          jsonData += "{\"t\":" + String(timestamp) +
                      ",\"x\":" + String(ax, 3) +
                      ",\"y\":" + String(ay, 3) +
                      ",\"z\":" + String(az, 3) +
                      ",\"gx\":" + String(gx, 3) +
                      ",\"gy\":" + String(gy, 3) +
                      ",\"gz\":" + String(gz, 3) +
                      ",\"lat\":" + String(lat, 6) +
                      ",\"lon\":" + String(lon, 6) + "}";
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
  while (!i2cWrite(0x19, 0x07, true));
  while (!i2cWrite(0x19, initData, 4, false));
  while (!i2cWrite(0x6B, 0x01, true));
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
  SerialMon.printf("Gyro Offsets: X=%.6f, Y=%.6f, Z=%.6f\n", gyro_offset_x, gyro_offset_y, gyro_offset_z);

  modemInit();

  sensorQueue = xQueueCreate(QUEUE_LENGTH, QUEUE_ITEM_SIZE);
  if (!sensorQueue) {
    SerialMon.println("Queue creation failed!");
    while(1);
  }

  xTaskCreatePinnedToCore(gpsTask, "GpsTask", 4096, NULL, 3, &gpsTaskHandle, 1);
  vTaskDelay(30000 / portTICK_PERIOD_MS);
  xTaskCreatePinnedToCore(sensorReadTask, "SensorTask", 4096, NULL, 2, &sensorTaskHandle, 0);
  xTaskCreatePinnedToCore(sdWriteTask, "SDTask", 8192, NULL, 1, &sdTaskHandle, 1);

  setup_complete = true;
}

void loop() {
  static bool wasPressed = false;
  if (digitalRead(BUTTON_PIN) == LOW && !wasPressed) {
    transmitMode = true;
    wasPressed = true;
    SerialMon.println("Button pressed -> STARTING TRANSMISSION MODE");
    xTaskCreatePinnedToCore(transmitTask, "TransmitTask", 8192, NULL, 2, &transmitTaskHandle, 1);
  }
  if (digitalRead(BUTTON_PIN) == HIGH && wasPressed) {
    wasPressed = false;
  }
  delay(100);
}
