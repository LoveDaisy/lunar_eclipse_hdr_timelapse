clear; close all; clc;

work_path = '/Volumes/ZJJ-4TB/Photos/18.01.31 Lunar Eclipse by Wang Letian/';
input_image_path = [work_path, '02/'];

files = dir([input_image_path, 'IMG_*.CR2']);
files_idx = reshape(bsxfun(@plus, (0:9)', (100:150:3800)), [], 1);

[hist_store, exp_store, valid_flags] = test_valid_image(input_image_path, files(files_idx));