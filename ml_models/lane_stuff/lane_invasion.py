import cv2
import json
import numpy as np
from collections import deque
import datetime

# -------------------
# Configuration (tuned for Indian roads)
# -------------------
VIDEO_PATH = r"C:\Users\pragy\lanedetection-microservice\reddittestlane3.mp4"  # <-- set your video file path here
HISTORY_LEN = 4         # smoothing across frames
SAMPLE_Y_FRAC_START = 0.98
SAMPLE_Y_FRAC_END = 0.60
NUM_SAMPLE_Y = 50
MIN_POINTS_TO_ACCEPT = 10
XM_PER_PIX_BASE = 3.5    # assumed real lane width in meters
LANE_WIDTH_PIX_FRAC = 0.68
INVASION_MARGIN_PIX = 30
OUTPUT_WIDTH = 800       # for output window
OUTPUT_JSON = "lane_detection_results.json"

# -------------------
# Helpers & Improvements
# -------------------

def adaptive_color_mask(frame):
    """HSV-based mask with V equalization, tuned for yellow + white lanes."""
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    v = hsv[:, :, 2]
    v_eq = cv2.equalizeHist(v)
    hsv[:, :, 2] = v_eq

    # yellow and white ranges (tweakable)
    lower_yellow = np.array([12, 65, 70])
    upper_yellow = np.array([40, 255, 255])
    mask_y = cv2.inRange(hsv, lower_yellow, upper_yellow)

    lower_white = np.array([0, 0, 150])
    upper_white = np.array([180, 60, 255])
    mask_w = cv2.inRange(hsv, lower_white, upper_white)

    mask = cv2.bitwise_or(mask_y, mask_w)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=1)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    return mask

def region_of_interest_mask(img):
    """Polygonal ROI to mask irrelevant areas (roads focused)."""
    h, w = img.shape[:2]
    polygons = np.array([[
        (int(0.08 * w), h),
        (int(0.38 * w), int(SAMPLE_Y_FRAC_END * h)),
        (int(0.62 * w), int(SAMPLE_Y_FRAC_END * h)),
        (int(0.92 * w), h)
    ]], dtype=np.int32)
    mask = np.zeros((h, w), dtype=np.uint8)
    cv2.fillPoly(mask, polygons, 255)
    return mask

def extract_line_points_from_hough(lines, img_shape, slope_thresh=0.35):
    """Classify Hough segments into left / right arrays of endpoints."""
    if lines is None:
        return [], []
    h, w = img_shape[:2]
    center_x = w // 2
    left_pts, right_pts = [], []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        if x2 == x1:
            continue
        slope = (y2 - y1) / (x2 - x1 + 1e-8)
        if slope < -slope_thresh and x1 < center_x and x2 < center_x:
            left_pts += [(x1, y1), (x2, y2)]
        elif slope > slope_thresh and x1 > center_x and x2 > center_x:
            right_pts += [(x1, y1), (x2, y2)]
    return left_pts, right_pts

def eval_poly(coeffs, y_vals):
    if coeffs is None:
        return None
    return np.polyval(coeffs, y_vals)

class SmoothedLane:
    def __init__(self, maxlen=HISTORY_LEN, num_y=NUM_SAMPLE_Y):
        self.history = deque(maxlen=maxlen)
        self.num_y = num_y

    def add(self, x_vals):
        if x_vals is None:
            self.history.append(None)
        else:
            arr = np.array(x_vals, dtype=float)
            if arr.shape[0] != self.num_y:
                arr = np.resize(arr, (self.num_y,))
            self.history.append(arr)

    def get_smoothed(self):
        arrays = [a for a in self.history if a is not None]
        if not arrays:
            return None
        stacked = np.vstack(arrays)
        return np.nanmean(stacked, axis=0)

class LaneInvasionTracker:
    def __init__(self, frame_width, margin=INVASION_MARGIN_PIX):
        self.frame_width = frame_width
        self.margin = margin
        self.left_invasion_count = 0
        self.right_invasion_count = 0
        self.in_left_lane = False
        self.in_right_lane = False

    def update(self, left_x_at_bottom, right_x_at_bottom):
        car_x = self.frame_width // 2
        left_x = left_x_at_bottom
        right_x = right_x_at_bottom
        if left_x is None or right_x is None:
            self.in_left_lane = False
            self.in_right_lane = False
            return
        if car_x < (left_x - self.margin) and not self.in_left_lane:
            self.left_invasion_count += 1
            self.in_left_lane = True
        elif car_x >= (left_x + self.margin):
            self.in_left_lane = False
        if car_x > (right_x + self.margin) and not self.in_right_lane:
            self.right_invasion_count += 1
            self.in_right_lane = True
        elif car_x <= (right_x - self.margin):
            self.in_right_lane = False

    def display_counts(self, img):
        cv2.putText(img, f"Left Lane Invasions: {self.left_invasion_count}", (20, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.85, (0, 0, 255), 2)
        cv2.putText(img, f"Right Lane Invasions: {self.right_invasion_count}", (20, 95),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.85, (0, 0, 255), 2)

def calculate_distances_from_center(left_x, right_x, frame_width):
    car_x = frame_width // 2
    if left_x is None or right_x is None or not (np.isfinite(left_x) and np.isfinite(right_x)):
        xm_per_pix = XM_PER_PIX_BASE / (frame_width * LANE_WIDTH_PIX_FRAC)
    else:
        lane_px = abs(right_x - left_x)
        if lane_px > 1.0:
            xm_per_pix = XM_PER_PIX_BASE / lane_px
        else:
            xm_per_pix = XM_PER_PIX_BASE / (frame_width * LANE_WIDTH_PIX_FRAC)
    dist_left = (car_x - left_x) * xm_per_pix if left_x is not None and np.isfinite(left_x) else None
    dist_right = (right_x - car_x) * xm_per_pix if right_x is not None and np.isfinite(right_x) else None
    return dist_left, dist_right

def safe_polyfit(x_vals, y_vals, deg=2):
    try:
        coeffs = np.polyfit(y_vals, x_vals, deg)
        return coeffs
    except Exception:
        try:
            if len(y_vals) >= 2:
                lin = np.polyfit(y_vals, x_vals, 1)
                if lin is not None:
                    return np.array([0.0, lin[0], lin[1]])
        except Exception:
            return None
    return None

class LaneDetector:
    def __init__(self, frame_shape):
        h, w = frame_shape[:2]
        self.h = h
        self.w = w
        y_start = int(SAMPLE_Y_FRAC_START * h)
        y_end = int(SAMPLE_Y_FRAC_END * h)
        self.y_vals = np.linspace(y_start, y_end, NUM_SAMPLE_Y)
        self.left_smoothed = SmoothedLane(maxlen=HISTORY_LEN, num_y=NUM_SAMPLE_Y)
        self.right_smoothed = SmoothedLane(maxlen=HISTORY_LEN, num_y=NUM_SAMPLE_Y)
        self.invasion_tracker = LaneInvasionTracker(w)
        self.debug = False
        self.last_distances = (None, None)  # store last computed distances

    def process_frame(self, frame):
        vis = frame.copy()
        mask = adaptive_color_mask(frame)
        blur = cv2.GaussianBlur(mask, (5, 5), 0)
        edges = cv2.Canny(blur, 45, 120)
        roi_mask = region_of_interest_mask(edges)
        cropped_edges = cv2.bitwise_and(edges, roi_mask)

        lines = cv2.HoughLinesP(cropped_edges, rho=1, theta=np.pi/180, threshold=25,
                                minLineLength=30, maxLineGap=95)
        left_pts, right_pts = extract_line_points_from_hough(lines, frame.shape, slope_thresh=0.35)

        left_x_samples = self._generate_x_samples_from_points(left_pts)
        right_x_samples = self._generate_x_samples_from_points(right_pts)

        self.left_smoothed.add(left_x_samples if left_x_samples is not None else None)
        self.right_smoothed.add(right_x_samples if right_x_samples is not None else None)

        left_x_avg = self.left_smoothed.get_smoothed()
        right_x_avg = self.right_smoothed.get_smoothed()

        left_fit_coeffs, right_fit_coeffs = None, None

        if left_x_avg is not None and np.count_nonzero(~np.isnan(left_x_avg)) >= MIN_POINTS_TO_ACCEPT:
            valid_idx = ~np.isnan(left_x_avg)
            y_valid, x_valid = self.y_vals[valid_idx], left_x_avg[valid_idx]
            if len(x_valid) >= 2:
                left_fit_coeffs = safe_polyfit(x_valid, y_valid, deg=2)

        if right_x_avg is not None and np.count_nonzero(~np.isnan(right_x_avg)) >= MIN_POINTS_TO_ACCEPT:
            valid_idx = ~np.isnan(right_x_avg)
            y_valid, x_valid = self.y_vals[valid_idx], right_x_avg[valid_idx]
            if len(x_valid) >= 2:
                right_fit_coeffs = safe_polyfit(x_valid, y_valid, deg=2)

        output = vis.copy()

        left_x_bottom, right_x_bottom = None, None
        if left_fit_coeffs is not None:
            val = eval_poly(left_fit_coeffs, np.array([self.y_vals[0]]))[0]
            left_x_bottom = float(val) if np.isfinite(val) else None
        if right_fit_coeffs is not None:
            val = eval_poly(right_fit_coeffs, np.array([self.y_vals[0]]))[0]
            right_x_bottom = float(val) if np.isfinite(val) else None

        self.invasion_tracker.update(left_x_bottom, right_x_bottom)
        self.invasion_tracker.display_counts(output)

        dist_left, dist_right = calculate_distances_from_center(left_x_bottom, right_x_bottom, self.w)
        self.last_distances = (dist_left, dist_right)

        if dist_left is not None:
            cv2.putText(output, f"Dist Left: {dist_left:.2f} m", (20, 145),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        if dist_right is not None:
            cv2.putText(output, f"Dist Right: {dist_right:.2f} m", (20, 185),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

        output = resize_frame(output, OUTPUT_WIDTH)
        return output

    def _generate_x_samples_from_points(self, pts):
        if not pts:
            return None
        pts = np.array(pts)
        xs, ys = pts[:, 0].astype(float), pts[:, 1].astype(float)
        order = np.argsort(ys)
        ys_sorted, xs_sorted = ys[order], xs[order]
        if len(np.unique(ys_sorted)) < 3:
            return None
        x_at_y = np.interp(self.y_vals, ys_sorted, xs_sorted, left=np.nan, right=np.nan)
        min_y, max_y = ys_sorted.min(), ys_sorted.max()
        out_of_bounds = (self.y_vals < min_y) | (self.y_vals > max_y)
        x_at_y[out_of_bounds] = np.nan
        if np.count_nonzero(~np.isnan(x_at_y)) < MIN_POINTS_TO_ACCEPT:
            return None
        return x_at_y

def resize_frame(frame, new_width):
    h, w = frame.shape[:2]
    scale = new_width / w
    new_height = int(h * scale)
    return cv2.resize(frame, (new_width, new_height))

def main():
    cap = cv2.VideoCapture(VIDEO_PATH)
    if not cap.isOpened():
        print(f"Error: Could not open video file {VIDEO_PATH}")
        return
    ret, frame = cap.read()
    if not ret:
        print("Error: Could not read the first frame from video.")
        cap.release()
        return

    detector = LaneDetector(frame.shape)
    print("Controls: 'q' to quit, 's' to save current processed frame, 'd' to toggle debug overlays")
    saved_counter = 0
    results = []  # JSON log buffer

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        processed = detector.process_frame(frame)

        # --- log per-frame metrics with timestamp ---
        results.append({
            "timestamp": datetime.datetime.now().isoformat(),
            "frame": int(cap.get(cv2.CAP_PROP_POS_FRAMES)),
            "left_invasions": detector.invasion_tracker.left_invasion_count,
            "right_invasions": detector.invasion_tracker.right_invasion_count,
            "dist_left": detector.last_distances[0],
            "dist_right": detector.last_distances[1],
        })

        cv2.imshow("Lane Detection - Video", processed)
        key = cv2.waitKey(33) & 0xFF

        if key == ord('q'):
            break
        if key == ord('s'):
            save_path = f"processed_frame_{int(cap.get(cv2.CAP_PROP_POS_FRAMES))}.png"
            cv2.imwrite(save_path, processed)
            saved_counter += 1
            print(f"Saved: {save_path}")
        if key == ord('d'):
            detector.debug = not detector.debug
            print(f"Debug overlays {'ON' if detector.debug else 'OFF'}")

    # save JSON at end
    with open(OUTPUT_JSON, "w") as f:
        json.dump(results, f, indent=2)
    print(f"Saved results to {OUTPUT_JSON}")

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()