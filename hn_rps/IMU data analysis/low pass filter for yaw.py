import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt

# Load and slice
df = pd.read_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\csv file with yaw.csv")
df.columns = ['time_ms', 'acc_x', 'acc_y', 'acc_z', 'gyro_x', 'gyro_y', 'gyro_z','Yaw']

df = df.iloc[19701:25000].copy()  # segment

# Convert time
df["time_ms"] = pd.to_numeric(df["time_ms"], errors="coerce")
df["timestamp"] = pd.to_timedelta(df["time_ms"], unit="ms")
df = df.set_index("timestamp")

# Resample
fs = 50  # Hz
df_resampled = df.resample(f"{1000/fs}ms").mean()
df_resampled = df_resampled.interpolate()

# Butterworth low-pass filter
def butter_lowpass_filter(data, cutoff, fs, order=4):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low')
    return filtfilt(b, a, data)

cutoff = 0.184  # Hz (adjust this for yaw smoothing)
df_resampled["filtered"] = butter_lowpass_filter(df_resampled["Yaw"].values, cutoff, fs)

# Plot
plt.figure(figsize=(10,5))
plt.plot(df_resampled.index.total_seconds(), df_resampled["Yaw"], label="Original (resampled)")
plt.plot(df_resampled.index.total_seconds(), df_resampled["filtered"], label=f"Filtered (cutoff={cutoff}Hz)")
plt.legend()
plt.xlabel("Time [s]")
plt.ylabel("Yaw [deg]")  # or rad, depending on your data
plt.grid(True)
plt.show()
