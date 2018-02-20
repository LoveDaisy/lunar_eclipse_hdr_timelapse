clear; close all; clc;

input_image_path = '~/Desktop/';

fprintf('Reading image #1...\n');
im1 = im2double(imread([input_image_path, '115.tiff']));
im1_v = mean(im1, 3);
fprintf('Reading image #2...\n');
im2 = im2double(imread([input_image_path, '116.tiff']));
im2_v = mean(im2, 3);

fprintf('Finding circles in image #1...\n')
[centers1, radii1] = imfindcircles(im1_v, [595, 625], ...
    'ObjectPolarity', 'bright', 'Sensitivity', 0.99, 'EdgeThreshold', 0.1);
[xx, yy] = meshgrid(1:size(im1_v, 2), 1:size(im1_v, 1));
moon_area1 = (xx - centers1(1, 1)).^2 + (yy - centers1(1, 2)).^2 <= radii1(1)^2;
fprintf('Finding circles in image #1...\n')
[centers2, radii2] = imfindcircles(im2_v, [595, 625], ...
    'ObjectPolarity', 'bright', 'Sensitivity', 0.99, 'EdgeThreshold', 0.1);
[xx, yy] = meshgrid(1:size(im1_v, 2), 1:size(im1_v, 1));
moon_area2 = (xx - centers2(1, 1)).^2 + (yy - centers2(1, 2)).^2 <= radii2(1)^2;

[hist_n1, e1] = histcounts(im1_v(moon_area1 & im1_v < 1), 256);
[hist_n2, e2] = histcounts(im2_v(moon_area2 & im2_v < 1), 256);

%%
figure(1); clf;
subplot(1,2,1);
plot((e1(1:end-1) + e1(2:end))/2, hist_n1);
set(gca, 'XLim', [0, 1]);
subplot(1,2,2);
plot((e2(1:end-1) + e2(2:end))/2, hist_n2);
set(gca, 'XLim', [0, 1]);
