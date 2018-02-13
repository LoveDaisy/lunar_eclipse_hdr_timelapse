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
files_idx = reshape(bsxfun(@plus, (0:9)', (1:100:3700)), [], 1);

[hist_store, valid_flags] = test_valid_image(input_image_path, files(files_idx));