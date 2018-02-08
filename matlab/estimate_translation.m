function t = estimate_translation(img1, img2)
% This function estimates translation between img1 and img2
h = fspecial('gaussian', 20, 5);

img_size = size(img1);
img_center = floor(img_size(1:2)/2);
img1 = img1(img_center(1)-900:img_center(1)+900, img_center(2)-900:img_center(2)+900);
m = imfilter(img1, h, 'symmetric');
d = sqrt(imfilter((img1 - m).^2, h, 'symmetric'));
img1_he = (img1 - m) ./ (d + 0.03);
img1_fft = fft2(img1_he);

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

t = wrev(size(tmp) / 2) - sum([xx(:).*w(:), yy(:).*w(:)]) + 0.5;
end