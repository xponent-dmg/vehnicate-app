package com.vehnicate.app

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

/**
 * Manages sensor acquisition and coordinate conversion.
 * Collects data from accelerometer, linear accelerometer, gyroscope, magnetometer, and GPS,
 * then applies coordinate conversion formulas.
 */
class VehnicateSensorManager(
    private val context: Context,
    private val onDataCallback: (SensorPacket) -> Unit
) : SensorEventListener {

    private val sensorManager: AndroidSensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as AndroidSensorManager

    // Location services
    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)
    
    private var latestLocation: LocationData = LocationData()
    
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.lastLocation?.let { location ->
                latestLocation = LocationData(
                    latitude = location.latitude,
                    longitude = location.longitude,
                    altitude = location.altitude,
                    speed = location.speed,
                    bearing = location.bearing,
                    accuracy = location.accuracy,
                    hasLocation = true
                )
            }
        }
    }

    // Sensors
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val linearAcceleration: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
    private val gyroscope: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    private val magnetometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    // Latest sensor values
    private var ax = 0f
    private var ay = 0f
    private var az = 0f
    
    private var Ax = 0f
    private var Ay = 0f
    private var Az = 0f
    
    private var Gx = 0f
    private var Gy = 0f
    private var Gz = 0f
    
    private var Mx = 0f
    private var My = 0f
    private var Mz = 0f

    private var isRunning = false
    private var lastUpdateTime = 0L
    private val UPDATE_INTERVAL_MS = 50  // Update at ~20 Hz

    /**
     * Starts listening to all sensors and location updates.
     */
    fun startSensors() {
        if (isRunning) return
        
        // Start IMU sensors
        accelerometer?.let {
            sensorManager.registerListener(this, it, AndroidSensorManager.SENSOR_DELAY_GAME)
        }
        
        linearAcceleration?.let {
            sensorManager.registerListener(this, it, AndroidSensorManager.SENSOR_DELAY_GAME)
        }
        
        gyroscope?.let {
            sensorManager.registerListener(this, it, AndroidSensorManager.SENSOR_DELAY_GAME)
        }
        
        magnetometer?.let {
            sensorManager.registerListener(this, it, AndroidSensorManager.SENSOR_DELAY_GAME)
        }
        
        // Start location updates if permission granted
        startLocationUpdates()
        
        isRunning = true
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
            setMaxUpdateDelayMillis(2000)
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
        isRunning = false
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return

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
            Sensor.TYPE_MAGNETIC_FIELD -> {
                Mx = event.values[0]
                My = event.values[1]
                Mz = event.values[2]
            }
        }

        // Process and send data at controlled rate
        processAndSendData()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used for this implementation
    }

    /**
     * Processes sensor data and sends it via callback.
     * Uses STATIC CALIBRATION with rotation matrix for accurate coordinate conversion.
     * Includes throttling to avoid overwhelming the event channel.
     */
    private fun processAndSendData() {
        val currentTime = System.currentTimeMillis()
        
        // Throttle updates
        if (currentTime - lastUpdateTime < UPDATE_INTERVAL_MS) {
            return
        }
        
        lastUpdateTime = currentTime

        try {
            // Create raw sensor data
            val rawData = RawSensorData(
                timestamp = currentTime,
                ax = ax,
                ay = ay,
                az = az,
                Ax = Ax,
                Ay = Ay,
                Az = Az,
                Gx = Gx,
                Gy = Gy,
                Gz = Gz,
                Mx = Mx,
                My = My,
                Mz = Mz
            )

            // STATIC CALIBRATION: Calculate roll and pitch from gravity
            val angles = MathUtils.calculateStaticAngles(ax, ay, az)
            
            // Build rotation matrix (roll + pitch only, no yaw)
            val R = MathUtils.buildStaticRotationMatrix(angles.phi, angles.theta)
            
            // Apply rotation to linear acceleration (without gravity)
            val (AX, AY, AZ) = MathUtils.rotateAccel(Ax, Ay, Az, R)
            
            // Apply rotation to gyroscope
            val (GX, GY, GZ) = MathUtils.rotateGyro(Gx, Gy, Gz, R)

            // Create converted data
            val convertedData = ConvertedData(AX, AY, AZ, GX, GY, GZ)

            // Create and send packet with location
            val packet = SensorPacket(rawData, convertedData, angles, latestLocation)
            onDataCallback(packet)
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
