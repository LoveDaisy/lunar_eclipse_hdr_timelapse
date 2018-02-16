function expo_groups = collapse_exposure_groups(input_image_path)
planned_expo_time = [8, 4, 2, 1, 1, 0.5, 1/8, 1/30, 1/125, 1/500];
planned_expo_iso = [6400, 3200, 1600, 800, 200, 100, 100, 100, 100, 100];

files = dir([input_image_path, '*.CR2']);
total_images = length(files);

last_expo_idx = 0; start_file_id = 0;
expo_groups = struct('files', [], 'idx_range', []);
k = 1;
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
            last_expo_idx = 0;
        else
            last_expo_idx = 0;
            continue;
        end
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

    fprintf('Find exposure group #%d-%d\n', start_file_id, i);
    expo_groups(k).files = current_files;
    expo_groups(k).idx_range = [start_file_id, i];
    k = k+1;
end
end