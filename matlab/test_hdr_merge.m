clear; clc; close all;

pyr_layers = 4;
pyr_sig = 1.35;

img_files = dir('./*.tiff');
total_w = 0;
for i = [1, 5, 9]
    fprintf('reading image %s...\n', img_files(i).name);
    img = im2double(imread(img_files(i).name));
    img_v = mean(img, 3);
    
    w = exp(-abs((img_v - 0.52) ./ 0.55).^2);
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
    
%     tmp = bsxfun(@times, max(collapse_laplacian_pyramid(merge_pyr), 0), 1./total_w);
%     figure(1); clf;
%     imshow(tmp.^.5);
end

% total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
% for j = 1:length(merge_pyr)
%     merge_pyr{j} = bsxfun(@times, merge_pyr{j}, 1./total_w_pyr{j});
% end
merge_result = bsxfun(@times, max(collapse_laplacian_pyramid(merge_pyr), 0), 1./total_w);

figure(1); clf;
imshow(merge_result.^.5);