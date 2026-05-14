package com.opsin.app

/**
 * Data class representing raw sensor readings from the device.
 * All values are in standard SI units.
 */
data class RawSensorData(
    val timestamp: Long,                  // Timestamp in milliseconds
    @get:JvmName("getAccelX")
    val ax: Float,                        // Accelerometer X (with gravity) in m/s²
    @get:JvmName("getAccelY")
    val ay: Float,                        // Accelerometer Y (with gravity) in m/s²
    @get:JvmName("getAccelZ")
    val az: Float,                        // Accelerometer Z (with gravity) in m/s²
    @get:JvmName("getLinearAccelX")
    val Ax: Float,                        // Linear acceleration X (without gravity) in m/s²
    @get:JvmName("getLinearAccelY")
    val Ay: Float,                        // Linear acceleration Y (without gravity) in m/s²
    @get:JvmName("getLinearAccelZ")
    val Az: Float,                        // Linear acceleration Z (without gravity) in m/s²
    @get:JvmName("getGyroX")
    val Gx: Float,                        // Gyroscope X in deg/s
    @get:JvmName("getGyroY")
    val Gy: Float,                        // Gyroscope Y in deg/s
    @get:JvmName("getGyroZ")
    val Gz: Float,                        // Gyroscope Z in deg/s
    @get:JvmName("getMagX")
    val Mx: Float = 0f,                   // Magnetometer X in µT (optional)
    @get:JvmName("getMagY")
    val My: Float = 0f,                   // Magnetometer Y in µT (optional)
    @get:JvmName("getMagZ")
    val Mz: Float = 0f                    // Magnetometer Z in µT (optional)
)

/**
 * Data class representing converted sensor data in vehicle coordinates.
 */
data class ConvertedData(
    val AX: Float,                    // Converted acceleration X in m/s²
    val AY: Float,                    // Converted acceleration Y in m/s²
    val AZ: Float,                    // Converted acceleration Z in m/s²
    val GX: Float,                    // Converted gyroscope X in deg/s
    val GY: Float,                    // Converted gyroscope Y in deg/s
    val GZ: Float,                    // Converted gyroscope Z in deg/s
    val speed: Float = 0f,            // Speed in m/s
    val bearing: Float = 0f           // Bearing in degrees
)

/**
 * Data class representing location/GPS data.
 */
data class LocationData(
    val latitude: Double = 0.0,       // Latitude in degrees
    val longitude: Double = 0.0,      // Longitude in degrees
    val altitude: Double = 0.0,       // Altitude in meters
    val speed: Float = 0f,            // Speed in m/s
    val bearing: Float = 0f,          // Bearing in degrees
    val accuracy: Float = 0f,         // Accuracy in meters
    val hasLocation: Boolean = false  // Whether location is available
)

/**
 * Complete sensor data packet containing raw data, converted data, and location.
 * This is the data structure sent to Flutter via the event channel.
 */
data class SensorPacket(
    val raw: RawSensorData,
    val converted: ConvertedData,
    val location: LocationData = LocationData()
) {
    /**
     * Converts the sensor packet to a Map for JSON serialization.
     */
    fun toMap(): Map<String, Any> {
        return mapOf(
            "timestamp" to raw.timestamp,
            "raw" to mapOf(
                "ax" to raw.ax,
                "ay" to raw.ay,
                "az" to raw.az,
                "Ax" to raw.Ax,
                "Ay" to raw.Ay,
                "Az" to raw.Az,
                "Gx" to raw.Gx,
                "Gy" to raw.Gy,
                "Gz" to raw.Gz,
                "Mx" to raw.Mx,
                "My" to raw.My,
                "Mz" to raw.Mz
            ),
            "converted" to mapOf(
                "AX" to converted.AX,
                "AY" to converted.AY,
                "AZ" to converted.AZ,
                "GX" to converted.GX,
                "GY" to converted.GY,
                "GZ" to converted.GZ,
                "speed" to converted.speed,
                "bearing" to converted.bearing
            ),
            "location" to mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "altitude" to location.altitude,
                "speed" to location.speed,
                "bearing" to location.bearing,
                "accuracy" to location.accuracy,
                "hasLocation" to location.hasLocation
            )
        )
    }
}
