#co ordinate conversion and normalisation, sample
#in this code i have assume the car to be a block, with the imu fixed at the corner. readings at the centre of mass is calculated from the imu data

import numpy as np

def cross_matrix(v):
    """Return the 3x3 cross-product matrix of vector v."""
    return np.array([[0, -v[2], v[1]],
                     [v[2], 0, -v[0]],
                     [-v[1], v[0], 0]])

def imu_corner_to_com(a_corner, omega, alpha, rx, ry, rz):
    """
    Convert accelerometer readings from corner IMU to CoM.
    
    a_corner: 3x1 accelerometer at IMU (m/s²)
    omega: 3x1 angular velocity (rad/s)
    alpha: 3x1 angular acceleration (rad/s²)
    rx, ry, rz: distances from IMU to CoM (meters)
    
    Returns:
    a_com: 3x1 accelerometer at CoM
    omega_com: 3x1 gyro at CoM (same as corner)
    """
    # vector from IMU to CoM
    r = np.array([rx, ry, rz])
    
    # cross-product matrices
    omega_cross = cross_matrix(omega)
    alpha_cross = cross_matrix(alpha)
    
    # tangential acceleration
    a_tangential = alpha_cross @ r
    
    # centripetal acceleration
    a_centripetal = omega_cross @ (omega_cross @ r)
    
    # total acceleration at CoM
    a_com = a_corner + a_tangential + a_centripetal
    
    # gyro at CoM is the same
    omega_com = omega.copy()
    
    return a_com, omega_com

# Example usage
a_corner = np.array([0.5, 0.1, 9.8])   # IMU accel readings (m/s²)
omega = np.array([0.0, 0.1, 0.0])      # gyro (rad/s)
alpha = np.array([0.0, 0.05, 0.0])     # angular acceleration (rad/s²)

# User inputs distances from side mirror to CoM
rx = float(input("Distance forward/back from IMU to CoM (m): "))
ry = float(input("Distance left/right from IMU to CoM (m): "))
rz = float(input("Distance up/down from IMU to CoM (m): "))

a_com, omega_com = imu_corner_to_com(a_corner, omega, alpha, rx, ry, rz)

print("Accelerometer at CoM:", a_com)
print("Gyro at CoM:", omega_com)
