import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.fft import fft, fftfreq
import math as m

# --- Load and preprocess ---
df = pd.read_csv(r"D:\Vehnicate\Prototype\Code\python\IMU data analysis\data resulting from code\csv file with yaw.csv")
df.columns = ['time_ms', 'acc_x', 'acc_y', 'acc_z', 'gyro_x', 'gyro_y', 'gyro_z','Yaw']

# Take only the slice of interest
#df = df.iloc[19701:25000].copy()
#df = df.iloc[7722:10820].copy()
#df = df.iloc[7722:10820].copy()
#df = df.iloc[6507:7177].copy()
df = df.iloc[13264:16200].copy()

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

print(np.mean(xf),'mean')
sum_mag,count = 0,0
sum_xf,count1=0,0
xf1=[]
for i in range(len(xf)):
    try:
        xf1.append(xf[i]-xf[i+1])
        sum_xf += (magnitude[i+1]-magnitude[i])/(xf[i+1]-xf[i])
        count1+=1
    except:
        xf1.append(0)
        break
    if (xf[i]<=np.mean(xf)):
        sum_mag+=(magnitude[i])
        count+=1
print(sum_mag/count,"mean of mag = threshold")
print(sum_xf/count1,"threshold for xf")
#print(xf1[:10],"xf1")
#print(xf[:10],"xf")

#mask = magnitude > 0.02
#xf = xf[mask]
#magnitude = magnitude[mask]
#xf1 = xf1[mask]

a=(np.mean(xf*magnitude)/np.mean(magnitude))
print((np.sqrt(np.mean(xf**2))+a)/2)
print(np.mean(xf/np.sqrt(magnitude))*np.mean(magnitude),"this")

# --- Plot ---
plt.figure(figsize=(10,5))
plt.subplot(1,2,1)
plt.plot(xf, magnitude, color="blue")
plt.xlim(0, fs/2)   # up to Nyquist frequency
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitude")
plt.title("FFT of Yaw (detrended + Hann window)")
plt.grid(True)
#plt.show()

plt.subplot(1,2,2)
plt.plot(xf,(np.exp(-1*xf*xf1))/(magnitude**magnitude))
plt.xlabel("frequency")
plt.ylabel("xf/magnitude")
plt.show()

#print(((np.exp(-1*xf*xf1))/(magnitude**magnitude))[0],"testing")
print(max((np.exp(-1*xf*xf1))/(magnitude**magnitude)),"max")
for i in range(len((np.exp(-1*xf*xf1))/(magnitude**magnitude))):
    if ((np.exp(-1*xf*xf1))/(magnitude**magnitude))[i]>=max((np.exp(-1*xf*xf1))/(magnitude**magnitude)):
        print(xf[i])
        break
