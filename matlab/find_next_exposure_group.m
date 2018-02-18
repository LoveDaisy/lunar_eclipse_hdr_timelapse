function expo_group = find_next_exposure_group(input_image_path, start_idx)
planned_expo_time = [8, 4, 2, 1, 1, 0.5, 1/8, 1/30, 1/125, 1/500];
planned_expo_iso = [6400, 3200, 1600, 800, 200, 100, 100, 100, 100, 100];

files = dir([input_image_path, '*.CR2']);
total_images = length(files);

last_expo_idx = 0; start_file_id = 0;
current_files = [];
for i = start_idx:total_images
    f_name = [input_image_path, files(i).name];
    f_info = imfinfo(f_name);
    t = f_info(1).DigitalCamera.ExposureTime;
    iso = f_info(1).DigitalCamera.ISOSpeedRatings;
    
    expo_idx = find(planned_expo_time == t & planned_expo_iso == iso);
    if expo_idx == 1 && last_expo_idx == 0
        start_file_id = i;
        last_expo_idx = expo_idx;
    elseif expo_idx == length(planned_expo_time)
        if start_file_id > 0
            current_files = files(start_file_id:i);
            break;
        else
            last_expo_idx = 0;
        end
    elseif expo_idx < last_expo_idx || abs(expo_idx - last_expo_idx) ~= 1
        if expo_idx == 1
            last_expo_idx = expo_idx;
            start_file_id = i;
        else
            last_expo_idx = 0;
            start_file_id = 0;
        end
    else
        last_expo_idx = expo_idx;
    end
end

if ~isempty(current_files)
    fprintf('Find exposure group #%d-%d\n', start_file_id, i);
    expo_group.files = current_files;
    expo_group.idx_range = [start_file_id, i];
else
    expo_group.files = [];
    expo_group.idx_range = [];
end
end