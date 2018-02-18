function merge_result = hdr_merge(image_store, trans_mat)
pyr_layers = 8;
pyr_sig = 1.35;
total_images = length(image_store);

if total_images == 1
    fprintf('Merging image 1/1...\n');
    merge_result = im2double(image_store.image);
    return
end

ref_ind = min(3, total_images);
merge_pyr = cell(pyr_layers+1, 1);
for i = 1:length(merge_pyr)
    merge_pyr{i} = 0;
end
% tmp_w = zeros(size(image_store(1).image, 1), size(image_store(1).image, 2), total_images);
total_w = 0;
for i = 1:total_images
    fprintf('Merging image %d/%d...\n', i, total_images);
    img = im2double(imtranslate(image_store(i).image, trans_mat(:, i, ref_ind)'));
    img_v = mean(img, 3);
    
    moon_area = find_moon_region(img_v);
    
    moon_w = gauss_decay_weight_function(img_v, 0.58, 0.34, 0.02, 0.01);
    sky_w = gauss_weight_function(img_v, 0.25, 0.32) .* (~moon_area);
    
%     img_log = max(imfilter(img_v, -fspecial('log', 8, 2.2), 'symmetric'), 0);
%     img_log = img_log .* ~imdilate(moon_area, strel('disk', 4, 4));

    w = (moon_w + sky_w);
    total_w = total_w + w;
    
    img_pyr = generate_laplacian_pyramid(img, pyr_layers, pyr_sig);
    w_pyr = generate_gaussian_pyramid(w, pyr_layers, pyr_sig);
    
    for j = 1:length(merge_pyr)
        merge_pyr{j} = merge_pyr{j} + bsxfun(@times, img_pyr{j}, w_pyr{j});
    end
    
end

total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
for j = 1:length(merge_pyr)
    merge_pyr{j} = bsxfun(@times, merge_pyr{j}, 1./total_w_pyr{j});
end
merge_result = max(min(collapse_laplacian_pyramid(merge_pyr), 1), 0);
end


function bw = find_moon_region(img_v)
img_size = size(img_v);
[centers, radii] = imfindcircles(img_v, [595, 625], ...
    'ObjectPolarity', 'bright', 'Sensitivity', 0.99, 'EdgeThreshold', 0.2);
if ~isempty(radii)
    [xx, yy] = meshgrid(1:img_size(2), 1:img_size(1));
    bw = (xx - centers(1,1)).^2 + (yy - centers(1,2)).^2 < radii(1)^2;
else
    bw = true(img_size);
end
end


function w = gauss_weight_function(x, mu, sig)
% Typical value: mu = 0.52, sig = 0.55
w = exp(-abs((x - mu) ./ sig).^2);
end


function w = gauss_decay_weight_function(x, mu, sig, alpha, beta)
% Typical value: mu = 0.52, sig = 0.55, alpha = 0.014, beta = 0.02
w = exp(-abs((x - mu) ./ sig).^2) .* ...
    exp(alpha ./ (x - 1 - beta) - alpha*.3 ./ (x + beta));
end