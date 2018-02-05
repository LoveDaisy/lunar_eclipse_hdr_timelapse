clear; close all; clc;

path0 = getenv('PATH');
if ~contains(path0, '/usr/local/Cellar/dcraw/9.27.0_2/bin')
    path1 = ['/usr/local/Cellar/dcraw/9.27.0_2/bin:', path0];
    setenv('PATH', path1);
end

for n = 1:5
    image_path = sprintf('/Users/jiajiezhang/Desktop/tmp/%02d/', n);
    fprintf('Set image path: %s\n', image_path);
    files = dir(sprintf('%s/%s', image_path, 'IMG_*'));
    
    image_store = choose_valid_image(image_path, files);
    
    trans_mat = align_images(image_store);
    
    merge_result = hdr_merge(image_store, trans_mat);
    
    imwrite(uint8(merge_result * 255), [image_path, 'merge.jpg']);
end