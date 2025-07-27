#include "esp_camera.h"
#include <WiFi.h>

// ====== User Settings =======
const char* ssid = "sid";
const char* password = "Siddhu#05";

// Your ngrok URL with /upload path
String serverName = "http://19087dfe6433.ngrok-free.app/upload";

// AI THINKER camera pin definition (hardcoded for reliability)
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM     0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM       5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

void setup() {
  Serial.begin(115200);
  Serial.println("Starting camera...");

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
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
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_UXGA;    // Low resolution to save memory
  config.jpeg_quality = 12;              // Compression quality
  config.fb_count = 2;
  config.grab_mode = CAMERA_GRAB_LATEST;
  config.fb_location = CAMERA_FB_IN_PSRAM;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
    while (true) delay(1000); // Halt on failure
  }
  Serial.println("Camera init OK");

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("WiFi connected! IP: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    delay(2000);
    return;
  }

  Serial.printf("Captured image size: %d bytes\n", fb->len);
  Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());
  Serial.printf("Free PSRAM: %d bytes\n", ESP.getFreePsram());

  if (WiFi.status() == WL_CONNECTED) {
    // Prepare multipart form data
    String boundary = "------------------------123456789012345678901234";
    String head = "--" + boundary + "\r\n"
                  "Content-Disposition: form-data; name=\"file\"; filename=\"" + String(millis()) + ".jpg\"\r\n"
                  "Content-Type: image/jpeg\r\n\r\n";
    String tail = "\r\n--" + boundary + "--\r\n";

    int contentLength = head.length() + fb->len + tail.length();

    // Parse serverName to extract host and path
    String url = serverName; // e.g. http://your-ngrok-url/upload
    if (!url.startsWith("http://")) {
      Serial.println("Only http:// URLs are supported.");
      esp_camera_fb_return(fb);
      delay(5000);
      return;
    }
    url.remove(0, 7); // strip "http://"
    int slashIndex = url.indexOf('/');
    String host = url.substring(0, slashIndex);
    String path = url.substring(slashIndex);

    WiFiClient client;
    if (!client.connect(host.c_str(), 80)) {
      Serial.println("Connection failed");
      esp_camera_fb_return(fb);
      delay(2000);
      return;
    }

    // Send HTTP POST headers
    client.print("POST " + path + " HTTP/1.1\r\n");
    client.print("Host: " + host + "\r\n");
    client.print("Content-Type: multipart/form-data; boundary=" + boundary + "\r\n");
    client.print("Content-Length: " + String(contentLength) + "\r\n");
    client.print("Connection: close\r\n\r\n");

    // Send multipart body
    client.print(head);
    client.write(fb->buf, fb->len);
    client.print(tail);

    // Wait and print server response
    while (client.connected() && !client.available()) delay(1);
    while (client.available()) {
      String line = client.readStringUntil('\n');
      Serial.println(line);
    }
    client.stop();

  } else {
    Serial.println("WiFi not connected");
  }

  esp_camera_fb_return(fb);
  delay(5000); // Wait 5 seconds before next capture
}
