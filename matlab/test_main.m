clear; close all;

img_path = '/Users/jiajiezhang/Desktop/tmp/03/';
file_name = 'IMG_21663_+0.67.TIF';

img = im2double(imread([img_path, file_name]));

figure(1); clf;
hist(img(:), 200);