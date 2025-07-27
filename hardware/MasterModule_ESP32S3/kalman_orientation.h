#ifndef _KalmanOrientation_h
#define _KalmanOrientation_h

class KalmanOrientation {
public:
    KalmanOrientation() {
        Q_angle = 0.001f;
        Q_bias = 0.003f;
        R_measure = 0.03f;

        angle = 0.0f;
        bias = 0.0f;

        P[0][0] = 0.0f;
        P[0][1] = 0.0f;
        P[1][0] = 0.0f;
        P[1][1] = 0.0f;
    }

    float filter(float accAngle, float gyroRate, float dt) {
        // Predict step
        float rate = gyroRate - bias;
        angle += dt * rate;

        // Update estimation error covariance
        P[0][0] += dt * (dt*P[1][1] - P[0][1] - P[1][0] + Q_angle);
        P[0][1] -= dt * P[1][1];
        P[1][0] -= dt * P[1][1];
        P[1][1] += Q_bias * dt;

        // Compute Kalman gain
        float y = accAngle - angle;
        float S = P[0][0] + R_measure;
        float K[2];
        K[0] = P[0][0] / S;
        K[1] = P[1][0] / S;

        // Update angle and bias
        angle += K[0] * y;
        bias += K[1] * y;

        // Update error covariance matrix
        float P00_temp = P[0][0];
        float P01_temp = P[0][1];

        P[0][0] -= K[0] * P00_temp;
        P[0][1] -= K[0] * P01_temp;
        P[1][0] -= K[1] * P00_temp;
        P[1][1] -= K[1] * P01_temp;

        return angle;
    }

    void setInitialAngle(float newAngle) { angle = newAngle; }
    float getAngle() { return angle; }

    void setQangle(float q) { Q_angle = q; }
    void setQbias(float b) { Q_bias = b; }
    void setRmeasure(float r) { R_measure = r; }

private:
    float Q_angle;
    float Q_bias;
    float R_measure;

    float angle;
    float bias;

    float P[2][2];
};

#endif
