clear; close all; clc;

for n = 1
image_path = sprintf('/Users/jiajiezhang/Desktop/tmp/%02d/', n);
% image_path = '/Users/jiajiezhang/Desktop/tmp/02/';
fprintf('Set image path: %s\n', image_path);
files = dir(sprintf('%s/%s', image_path, 'IMG_*'));
image_store = choose_valid_image(image_path, files);

trans_mat = align_images(image_store);

merge_result = hdr_merge(image_store, trans_mat);

% imwrite(uint16(merge_result * 65535), [image_path, 'merge.tif']);
end