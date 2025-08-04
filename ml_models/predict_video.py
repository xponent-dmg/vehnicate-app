from ultralytics import YOLO
import cv2

# ML lead model
# model = YOLO(r"C:\Users\pragy\Downloads\best-final.pt")

# My 1st version
# model = YOLO(r"C:/Users/pragy/prototype/ml_models/runs/detect/train2/weights/best.pt")

# My 2nd version - most performing
model = YOLO(r"C:\Users\pragy\Downloads\new-best.pt")


video_path = r"C:\Users\pragy\prototype\ml_models\assets\30thJuly_trial.mp4"
cap = cv2.VideoCapture(video_path)

save_output = True
output_path = "C:/Users/pragy/prototype/ml_models/assets/output_annotated.mp4"


fps    = cap.get(cv2.CAP_PROP_FPS)
width  = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

if save_output:
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    results = model.predict(
        source=frame,
        imgsz=(width, height),  
        rect=True               
    )
    annotated_frame = results[0].plot() 

    cv2.imshow('YOLOv8 Video Detection', annotated_frame)

    if save_output:
        out.write(annotated_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
if save_output:
    out.release()
cv2.destroyAllWindows()
