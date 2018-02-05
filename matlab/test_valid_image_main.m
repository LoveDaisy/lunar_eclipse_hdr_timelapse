clear; close all; clc;

image_path = '/Users/jiajiezhang/Desktop/tmp/02/';
files = dir(sprintf('%s/%s', image_path, '*.TIF'));
image_store = choose_valid_image(image_path, files);