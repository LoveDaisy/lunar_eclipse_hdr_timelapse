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
total_w = 0; merge_img = 0;
for i = 1:total_images
    fprintf('Merging image %d/%d...\n', i, total_images);
    img = im2double(imtranslate(image_store(i).image, -trans_mat(:, i, ref_ind)'));
    img_v = mean(img, 3);
    
%     intensity_w = exp(-abs((img_v - 0.52) / 0.55).^2) .* ...
%         exp(.014 ./ (img_v - 1 - 0.02) - .014 ./ (img_v + 0.02));
    intensity_w = exp(-abs((img_v - 0.52) / 0.5).^2);
    w = intensity_w;
    total_w = total_w + w;
    
%     img_pyr = generate_laplacian_pyramid(img, pyr_layers, pyr_sig);
%     w_pyr = generate_gaussian_pyramid(w, pyr_layers, pyr_sig);
%     for j = 1:length(img_pyr)
%         img_pyr{j} = bsxfun(@times, img_pyr{j}, w_pyr{j});
%     end
%     
%     if ~exist('merge_pyr', 'var')
%         merge_pyr = img_pyr;
%     else
%         for j = 1:length(merge_pyr)
%             merge_pyr{j} = merge_pyr{j} + img_pyr{j};
%         end
%     end

    merge_img = merge_img + bsxfun(@times, img, intensity_w);
    
%     total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
%     tmp_pyr = merge_pyr;
%     for j = 1:length(merge_pyr)
%         tmp_pyr{j} = bsxfun(@times, merge_pyr{j}, 1./total_w_pyr{j});
%     end
%     tmp_result = collapse_laplacian_pyramid(tmp_pyr);
%     figure(1); clf;
%     set(gcf, 'Position', [100, 200, 1200, 600]);
%     subplot(1,3,1);
%     imshow(tmp_result);
%     subplot(1,3,2);
%     imshow(img);
%     subplot(1,3,3);
%     imagesc(w);
%     colormap gray;
%     axis equal; axis tight; axis off;
%     drawnow;
end

% total_w_pyr = generate_gaussian_pyramid(total_w, pyr_layers, pyr_sig);
% for j = 1:length(merge_pyr)
%     merge_pyr{j} = bsxfun(@times, merge_pyr{j}, 1./total_w_pyr{j});
% end
% merge_result = collapse_laplacian_pyramid(merge_pyr);
merge_result = bsxfun(@times, merge_img, 1./total_w);
end