clear; close all; clc;

for n = 2
image_path = sprintf('/Users/jiajiezhang/Desktop/tmp/%02d/', n);
% image_path = '/Users/jiajiezhang/Desktop/tmp/02/';
fprintf('Set image path: %s\n', image_path);
files = dir(sprintf('%s/%s', image_path, 'IMG_*.TIF'));
image_store = choose_valid_image(image_path, files);

trans_mat = align_images(image_store);

clear *_pyr;
pyr_layers = 6;
pyr_sig = 1.35;
ref_ind = 3;
total_w = 0;
for i = 1:length(image_store)
    fprintf('Merging image %d/%d...\n', i, length(image_store));
    img = im2double(imtranslate(image_store(i).image, -trans_mat(:, i, ref_ind)'));
    img_v = mean(img, 3);
    
    w = exp(-(img_v - 0.55).^2 / 0.5^2);
    total_w = total_w + w;
    
    img_pyr = generate_laplacian_pyramid(img, pyr_layers, pyr_sig);
    w_pyr = generate_gaussian_pyramid(w, pyr_layers, pyr_sig);
    for j = 1:length(img_pyr)
        img_pyr{j} = bsxfun(@times, img_pyr{j}, w_pyr{j});
    end
    
    if ~exist('merge_pyr', 'var')
        merge_pyr = img_pyr;
    else
        for j = 1:length(merge_pyr)
            merge_pyr{j} = merge_pyr{j} + img_pyr{j};
        end
    end
    
%     tmp_pyr = merge_pyr;
%     total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
%     for j = 1:length(tmp_pyr)
%         tmp_pyr{j} = bsxfun(@times, tmp_pyr{j}, 1./total_w_pyr{j});
%     end
%     tmp_merge = collapse_laplacian_pyramid(tmp_pyr);
%     
%     figure(1); clf;
%     set(gcf, 'Position', [200, 100, 1200, 600]);
%     subplot(1,2,1);
%     imshow(tmp_merge);
%     subplot(1,2,2);
%     imagesc(w./total_w);
%     axis equal; axis tight; axis off;
%     colormap gray;
%     drawnow;
end

total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
for j = 1:length(merge_pyr)
    merge_pyr{j} = bsxfun(@times, merge_pyr{j}, 1./total_w_pyr{j});
end
merge_result = collapse_laplacian_pyramid(merge_pyr);

% imwrite(uint16(merge_result * 65535), [image_path, 'merge.tif']);
end