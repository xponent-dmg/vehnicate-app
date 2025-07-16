from ultralytics import YOLO
import multiprocessing

def main():
    model = YOLO('yolov8n.pt')
    model.train(
        data=r'C:\Users\pragy\prototype\ml_models\mega_dataset\data.yaml',
        epochs=100,
        imgsz=412,
        batch=32,
        workers=2,
        device='cuda'  
    )

if __name__ == '__main__':
    multiprocessing.freeze_support()    
    main()
