function trans_mat = align_images(image_store)
% INPUT
%   image_store:    struct array.
%                   .image
%                   .exposure
% OUTPUT
%   trans_mat:      2*n*n

h = fspecial('gaussian', 20, 5);

total_images = length(image_store);
% tmp_expo = cat(1, image_store.exposure);
% [distinct_expo, ia, ic] = unique(tmp_expo(:,1));
% total_expos = size(distinct_expo, 1);
[distinct_expo, ia, ic] = unique(cat(1, image_store.expo));
total_expos = length(distinct_expo);

unique_trans_mat = zeros(2, total_expos, total_expos);
for i = 1:total_expos-1
    fprintf('Estimating alignment between (%d,%d)...\n', i, i+1);
    
    if ~exist('img2_fft', 'var')
        img1 = mean(im2double(image_store(ia(i)).image), 3);
        img_size = size(img1);
        img_center = floor(img_size(1:2)/2);
        img1 = img1(img_center(1)-900:img_center(1)+900, img_center(2)-900:img_center(2)+900);
        m = imfilter(img1, h, 'symmetric');
        d = sqrt(imfilter((img1 - m).^2, h, 'symmetric'));
        img1_he = (img1 - m) ./ (d + 0.03);
        img1_fft = fft2(img1_he);
    else
        img1_fft = img2_fft;
    end
    
    img2 = mean(im2double(image_store(ia(i+1)).image), 3);
    img_size = size(img2);
    img_center = floor(img_size(1:2)/2);
    img2 = img2(img_center(1)-900:img_center(1)+900, img_center(2)-900:img_center(2)+900);
    m = imfilter(img2, h, 'symmetric');
    d = sqrt(imfilter((img2 - m).^2, h, 'symmetric'));
    img2_he = (img2 - m) ./ (d + 0.03);
    img2_fft = fft2(img2_he);

    tmp = ifftshift(ifft2(img1_fft ./ img2_fft));
    tmp = imfilter(tmp, fspecial('gaussian', 8, 2.0));
    [~, idx] = max(tmp(:));
    [r, c] = ind2sub(size(tmp), idx);
    [xx, yy] = meshgrid(c-6:c+6, r-6:r+6);
    w = (max(tmp(r-6:r+6, c-6:c+6), 0)).^2;
    w = w / sum(w(:));
        
    unique_trans_mat(:, i, i+1) = reshape(wrev(size(tmp) / 2) - ...
        sum([xx(:).*w(:), yy(:).*w(:)]) + 0.5, [], 1);
    unique_trans_mat(:, i+1, i) = unique_trans_mat(:, i, i+1);
end

for i = 1:total_expos
    for j = i+2:total_expos
        unique_trans_mat(:, i, j) = unique_trans_mat(:, i, j-1) + unique_trans_mat(:, j-1, j);
        unique_trans_mat(:, j, i) = unique_trans_mat(:, i, j);
    end
end

trans_mat = zeros(2, total_images, total_images);
for i = 1:total_images
    for j = i+1:total_images
        trans_mat(:, i, j) = unique_trans_mat(:, ic(i), ic(j));
        trans_mat(:, j, i) = trans_mat(:, i, j);
    end
end
end