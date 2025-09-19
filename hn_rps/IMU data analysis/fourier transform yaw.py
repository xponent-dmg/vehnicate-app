import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.fft import fft, fftfreq

# --- Load and preprocess ---
df = pd.read_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\csv file with yaw.csv")
df.columns = ['time_ms', 'acc_x', 'acc_y', 'acc_z', 'gyro_x', 'gyro_y', 'gyro_z','Yaw']

# Take only the slice of interest
df = df.iloc[19701:25000].copy()

# Convert time column
df["time_ms"] = pd.to_numeric(df["time_ms"], errors="coerce")
df["timestamp"] = pd.to_timedelta(df["time_ms"], unit="ms")
df = df.set_index("timestamp")

# Resample to fixed rate
fs = 50  # Hz (20 ms step)
df_resampled = df.resample(f"{1000/fs}ms").mean()
df_resampled = df_resampled.interpolate()

# --- FFT with detrending + window ---
y = df_resampled["Yaw"].values
N = len(y)
T = 1.0 / fs

# Detrend (remove mean)
y_detrended = y - np.mean(y)

# Apply Hann window
window = np.hanning(N)
y_win = y_detrended * window

# FFT
yf = fft(y_win)
xf = fftfreq(N, T)[:N//2]

# Correct magnitude spectrum (single-sided, with window compensation)
magnitude = 2.0 / N * np.abs(yf[:N//2])
magnitude /= window.mean()   # compensate for Hann window loss

# --- Plot ---
plt.figure(figsize=(10,5))
plt.plot(xf, magnitude, color="blue")
plt.xlim(0, fs/2)   # up to Nyquist frequency
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitude")
plt.title("FFT of Yaw (detrended + Hann window)")
plt.grid(True)
plt.show()
