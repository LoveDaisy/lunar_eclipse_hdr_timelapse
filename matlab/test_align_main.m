clear; close all; clc;

for n = 1:5
    image_path = sprintf('/Users/jiajiezhang/Desktop/tmp/%02d/', n);
    fprintf('Set image path: %s\n', image_path);
    files = dir(sprintf('%s/%s', image_path, 'IMG_*'));
    
    image_store = choose_valid_image(image_path, files);
    
    trans_mat = align_images(image_store);
    
    merge_result = hdr_merge(image_store, trans_mat);
    
    imwrite(uint8(merge_result * 255), [image_path, 'merge.jpg']);
end