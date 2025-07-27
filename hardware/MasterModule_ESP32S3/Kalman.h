#ifndef _Kalman_h
#define _Kalman_h

class Kalman {
public:
    Kalman() {
        Q_value = 0.001;
        Q_bias = 0.003;
        R_measure = 0.03;

        value = 0;
        bias = 0;

        P[0][0] = 0;
        P[0][1] = 0;
        P[1][0] = 0;
        P[1][1] = 0;
    }

    double filter(double newValue, double dt) {
        double rate = 0 - bias;
        value += dt * rate;

        P[0][0] += dt * (dt*P[1][1] - P[0][1] - P[1][0] + Q_value);
        P[0][1] -= dt * P[1][1];
        P[1][0] -= dt * P[1][1];
        P[1][1] += Q_bias * dt;

        double S = P[0][0] + R_measure;
        double K[2];
        K[0] = P[0][0] / S;
        K[1] = P[1][0] / S;

        double y = newValue - value;
        value += K[0] * y;
        bias += K[1] * y;

        P[0][0] -= K[0] * P[0][0];
        P[0][1] -= K[0] * P[0][1];
        P[1][0] -= K[1] * P[0][0];
        P[1][1] -= K[1] * P[0][1];

        return value;
    }

    void setInitialValue(double newValue) { value = newValue; }
    double getValue() { return value; }

    void setQvalue(double q) { Q_value = q; }
    void setQbias(double b) { Q_bias = b; }
    void setRmeasure(double r) { R_measure = r; }

private:
    double Q_value;
    double Q_bias;
    double R_measure;

    double value;
    double bias;

    double P[2][2];
};

#endif
