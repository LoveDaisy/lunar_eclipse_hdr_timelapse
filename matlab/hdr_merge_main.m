clear; close all; clc;

path0 = getenv('PATH');
if ~contains(path0, '/usr/local/Cellar/dcraw/9.27.0_2/bin')
    path1 = ['/usr/local/Cellar/dcraw/9.27.0_2/bin:', path0];
    setenv('PATH', path1);
end

work_path = '/Volumes/ZJJ-4TB/Photos/18.01.31 Lunar Eclipse by Wang Letian/';
input_image_path = [work_path, '02/'];
output_image_path = [work_path, 'timelapse/'];

planned_expo_time = [8, 4, 2, 1, 1, 0.5, 1/8, 1/30, 1/125, 1/500];
planned_expo_iso = [6400, 3200, 1600, 800, 200, 100, 100, 100, 100, 100];

files = dir([input_image_path, 'IMG_*.CR2']);
total_images = length(files);
last_expo_idx = 0; start_file_id = 0;
for i = 1:total_images
    f_name = [input_image_path, files(i).name];
    f_info = imfinfo(f_name);
    t = f_info(1).DigitalCamera.ExposureTime;
    iso = f_info(1).DigitalCamera.ISOSpeedRatings;
    
    expo_idx = find(planned_expo_time == t & planned_expo_iso == iso);
    if expo_idx == 1 && last_expo_idx == 0
        start_file_id = i;
        last_expo_idx = expo_idx;
        continue;
    elseif expo_idx == length(planned_expo_time)
        if start_file_id > 0
            current_files = files(start_file_id:i);
        end
        last_expo_idx = 0;
    elseif expo_idx < last_expo_idx || abs(expo_idx - last_expo_idx) ~= 1
        if expo_idx == 1
            last_expo_idx = expo_idx;
            start_file_id = i;
        else
            last_expo_idx = 0;
            start_file_id = 0;
        end
        continue;
    else
        last_expo_idx = expo_idx;
        continue;
    end
    
    fprintf('Dealing with image #%d-%d\n', start_file_id, i);
    
    image_store = choose_valid_image(input_image_path, current_files);
    
    trans_mat = align_images(image_store);
    
    merge_result = hdr_merge(image_store, trans_mat);
    
    imwrite(uint16(merge_result * 65535), [output_image_path, sprintf('%d.tiff', i)]);
end
