/*
#define TINY_GSM_MODEM_BG96
#include <TinyGsmClient.h>
#include <PubSubClient.h>

// Hardware Serial for modem
#define MODEM_SERIAL Serial1
#define MODEM_TX 13
#define MODEM_RX 12
#define MODEM_PWRKEY 4

// Debug serial
#define SerialMon Serial

// SIM credentials
const char apn[] = "airtelgprs.com";
const char gprsUser[] = "";
const char gprsPass[] = "";

// MQTT Broker (HiveMQ Cloud)
const char* broker = "broker.hivemq.com";//"o536e011.ala.asia-southeast1.emqxsl.com";  // e.g., "xxxxxx.hivemq.cloud"
const int port = 1883;//8883;
const char* topic = "esp32s3/hnPdata";
const char* mqttUser = "vehnicate";
const char* mqttPass = "SSottallu@w24";

// Public Root CA Certificate (DigiCert Global Root CA)
const char* root_ca = 
"-----BEGIN CERTIFICATE-----\n"
"MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh\n"
"MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3\n"
"d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD\n"
"QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT\n"
"MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j\n"
"b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG\n"
"9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB\n"
"CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97\n"
"nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt\n"
"43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P\n"
"T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4\n"
"gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO\n"
"BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR\n"
"TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw\n"
"DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr\n"
"hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg\n"
"06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF\n"
"PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls\n"
"YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk\n"
"CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=\n"
"-----END CERTIFICATE-----\n";

// TinyGSM objects
TinyGsm modem(MODEM_SERIAL);
TinyGsmClient gsmClient(modem);
//TinyGsmClientSecure gsmClient(modem);
PubSubClient mqtt(gsmClient);

void setup() {
  // Initialize modem power
  pinMode(MODEM_PWRKEY, OUTPUT);
  digitalWrite(MODEM_PWRKEY, HIGH);
  delay(1000);

  // Start serial communications
  SerialMon.begin(115200);
  MODEM_SERIAL.begin(115200, SERIAL_8N1, MODEM_RX, MODEM_TX);
  delay(3000);  // Wait for modem initialization

  SerialMon.println("Initializing modem...");
  modem.restart();
  delay(2000);

  SerialMon.println("Waiting for network...");
  if (!modem.waitForNetwork()) {
    SerialMon.println("Network failed");
    while (true);
  }

  SerialMon.print("Connecting to ");
  SerialMon.print(apn);
  if (!modem.gprsConnect(apn, gprsUser, gprsPass)) {
    SerialMon.println(" GPRS failed");
    while (true);
  }
  SerialMon.println(" OK");

  /*
  // Set root CA certificate
  if (!modem.setCARootCert(root_ca)) {
    SerialMon.println("Failed to set CA certificate");
  } else {
    SerialMon.println("CA certificate set");
  }
  *----------------------------------------------------------------------/

  // Configure MQTT
  mqtt.setServer(broker, port);
  mqtt.setKeepAlive(60);
}

void loop() {
  if (!mqtt.connected()) {
    connectMQTT();
  }
  mqtt.loop();
}

void connectMQTT() {
  SerialMon.print("Connecting to ");
  SerialMon.print(broker);
  
  while (!mqtt.connected()) {
    if (mqtt.connect("EC200U_Client")) {
      SerialMon.println(" OK");
      mqtt.publish(topic, "EC200U online");
      SerialMon.print("done");
    } else {
      SerialMon.print(" failed, rc=");
      SerialMon.print(mqtt.state());
      SerialMon.println(" retrying...");
      delay(5000);
    }
  }
}
*/