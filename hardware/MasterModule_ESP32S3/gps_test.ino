/*
#define TINY_GSM_MODEM_BG96
#include <TinyGsmClient.h>

#define SerialMon Serial
#define SerialAT  Serial2

// Set your modem UART pins and baudrate
#define MODEM_TX 13
#define MODEM_RX 12
#define MODEM_BAUDRATE 115200

TinyGsm modem(SerialAT);

void setup() {
  SerialMon.begin(115200);
  delay(3000); // Wait for serial monitor connection
  SerialMon.println("Starting EC200U GPS Test!");

  // Start modem UART
  SerialAT.begin(MODEM_BAUDRATE, SERIAL_8N1, MODEM_RX, MODEM_TX);
  delay(1000);

  // Try to start modem (optional; many EC200U come alive after UART alone)
  SerialMon.println("Restarting modem...");
  modem.restart();
  delay(2000);

  // Enable GPS
  SerialMon.println("Enabling GPS engine...");
  modem.sendAT("+QGPS=1");
  modem.waitResponse(5000);

  SerialMon.println("Waiting for GPS fix...");
}

void loop() {
  // Optional: check GPS status
  modem.sendAT("+QGPS?");
  String status;
  modem.waitResponse(2000, status);
  SerialMon.println("GPS Status: " + status);

  // Query location
  modem.sendAT("+QGPSLOC=2");
  String gpsResp;
  if (modem.waitResponse(5000, gpsResp) == 1) {
    SerialMon.println("Raw GPS Resp: " + gpsResp);
    int idx = gpsResp.indexOf("+QGPSLOC:");
    if (idx >= 0) {
      String fields = gpsResp.substring(idx + 9);  // after '+QGPSLOC:'
      fields.trim();
      int firstComma = fields.indexOf(',');
      int secondComma = fields.indexOf(',', firstComma + 1);
      int thirdComma = fields.indexOf(',', secondComma + 1);
      if (firstComma > 0 && secondComma > firstComma && thirdComma > secondComma) {
        String latStr = fields.substring(firstComma + 1, secondComma);
        String lonStr = fields.substring(secondComma + 1, thirdComma);
        float lat = latStr.toFloat();
        float lon = lonStr.toFloat();
        SerialMon.print("Parsed Latitude: "); SerialMon.println(lat, 6);
        SerialMon.print("Parsed Longitude: "); SerialMon.println(lon, 6);
        if (abs(lat) < 0.01 && abs(lon) < 0.01) {
          SerialMon.println("WARNING: No fix yet or invalid data. Wait for GPS to acquire fix.");
        }
      }
    } else {
      SerialMon.println("No +QGPSLOC: found in response.");
    }
  } else {
    SerialMon.println("No response or timeout from +QGPSLOC=2 command.");
  }

  delay(3000); // Query again every 3 s
}

*/