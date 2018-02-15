function merge_result = hdr_merge(image_store, trans_mat)
pyr_layers = 5;
pyr_sig = 1.35;
total_images = length(image_store);

if total_images == 1
    fprintf('Merging image 1/1...\n');
    merge_result = im2double(image_store.image);
    return
end

ref_ind = min(3, total_images);
total_w = 0;
for i = 1:total_images
    fprintf('Merging image %d/%d...\n', i, total_images);
    img = im2double(imtranslate(image_store(i).image, -trans_mat(:, i, ref_ind)'));
    img_v = mean(img, 3);
    
    intensity_w = gauss_decay_weight_function(img_v, 0.52, 0.5, 0.014, 0.018);

    w = intensity_w;
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
    
end

total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
for j = 1:length(merge_pyr)
    merge_pyr{j} = bsxfun(@times, merge_pyr{j}, 1./total_w_pyr{j});
end
merge_result = collapse_laplacian_pyramid(merge_pyr);
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