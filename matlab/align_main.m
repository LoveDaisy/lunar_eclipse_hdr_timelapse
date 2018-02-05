clear; close all; clc;

image_path = '/Users/jiajiezhang/Desktop/tmp/03/';
files = dir(sprintf('%s/%s', image_path, '*.TIF'));
n = length(files);

image_store = cell(n, 1);
kur_store = zeros(n, 1);
skw_store = zeros(n, 1);
for i = 1:n
    fprintf('Reading image %s...\n', files(i).name);
    img = im2double(imread(sprintf('%s/%s', image_path, files(i).name)));
    img_size = size(img);
    kur = kurtosis(img(:));
    skw = skewness(img(:));
    kur_store(i) = kur;
    skw_store(i) = skw;
end

local_dtl_store = cell(n, 1);
h = fspecial('gaussian', 40, 10);
for i = 1:n
    fprintf('Calculating local detail %d/%d ...\n', i, n);
    gray = rgb2gray(image_store{i});
    m = imfilter(gray, h, 'symmetric');
    d = sqrt(imfilter((gray - m).^2, h, 'symmetric'));
    local_dtl_store{i} = (gray - m) ./ d;
end

fft_store = cell(n, 1);
trans_mat = zeros(n, n, 2);
for i = 1:n
    fprintf('FFT to image %d/%d...\n', i, n);
    fft_store{i} = fft2(local_dtl_store{i});
end

%%% image_i translated by trans_mat(i,j) then meets image_j
for i = 1:n
    for j = i+1:n
        fprintf('Estimating translation between (%d, %d)...\n', i, j);
        tmp = ifftshift(ifft2(fft_store{i} ./ fft_store{j}));
        tmp = imfilter(tmp, fspecial('gaussian', 8, 2.5));
        [~, idx] = max(tmp(:));
        [r, c] = ind2sub(size(tmp), idx);
        trans_mat(i, j, :) = wrev(size(tmp) / 2) - [c, r];
    end
end
trans_mat(:, :, 1) = trans_mat(:, :, 1) - trans_mat(:, :, 1)';
trans_mat(:, :, 2) = trans_mat(:, :, 2) - trans_mat(:, :, 2)';

clear local_dtl_store;
clear fft_store;

%%
image_align_store = cell(n, 1);
align_idx = 9;
for i = 1:n
    if i == align_idx
        image_align_store{i} = image_store{i};
        continue;
    end
    fprintf('Translating image %d/%d...\n', i, n);
    d = trans_mat(i, align_idx, :);
    image_align_store{i} = imtranslate(image_store{i}, d(:)');
end

clear image_store;

%%
mu = 0.3; sig = 0.25;
w_store = cell(n, 1);
for i = 1:n
    gray = rgb2gray(image_align_store{i});
    w_store{i} = exp(-(gray - mu).^2 / sig^2);
end
img_blend = pyramid_blend(8, image_align_store, w_store);

figure(1); clf;
imshow(img_blend);