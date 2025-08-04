from flask import Flask, request, jsonify
import json
import time
from collections import deque
import threading
import csv
import os
from datetime import datetime
from flask_cors import CORS
from werkzeug.utils import secure_filename
# Increase to 2MB (or as required)
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024  # 2MB
CORS(app)
UPLOAD_FOLDER = r"D:\Vehnicate\Prototype\data\images"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/upload_image', methods=['POST'])
def upload_image():
    if 'file' not in request.files:
        return jsonify({"status": "error", "message": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"status": "error", "message": "No selected file"}), 400
    filename = secure_filename(file.filename)
    save_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(save_path)
    return jsonify({"status": "success", "message": "Image uploaded", "filename": filename}), 200

# Sensor data storage for live view
sensor_data = {
    'timestamps': deque(maxlen=50),
    'accel': {'x': deque(maxlen=50), 'y': deque(maxlen=50), 'z': deque(maxlen=50)},
    'gyro': {'x': deque(maxlen=50), 'y': deque(maxlen=50), 'z': deque(maxlen=50)},
    'lat': deque(maxlen=50),
    'lon': deque(maxlen=50)
}

# Statistics tracking
stats = {
    'total_readings': 0,
    'total_chunks': 0,
    'last_update': 'Never',
    'sampling_rate': 0
}

# Thread safety
data_lock = threading.Lock()

# CSV logging configuration
CSV_FOLDER = r"D:\Vehnicate\Prototype\data"
CSV_FILE_PATH = os.path.join(CSV_FOLDER, 'sensor_data.csv')

# Background logging queue and thread
log_queue = deque()
log_queue_lock = threading.Lock()
log_thread_running = True

def initialize_csv_logging():
    """Initialize CSV logging directory and file"""
    try:
        if not os.path.exists(CSV_FOLDER):
            os.makedirs(CSV_FOLDER)
            print(f"Created log directory: {CSV_FOLDER}")
        # Update the header for both IMU and GPS
        if not os.path.exists(CSV_FILE_PATH):
            with open(CSV_FILE_PATH, 'w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow([
                    'Date', 'Time', 'Timestamp_ms',
                    'Accel_X', 'Accel_Y', 'Accel_Z',
                    'Gyro_X', 'Gyro_Y', 'Gyro_Z',
                    'Latitude', 'Longitude'
                ])
            print(f"Created new log file: {CSV_FILE_PATH}")
    except Exception as e:
        print(f"Error initializing CSV logging: {e}")

def log_data_to_csv_background():
    """Background thread: logs data from queue to CSV"""
    global log_thread_running
    while log_thread_running:
        batch = []
        # Gather up to 500 points at a time for efficient writing
        with log_queue_lock:
            while log_queue and len(batch) < 500:
                batch.append(log_queue.popleft())
        if batch:
            try:
                with open(CSV_FILE_PATH, 'a', newline='') as file:
                    writer = csv.writer(file)
                    for point in batch:
                        now = datetime.now()
                        writer.writerow([
                            now.date(), now.time(),
                            point['timestamp'],
                            point['ax'],
                            point['ay'],
                            point['az'],
                            point['gx'],
                            point['gy'],
                            point['gz'],
                            point.get('lat', ''),      # Store GPS if available, blank if not
                            point.get('lon', '')
                        ])
                print(f"Logged {len(batch)} data points (background)")
            except Exception as e:
                print(f"Error logging to CSV: {str(e)}")
        else:
            time.sleep(0.2)  # Sleep briefly if no data

@app.route('/api', methods=['POST'])
def receive_data():
    try:
        raw_data = request.get_data()
        try:
            data = json.loads(raw_data)
        except Exception as e:
            print(f"Failed to parse as JSON: {e}")
            return jsonify({"status": "error", "message": "Invalid JSON"}), 400

        if not isinstance(data, dict) or 'data' not in data:
            return jsonify({"status": "error", "message": "Missing 'data' field"}), 400

        data_points = []
        for point in data['data']:
            # Accept and store lat/lon if present
            data_points.append({
                'timestamp': point['t'],
                'ax': point['x'],
                'ay': point['y'],
                'az': point['z'],
                'gx': point['gx'],
                'gy': point['gy'],
                'gz': point['gz'],
                'lat': point.get('lat', None),
                'lon': point.get('lon', None)
            })

        # Queue data for background logging
        with log_queue_lock:
            log_queue.extend(data_points)

        # Update live data and stats
        with data_lock:
            for point in data_points:
                sensor_data['timestamps'].append(point['timestamp'])
                sensor_data['accel']['x'].append(point['ax'])
                sensor_data['accel']['y'].append(point['ay'])
                sensor_data['accel']['z'].append(point['az'])
                sensor_data['gyro']['x'].append(point['gx'])
                sensor_data['gyro']['y'].append(point['gy'])
                sensor_data['gyro']['z'].append(point['gz'])
                sensor_data['lat'].append(point.get('lat'))
                sensor_data['lon'].append(point.get('lon'))
            stats['total_readings'] += len(data_points)
            stats['total_chunks'] += 1
            stats['last_update'] = time.strftime("%Y-%m-%d %H:%M:%S")

        return jsonify({"status": "success", "message": "Data received and queued"}), 200

    except Exception as e:
        print(f"Server error: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/data', methods=['GET'])
def get_live_data():
    with data_lock:
        return jsonify({
            'timestamps': list(sensor_data['timestamps']),
            'accel': {
                'x': list(sensor_data['accel']['x']),
                'y': list(sensor_data['accel']['y']),
                'z': list(sensor_data['accel']['z'])
            },
            'gyro': {
                'x': list(sensor_data['gyro']['x']),
                'y': list(sensor_data['gyro']['y']),
                'z': list(sensor_data['gyro']['z'])
            },
            'lat': list(sensor_data['lat']),
            'lon': list(sensor_data['lon'])
        })

@app.route('/api/stats', methods=['GET'])
def get_stats():
    return jsonify(stats)

@app.route('/test', methods=['GET', 'POST'])
def test_endpoint():
    if request.method == 'POST':
        return jsonify({
            "status": "success",
            "message": "Test POST received",
            "data": request.get_json(silent=True) or request.form.to_dict()
        }), 200
    return jsonify({
        "status": "success",
        "message": "Test endpoint active"
    }), 200

if __name__ == '__main__':
    print("Starting Sensor Data Server...")
    initialize_csv_logging()
    # Start background logging thread
    log_thread = threading.Thread(target=log_data_to_csv_background, daemon=True)
    log_thread.start()
    try:
        app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
    finally:
        log_thread_running = False
        log_thread.join()
