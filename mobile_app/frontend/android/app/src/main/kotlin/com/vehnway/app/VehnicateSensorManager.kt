package com.vehnway.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager as AndroidSensorManager
import android.location.Location
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Manages sensor acquisition and coordinate conversion.
 * Collects data from accelerometer, linear accelerometer, gyroscope, and GPS,
 * emitting them as separate maps.
 */
class VehnicateSensorManager(
    private val context: Context,
    private val onDataCallback: (Map<String, Any>) -> Unit
) : SensorEventListener {

    private val sensorManager: AndroidSensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as AndroidSensorManager

    // Location services
    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)
    
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.locations.forEach { location ->
                latestLocation = location
            }
        }
    }

    @Volatile
    private var latestLocation: Location? = null
    private var gpsEmissionTask: ScheduledFuture<*>? = null

    private fun emitLatestLocation() {
        val location = latestLocation ?: return
        val locationMap = mapOf(
            "type" to "gps",
            // This is the time the fixed-rate collector emitted the record.
            "timestamp" to System.currentTimeMillis(),
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "speed" to location.speed,
            "bearing" to location.bearing
        )
        onDataCallback(locationMap)
    }

    // Sensors
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val linearAcceleration: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
    private val gyroscope: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

    // Latest sensor values
    @Volatile
    private var ax = 0f
    @Volatile
    private var ay = 0f
    @Volatile
    private var az = 0f
    
    @Volatile
    private var Ax = 0f
    @Volatile
    private var Ay = 0f
    @Volatile
    private var Az = 0f
    
    @Volatile
    private var Gx = 0f
    @Volatile
    private var Gy = 0f
    @Volatile
    private var Gz = 0f

    @Volatile
    private var latestSensorTimestampNs = 0L

    private var isRunning = false
    private val imuExecutor: ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor()
    private val IMU_INTERVAL_MS = 20L // Fixed output rate: 50 Hz
    private val GPS_INTERVAL_MS = 1000L // Fixed output rate: 1 Hz

    /**
     * Starts listening to all sensors and location updates.
     */
    fun startSensors() {
        if (isRunning) return
        
        // Start IMU sensors
        accelerometer?.let {
            sensorManager.registerListener(this, it, 20000, 0)
        }
        
        linearAcceleration?.let {
            sensorManager.registerListener(this, it, 20000, 0)
        }
        
        gyroscope?.let {
            sensorManager.registerListener(this, it, 20000, 0)
        }
        
        // Start location updates if permission granted
        startLocationUpdates()
        
        isRunning = true
        imuExecutor.scheduleAtFixedRate(
            { processAndSendData() },
            0L,
            IMU_INTERVAL_MS,
            TimeUnit.MILLISECONDS
        )
        gpsEmissionTask = imuExecutor.scheduleAtFixedRate(
            { emitLatestLocation() },
            0L,
            GPS_INTERVAL_MS,
            TimeUnit.MILLISECONDS
        )
    }

    /**
     * Starts location updates if permissions are granted.
     */
    private fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            // Permission not granted, location will not be available
            return
        }

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            1000 // 1 second interval
        ).apply {
            setMinUpdateIntervalMillis(500)
            setMaxUpdateDelayMillis(1000)
        }.build()

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    /**
     * Stops listening to all sensors and location updates.
     */
    fun stopSensors() {
        if (!isRunning) return
        
        sensorManager.unregisterListener(this)
        fusedLocationClient.removeLocationUpdates(locationCallback)
        gpsEmissionTask?.cancel(false)
        gpsEmissionTask = null
        latestLocation = null
        isRunning = false
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return

        latestSensorTimestampNs = maxOf(latestSensorTimestampNs, event.timestamp)

        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> {
                ax = event.values[0]
                ay = event.values[1]
                az = event.values[2]
            }
            Sensor.TYPE_LINEAR_ACCELERATION -> {
                Ax = event.values[0]
                Ay = event.values[1]
                Az = event.values[2]
            }
            Sensor.TYPE_GYROSCOPE -> {
                // Convert from rad/s to deg/s
                Gx = Math.toDegrees(event.values[0].toDouble()).toFloat()
                Gy = Math.toDegrees(event.values[1].toDouble()).toFloat()
                Gz = Math.toDegrees(event.values[2].toDouble()).toFloat()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used for this implementation
    }

    /**
     * Processes IMU data and sends it via callback.
     * Includes throttling to avoid overwhelming the event channel.
     */
    private fun processAndSendData() {
        try {
            val imuMap = mapOf(
                "type" to "imu",
                // Keep timestamp in epoch milliseconds for the existing database schema.
                "timestamp" to System.currentTimeMillis(),
                "ax" to ax,
                "ay" to ay,
                "az" to az,
                "gx" to Gx,
                "gy" to Gy,
                "gz" to Gz,
                "Ax" to Ax,
                "Ay" to Ay,
                "Az" to Az,
                // Sensor timestamps use elapsedRealtimeNanos and are monotonic,
                // unlike wall-clock timestamps.
                "sensor_timestamp_ns" to latestSensorTimestampNs
            )
            onDataCallback(imuMap)
        } catch (e: Exception) {
            // Log error but don't crash
            e.printStackTrace()
        }
    }

    /**
     * Cleanup resources.
     */
    fun cleanup() {
        stopSensors()
        imuExecutor.shutdownNow()
    }

    /**
     * Checks if all required sensors are available.
     */
    fun areSensorsAvailable(): Boolean {
        return accelerometer != null && 
               linearAcceleration != null && 
               gyroscope != null
    }
}
