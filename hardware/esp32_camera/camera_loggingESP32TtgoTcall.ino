/*
#include "esp_camera.h"

// Camera configuration (AI-Thinker module)
#define PWDN_GPIO_NUM      32
#define RESET_GPIO_NUM     -1
#define XCLK_GPIO_NUM       0
#define SIOD_GPIO_NUM      26
#define SIOC_GPIO_NUM      27
#define Y9_GPIO_NUM        35
#define Y8_GPIO_NUM        34
#define Y7_GPIO_NUM        39
#define Y6_GPIO_NUM        36
#define Y5_GPIO_NUM        21
#define Y4_GPIO_NUM        19
#define Y3_GPIO_NUM        18
#define Y2_GPIO_NUM         5
#define VSYNC_GPIO_NUM     25
#define HREF_GPIO_NUM      23
#define PCLK_GPIO_NUM      22

void setup() {
  Serial.begin(115200);  // UART0 (TX=GPIO1)
  
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
  
  // Optimized settings
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_SVGA;  // 800x600
  config.pixel_format = PIXFORMAT_JPEG;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 2;

  // Initialize camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    while(true);  // Halt on failure
  }
}

void loop() {
  camera_fb_t *fb = esp_camera_fb_get();
  if(!fb) {
  //Serial.println("Camera capture failed");
  return;
  }

//Serial.printf("Captured image of size: %u bytes\n", fb->len);

  // Send image via UART

  uint32_t imgSize = fb->len;
  Serial.write("IMG", 3); 
  Serial.write((uint8_t*)&imgSize, 4);  // Send 4-byte size header
  
  // Send in chunks to prevent buffer overflow
  uint32_t bytesSent = 0;
  while(bytesSent < imgSize) {
    // FIX: Use same data types (uint32_t) for min()
    uint32_t remaining = imgSize - bytesSent;
    uint32_t chunkSize = (remaining > 128) ? 128 : remaining;
    
    Serial.write(fb->buf + bytesSent, chunkSize);
    bytesSent += chunkSize;
  }
  
  esp_camera_fb_return(fb);
  delay(100);  // ~10 FPS
}

*/