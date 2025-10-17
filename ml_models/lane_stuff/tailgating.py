import cv2
import math
import time
import torch
import json
from datetime import datetime
from ultralytics import YOLO

# -------------------------
# Config
# -------------------------
MODEL_NAME = "yolov8n.pt"
IMGSZ = 480
DISPLAY_W, DISPLAY_H = 960, 540
CONF_THRES = 0.5

# Added "auto" (auto rickshaw) height and safe distance
REAL_HEIGHTS = {
    "car": 1.5,
    "motorcycle": 1.2,
    "bus": 3.2,
    "truck": 3.0,
    "auto": 1.6  # meters
}

SAFE_DIST = {
    "car": 10,
    "motorcycle": 8,
    "bus": 20,
    "truck": 25,
    "auto": 9  # meters
}

FOCAL_LENGTH = 900

# -------------------------
# Model setup
# -------------------------
model = YOLO(MODEL_NAME)
use_cuda = torch.cuda.is_available()

if use_cuda:
    model.to("cuda")
    torch.set_float32_matmul_precision("medium")

vehicle_labels = set(REAL_HEIGHTS.keys())
vehicle_class_ids = [i for i, n in model.names.items() if n.lower() in vehicle_labels]


# -------------------------
# Simple IOU Tracker
# -------------------------
class Track:
    def __init__(self, tid, xyxy):
        self.id = tid
        self.xyxy = xyxy
        self.last_seen = 0


def iou(a, b):
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b

    inter_x1, inter_y1 = max(ax1, bx1), max(ay1, by1)
    inter_x2, inter_y2 = min(ax2, bx2), min(ay2, by2)

    iw, ih = max(0, inter_x2 - inter_x1), max(0, inter_y2 - inter_y1)
    inter = iw * ih
    if inter == 0:
        return 0.0

    area_a = (ax2 - ax1) * (ay2 - ay1)
    area_b = (bx2 - bx1) * (by2 - by1)

    return inter / (area_a + area_b - inter + 1e-6)


class IOUTracker:
    def __init__(self, iou_thresh=0.35, max_age=10):
        self.tracks = []
        self.next_id = 0
        self.iou_thresh = iou_thresh
        self.max_age = max_age

    def update(self, dets):
        for t in self.tracks:
            t.last_seen += 1

        assigned_ids = set()
        outputs = []

        for xyxy, label in dets:
            best_iou, best_track = 0.0, None
            for t in self.tracks:
                i = iou(xyxy, t.xyxy)
                if i > best_iou:
                    best_iou, best_track = i, t

            if best_iou >= self.iou_thresh:
                best_track.xyxy = xyxy
                best_track.last_seen = 0
                assigned_ids.add(best_track.id)
                outputs.append((best_track.id, xyxy, label))
            else:
                t = Track(self.next_id, xyxy)
                self.next_id += 1
                self.tracks.append(t)
                assigned_ids.add(t.id)
                outputs.append((t.id, xyxy, label))

        self.tracks = [
            t for t in self.tracks
            if t.last_seen <= self.max_age or t.id in assigned_ids
        ]
        return outputs


tracker = IOUTracker()

# -------------------------
# Tailgating timer storage + JSON logs
# -------------------------
tailgating_start_time = {}
json_records = []

video_path = r"C:\Users\pragy\lanedetection-microservice\reddittestlane3.mp4" 

# -------------------------
# Video setup
# -------------------------
cap = cv2.VideoCapture(video_path)
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(
    "tailgating_proof.mp4",
    fourcc,
    cap.get(cv2.CAP_PROP_FPS),
    (DISPLAY_W, DISPLAY_H)
)

frame_id = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    frame_id += 1
    timestamp_ms = int(cap.get(cv2.CAP_PROP_POS_MSEC))

    frame = cv2.resize(frame, (DISPLAY_W, DISPLAY_H))

    results = model.predict(
        frame,
        conf=CONF_THRES,
        classes=vehicle_class_ids,
        imgsz=IMGSZ,
        device=0 if use_cuda else None,
        verbose=False
    )

    dets = []
    if results and len(results[0].boxes) > 0:
        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            label = model.names[cls_id].lower()
            if label not in vehicle_labels:
                continue
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            dets.append(((x1, y1, x2, y2), label))

    tracks = tracker.update(dets)

    for tid, (x1, y1, x2, y2), label in tracks:
        h_pix = max(1, y2 - y1)
        real_h = REAL_HEIGHTS[label]
        distance_m = (real_h * FOCAL_LENGTH) / h_pix
        is_tailgating = distance_m < SAFE_DIST[label]

        # Manage tailgating timer
        if is_tailgating:
            if tid not in tailgating_start_time:
                tailgating_start_time[tid] = time.time()
            elapsed_time = time.time() - tailgating_start_time[tid]
        else:
            if tid in tailgating_start_time:
                del tailgating_start_time[tid]
            elapsed_time = 0

        # -------------------------
        # JSON record (per vehicle, per frame)
        # -------------------------
        record = {
            "frame_id": frame_id,
            "timestamp_ms": timestamp_ms,
            "vehicle_id": tid,
            "vehicle_type": label,
            "distance_m": round(distance_m, 2),
            "safe_distance_m": SAFE_DIST[label],
            "is_tailgating": is_tailgating,
            "tailgating_duration_s": round(elapsed_time, 2),
            "bbox": [x1, y1, x2, y2]
        }
        json_records.append(record)

        # Draw overlay
        color = (0, 0, 255) if is_tailgating else (0, 255, 255)
        text = f"{label} | {int(distance_m)}m"
        if is_tailgating:
            text += f" 🚨 {elapsed_time:.1f}s"

        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        (tw, th), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.55, 2)
        ty = max(20, y1 - 8)
        cv2.rectangle(frame, (x1, ty - th - 6), (x1 + tw + 8, ty + 4), color, cv2.FILLED)
        cv2.putText(frame, text, (x1 + 4, ty), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 0, 0), 2)

    # Save video frame
    out.write(frame)
    cv2.imshow("Tailgating Detection (Distance + Time)", frame)

    if cv2.waitKey(1) == 27:  # ESC
        break

cap.release()
out.release()
cv2.destroyAllWindows()

# -------------------------
# Save JSON log at end
# -------------------------
with open("tailgating_log.json", "w") as f:
    json.dump(json_records, f, indent=2)