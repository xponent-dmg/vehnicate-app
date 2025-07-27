#include "esp_camera.h"
#include "FS.h"
#include "SD_MMC.h"

#define UART_BAUD 115200
#define UART_TX 13  // Example: GPIO13
#define UART_RX 15  // Example: GPIO15
HardwareSerial CamSerial(1);

// Camera pins configuration
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

unsigned long lastCapture = 0;

void setup() {
  CamSerial.begin(UART_BAUD, SERIAL_8N1, UART_RX, UART_TX);

  // Camera configuration
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.xclk_freq_hz = 20000000;         // 20MHz
  config.frame_size = FRAMESIZE_QVGA;     // 320x240 (adjust as needed)
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_LATEST;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 30;               // 0-63 (higher = more compression)
  config.fb_count = 2;

  // Initialize camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    while(1); // Camera init failed
  }

  // Initialize SD card
  if(!SD_MMC.begin()){
    while(1); // SD card failed
  }
}

void loop() {
  // 1. Capture and save images periodically
  if(millis() - lastCapture > 1000){  // 1 FPS (adjust as needed)
    camera_fb_t *fb = esp_camera_fb_get();
    if(fb) {
      String path = "/img" + String(millis()) + ".jpg";
      File file = SD_MMC.open(path.c_str(), FILE_WRITE);
      if(file){
        file.write(fb->buf, fb->len);
        file.close();
      }
      esp_camera_fb_return(fb);
      lastCapture = millis();
    }
  }

  // 2. Wait for SENDIMG command over UART1
  if (CamSerial.available()) {
    String cmd = CamSerial.readStringUntil('\n');
    cmd.trim();
    if (cmd == "SENDIMG") {
      File root = SD_MMC.open("/");
      File file = root.openNextFile();
      while (file) {
        if (!file.isDirectory() && String(file.name()).endsWith(".jpg")) {
          size_t imgSize = file.size();
          // Send ASCII header: IMG:<filename>:<size>\n
          CamSerial.printf("IMG:%s:%d\n", file.name(), imgSize);
          // Send image data in chunks
          while (file.available()) {
            uint8_t buf[1024];
            int n = file.read(buf, sizeof(buf));
            CamSerial.write(buf, n);
          }
          file.close();
          SD_MMC.remove(file.name());
          delay(20); // Small delay for reliability
        }
        file = root.openNextFile();
      }
      root.close();
      CamSerial.println("DONE");
    }
  }
}
