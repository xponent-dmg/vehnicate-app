import os
import shutil
import random
import glob
from pathlib import Path

def remap_labels(label_file_path, new_class_index):
    
    with open(label_file_path, 'r') as f:
        lines = f.readlines()
    
    with open(label_file_path, 'w') as f:
        for line in lines:
            parts = line.strip().split(' ')
            if parts and parts[0]:  
                parts[0] = str(new_class_index)
                f.write(' '.join(parts) + '\n')

def copy_and_remap_dataset(source_images_dir, source_labels_dir, 
                          dest_images_dir, dest_labels_dir, 
                          new_class_index, num_samples=200, exclude_images=None):
   
    if exclude_images is None:
        exclude_images = set()
    
    image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.bmp']
    image_files = []
    for ext in image_extensions:
        image_files.extend(glob.glob(os.path.join(source_images_dir, ext)))
        image_files.extend(glob.glob(os.path.join(source_images_dir, ext.upper())))
    
    available_images = [img for img in image_files if os.path.basename(img) not in exclude_images]
    
    if len(available_images) < num_samples:
        print(f"Warning: Only {len(available_images)} images available, using all of them")
        selected_images = available_images
    else:
        selected_images = random.sample(available_images, num_samples)
    
    copied_count = 0
    used_images = set()
    
    for image_path in selected_images:
        image_name = os.path.basename(image_path)
        image_name_without_ext = os.path.splitext(image_name)[0]  
        
        label_file = os.path.join(source_labels_dir, f"{image_name_without_ext}.txt")
        
        if os.path.exists(label_file):
            dest_image_path = os.path.join(dest_images_dir, image_name)
            shutil.copy2(image_path, dest_image_path)
            
            dest_label_path = os.path.join(dest_labels_dir, f"{image_name_without_ext}.txt")
            shutil.copy2(label_file, dest_label_path)
            remap_labels(dest_label_path, new_class_index)
            
            copied_count += 1
            used_images.add(image_name)
        else:
            print(f"Warning: Label file not found for {image_name}")
    
    return copied_count, used_images

def create_mega_dataset(datasets_config, output_dir, train_samples_per_class=200, valid_samples_per_class=50):
    
    train_images_dir = os.path.join(output_dir, 'train', 'images')
    train_labels_dir = os.path.join(output_dir, 'train', 'labels')
    valid_images_dir = os.path.join(output_dir, 'valid', 'images')
    valid_labels_dir = os.path.join(output_dir, 'valid', 'labels')
    
    os.makedirs(train_images_dir, exist_ok=True)
    os.makedirs(train_labels_dir, exist_ok=True)
    os.makedirs(valid_images_dir, exist_ok=True)
    os.makedirs(valid_labels_dir, exist_ok=True)
    
    random.seed(42)
    
    total_copied_train = 0
    total_copied_valid = 0
    class_names = []
    
    for dataset in datasets_config:
        print(f"\nProcessing {dataset['name']} dataset...")
        
        print(f"Creating training set for {dataset['name']}...")
        copied_train, used_train_images = copy_and_remap_dataset(
            dataset['images_dir'],
            dataset['labels_dir'],
            train_images_dir,
            train_labels_dir,
            dataset['new_class_index'],
            train_samples_per_class
        )
        print(f"Copied {copied_train} training samples from {dataset['name']} dataset")
        
        print(f"Creating validation set for {dataset['name']}...")
        copied_valid, used_valid_images = copy_and_remap_dataset(
            dataset['images_dir'],
            dataset['labels_dir'],
            valid_images_dir,
            valid_labels_dir,
            dataset['new_class_index'],
            valid_samples_per_class,
            exclude_images=used_train_images
        )
        print(f"Copied {copied_valid} validation samples from {dataset['name']} dataset")
        
        total_copied_train += copied_train
        total_copied_valid += copied_valid
        class_names.append(dataset['name'])
    
    create_data_yaml(output_dir, class_names)
    
    print(f"\n{'='*50}")
    print(f"Dataset creation completed!")
    print(f"{'='*50}")
    print(f"Total training images: {total_copied_train}")
    print(f"Total validation images: {total_copied_valid}")
    print(f"Output directory: {output_dir}")
    print(f"Classes: {class_names}")
    
    return total_copied_train, total_copied_valid

def create_data_yaml(output_dir, class_names):
    
    yaml_content = f"""path: {os.path.abspath(output_dir)}
train: train/images
val: valid/images
nc: {len(class_names)}
names:
"""
    
    for i, name in enumerate(class_names):
        yaml_content += f"  {i}: {name}\n"
    
    yaml_path = os.path.join(output_dir, 'data.yaml')
    with open(yaml_path, 'w') as f:
        f.write(yaml_content)
    
    print(f"Created data.yaml at {yaml_path}")

datasets_config = [
        {
            'name': 'potholes',
            'images_dir': r'C:\Users\pragy\prototype\ml_models\cumta_potholes\images',  
            'labels_dir': r'C:\Users\pragy\prototype\ml_models\cumta_potholes\labels',  
            'new_class_index': 0
        },
        {
            'name': 'speedbumps',
            'images_dir': r'C:\Users\pragy\prototype\ml_models\cumta_markedspeedbumps\images',  
            'labels_dir': r'C:\Users\pragy\prototype\ml_models\cumta_markedspeedbumps\labels',  
            'new_class_index': 1
        },
        {
            'name': 'zebracrossing',
            'images_dir': r'C:\Users\pragy\prototype\ml_models\cumta_zebracross\images',  
            'labels_dir': r'C:\Users\pragy\prototype\ml_models\cumta_zebracross\labels', 
            'new_class_index': 2
        }
    ]
    

output_directory = 'mega_dataset'

if __name__ == "__main__":
    create_mega_dataset(datasets_config, output_directory, 
                       train_samples_per_class=200, 
                       valid_samples_per_class=50)
