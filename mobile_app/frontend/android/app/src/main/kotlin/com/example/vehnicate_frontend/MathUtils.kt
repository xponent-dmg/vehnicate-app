package com.vehnicate.app

import kotlin.math.*

/**
 * Utility class for static calibration and coordinate conversion from phone frame to vehicle frame.
 * Uses industry-standard IMU rotation matrices (roll-pitch only, no yaw during static calibration).
 */
object MathUtils {
    private const val GRAVITY = 9.8f  // m/s²

    /**
     * STATIC CALIBRATION: Calculates roll and pitch angles from accelerometer readings.
     * This assumes the vehicle is stationary (no linear acceleration).
     * 
     * Industry-standard formulas used in drones, aircraft, and ARCore:
     * - Roll (phi): Rotation around X-axis (left/right lean)
     * - Pitch (theta): Rotation around Y-axis (forward/back tilt)
     * 
     * @param ax Accelerometer X with gravity (m/s²)
     * @param ay Accelerometer Y with gravity (m/s²)
     * @param az Accelerometer Z with gravity (m/s²)
     * @return ConversionAngles containing phi (roll) and theta (pitch) in radians
     */
    fun calculateStaticAngles(ax: Float, ay: Float, az: Float): ConversionAngles {
        // Roll: atan2(ay, az)
        // Positive roll = phone tilted right
        val phi = atan2(ay, az)
        
        // Pitch: atan2(-ax, sqrt(ay² + az²))
        // Positive pitch = phone tilted forward (top edge down)
        val theta = atan2(-ax, sqrt(ay * ay + az * az))
        
        return ConversionAngles(phi, theta)
    }

    /**
     * Builds a 3x3 rotation matrix using ONLY roll and pitch (no yaw).
     * 
     * Rotation order: R = R_pitch(theta) * R_roll(phi)
     * This aligns the phone's gravity vector with the vehicle's vertical axis.
     * 
     * R_roll(phi) rotates around X-axis:
     * [1      0         0    ]
     * [0   cos(phi) -sin(phi)]
     * [0   sin(phi)  cos(phi)]
     * 
     * R_pitch(theta) rotates around Y-axis:
     * [ cos(theta)  0  sin(theta)]
     * [     0       1      0     ]
     * [-sin(theta)  0  cos(theta)]
     * 
     * Combined R = R_pitch * R_roll:
     * [ cos(theta)  sin(phi)*sin(theta)  cos(phi)*sin(theta) ]
     * [     0            cos(phi)            -sin(phi)        ]
     * [-sin(theta)  sin(phi)*cos(theta)  cos(phi)*cos(theta) ]
     * 
     * @param phi Roll angle in radians
     * @param theta Pitch angle in radians
     * @return 3x3 rotation matrix as Array<FloatArray>
     */
    fun buildStaticRotationMatrix(phi: Float, theta: Float): Array<FloatArray> {
        val cp = cos(phi)   // cos(roll)
        val sp = sin(phi)   // sin(roll)
        val ct = cos(theta) // cos(pitch)
        val st = sin(theta) // sin(pitch)
        
        return arrayOf(
            floatArrayOf(ct,      sp * st,     cp * st),
            floatArrayOf(0f,      cp,         -sp),
            floatArrayOf(-st,     sp * ct,     cp * ct)
        )
    }

    /**
     * Applies rotation matrix to convert acceleration from phone frame to vehicle frame.
     * 
     * a_vehicle = R * a_phone
     * 
     * After rotation, if calibration is correct:
     * - AX ≈ 0 (no lateral acceleration)
     * - AY ≈ 0 (no forward acceleration)
     * - AZ ≈ -9.8 m/s² (gravity pointing down)
     * 
     * @param ax Phone accelerometer X (m/s²)
     * @param ay Phone accelerometer Y (m/s²)
     * @param az Phone accelerometer Z (m/s²)
     * @param R 3x3 rotation matrix
     * @return Triple containing (AX, AY, AZ) in vehicle frame
     */
    fun rotateAccel(ax: Float, ay: Float, az: Float, R: Array<FloatArray>): Triple<Float, Float, Float> {
        val AX = R[0][0] * ax + R[0][1] * ay + R[0][2] * az
        val AY = R[1][0] * ax + R[1][1] * ay + R[1][2] * az
        val AZ = R[2][0] * ax + R[2][1] * ay + R[2][2] * az
        
        return Triple(AX, AY, AZ)
    }

    /**
     * Applies rotation matrix to convert gyroscope from phone frame to vehicle frame.
     * 
     * omega_vehicle = R * omega_phone
     * 
     * @param Gx Phone gyroscope X (deg/s)
     * @param Gy Phone gyroscope Y (deg/s)
     * @param Gz Phone gyroscope Z (deg/s)
     * @param R 3x3 rotation matrix
     * @return Triple containing (GX, GY, GZ) in vehicle frame
     */
    fun rotateGyro(Gx: Float, Gy: Float, Gz: Float, R: Array<FloatArray>): Triple<Float, Float, Float> {
        val GX = R[0][0] * Gx + R[0][1] * Gy + R[0][2] * Gz
        val GY = R[1][0] * Gx + R[1][1] * Gy + R[1][2] * Gz
        val GZ = R[2][0] * Gx + R[2][1] * Gy + R[2][2] * Gz
        
        return Triple(GX, GY, GZ)
    }

    /**
     * LEGACY: Old conversion functions kept for compatibility.
     * These will be deprecated - use rotation matrix approach instead.
     */
    @Deprecated("Use calculateStaticAngles instead", ReplaceWith("calculateStaticAngles(ax, ay, az)"))
    fun calculateAngles(ax: Float, ay: Float, az: Float): ConversionAngles {
        return calculateStaticAngles(ax, ay, az)
    }

    @Deprecated("Use buildStaticRotationMatrix + rotateAccel instead")
    fun convertAccelerationToVehicleFrame(
        Ax: Float,
        Ay: Float,
        Az: Float,
        theta: Float,
        phi: Float
    ): Triple<Float, Float, Float> {
        val R = buildStaticRotationMatrix(phi, theta)
        return rotateAccel(Ax, Ay, Az, R)
    }

    @Deprecated("Use buildStaticRotationMatrix + rotateGyro instead")
    fun convertGyroscopeToVehicleFrame(
        Gx: Float,
        Gy: Float,
        Gz: Float,
        theta: Float,
        phi: Float
    ): Triple<Float, Float, Float> {
        val R = buildStaticRotationMatrix(phi, theta)
        return rotateGyro(Gx, Gy, Gz, R)
    }

    /**
     * Converts radians to degrees.
     */
    fun radiansToDegrees(radians: Float): Float {
        return Math.toDegrees(radians.toDouble()).toFloat()
    }

    /**
     * Converts degrees to radians.
     */
    fun degreesToRadians(degrees: Float): Float {
        return Math.toRadians(degrees.toDouble()).toFloat()
    }

    /**
     * Debug helper: Validates static calibration quality.
     * Returns calibration error magnitude (should be close to 0).
     */
    fun getCalibrationError(ax: Float, ay: Float, az: Float): Float {
        val angles = calculateStaticAngles(ax, ay, az)
        val R = buildStaticRotationMatrix(angles.phi, angles.theta)
        val (AX, AY, AZ) = rotateAccel(ax, ay, az, R)
        
        // After rotation, should have: AX≈0, AY≈0, AZ≈-9.8
        val errorX = AX
        val errorY = AY
        val errorZ = AZ + GRAVITY
        
        return sqrt(errorX * errorX + errorY * errorY + errorZ * errorZ)
    }
}
