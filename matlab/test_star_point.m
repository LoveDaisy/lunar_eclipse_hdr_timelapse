clear; close all; clc;

input_image_path = '~/Desktop/tmp/';

img1_name = 'IMG_19710.ppm';
img2_name = 'IMG_19705.ppm';
% img1_name = 'IMG_20499.ppm';
% img2_name = 'IMG_20495.ppm';
% img1_name = 'IMG_20717.ppm';
% img2_name = 'IMG_20715.ppm';
% img1_name = 'IMG_21026.ppm';
% img2_name = 'IMG_21024.ppm';
% img1_name = 'IMG_21665.ppm';
% img2_name = 'IMG_21663.ppm';

img1 = srgb_gamma(im2double(imread([input_image_path, img1_name])));
img1 = img1 / prctile(img1(:), 99.5) * 0.95;
img1_v = mean(img1, 3);

img2 = srgb_gamma(im2double(imread([input_image_path, img2_name])));
img2_v = mean(img2, 3);

% sky_area = img2_v < prctile(img2_v(:), 94);
% sky_area = bwareaopen(sky_area, 100000);
% sky_area = bwareaopen(~sky_area, 100000);
% sky_area = ~imdilate(sky_area, strel('disk', 4, 4));

img_size = size(img2_v);
[centers, radii] = imfindcircles(img2_v, [595, 625], ...
    'ObjectPolarity', 'bright', 'Sensitivity', 0.99, 'EdgeThreshold', 0.1);
if ~isempty(radii)
    [xx, yy] = meshgrid(1:img_size(2), 1:img_size(1));
    bw = (xx - centers(1,1)).^2 + (yy - centers(1,2)).^2 < radii(1)^2;
    sky_area = ~imdilate(bw, strel('disk', 20, 4));
else
    fprintf('WARNING: no circle detected!');
    sky_area = true(img_size);
end

% h = fspecial('gaussian', 20, 10);
% img2_v_m = imfilter(img2_v, h, 'symmetric');
% img2_v_d = sqrt(imfilter((img2_v - img2_v_m).^2, h, 'symmetric')) + 0.02;
% img2_v_eh = (img2_v - img2_v_m) ./ img2_v_d;

%%
img2_log_4 = max(imfilter(img2_v, -fspecial('log', 15, 4), 'symmetric'), 0) .* sky_area;
star_v_4 = imfilter(double(img2_log_4 > max(img2_log_4(:))*0.07), fspecial('gaussian', 8, 1.5), 'symmetric') ...
    .* img2_log_4;
stars = bsxfun(@times, img2, star_v_4).^.6;
stars = stars / prctile(stars(stars > 0), 98) * 0.9;
stars(isnan(stars)) = 0;

%%
figure(1); clf;
imshow(img1);

figure(2); clf;
imshow(stars + img1);