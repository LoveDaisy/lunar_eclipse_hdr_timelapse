clear; clc; close all;


work_path = '/Volumes/ZJJ-4TB/Photos/18.01.31 Lunar Eclipse by Wang Letian/';
input_image_path = [work_path, '02/'];

img = im2double(imread([input_image_path, 'IMG_20689.ppm']));
img = srgb_gamma(img);

pyr = generate_laplacian_pyramid(img, 8, 1.35);

img1 = collapse_laplacian_pyramid(pyr);

%%
figure(1); clf;
imshow(img1);

figure(2); clf;
imagesc(pyr{end});
axis equal; axis tight; axis off;
