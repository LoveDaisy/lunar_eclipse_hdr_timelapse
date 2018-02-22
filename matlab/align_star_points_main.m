clear; close all; clc;

input_image_path = '/Volumes/ZJJ-4TB/Photos/18.01.31 Lunar Eclipse by Wang Letian/timelapse/aligned/';
files = dir([input_image_path, '*.tiff']);
total_images = length(files);

theta_store = zeros(total_images);
t_store = zeros(2, total_images, total_images);
feature_store = cell(total_images, 1);
img = [];
feature = [];
for i = 1:total_images
    img_last = img;
    fprintf('Reading image %s...\n', files(i).name);
    img = im2double(imread([input_image_path, files(i).name]));
    img_v = mean(img, 3);

    feature_last = feature;
    feature = extract_star_feature(img_v);
    feature_store{i} = feature;

    if isempty(feature_last)
        continue;
    end

    if min(size(feature.pts, 1), size(feature_last.pts, 1)) < 100
        dist_mat = pdist2(feature.pts, feature_last.pts);
        [~, idx_row] = min(dist_mat, [], 2);
        [~, idx_col] = min(dist_mat);
        idx = (idx_col(idx_row) == 1:length(idx_row))';
        pair_idx = [find(idx), idx_row(idx)];
        clear idx idx_row idx_col;
    else
        pair_idx = find_initial_match(feature, feature_last);
    end

    [theta, t] = find_transform(feature.pts, feature_last.pts, pair_idx);
    theta_store(i, i-1) = theta;
    theta_store(i-1, i) = -theta;
    t_store(:, i, i-1) = t';
    t_store(:, i-1, i) = -t';
end

img_size = size(img);
save tf.mat t_store theta_store feature_store img_size;

[theta_store, t_store] = refine_transform(theta_store, t_store, feature_store);

save tf.mat t_store theta_store feature_store img_size;

%%
load tf.mat;
max_trans = max(t_store(:,:,1), [], 2)';
min_trans = min(t_store(:,:,1), [], 2)';
final_image = uint16(zeros([wrev(ceil(max_trans - min_trans)+1)+img_size(1:2), 3]));
for i = 1:4:total_images
    img = imread([input_image_path, files(i).name]);
    im_ref = imref2d(img_size(1:2));
    q = theta_store(i, 1);
    img = imwarp(img, affine2d([cos(q), sin(q), 0; -sin(q), cos(q), 0; 0, 0, 1]), ...
        'OutputView', im_ref);
    offset = floor(t_store(:, i, 1)' - min_trans);
    crop_part = final_image(offset(2)+1:offset(2)+size(img,1), offset(1)+1:offset(1)+size(img,2),:);
    final_image(offset(2)+1:offset(2)+size(img,1), offset(1)+1:offset(1)+size(img,2), :) = ...
        max(crop_part, img);
    
    figure(1); clf;
    imshow(final_image);
    drawnow;
end

%%
% figure(1); clf;
% imshow(img);
% hold on;
% plot(feature.pts(:, 1), feature.pts(:, 2), 'ro', ...
%     feature_last.pts(:, 1), feature_last.pts(:, 2), 'yx');
% 
% figure(2); clf;
% imshow(img);
% hold on;
% plot(feature.pts(pair_idx(:,1), 1), feature.pts(pair_idx(:,1), 2), 'ro', ...
%     feature_last.pts(pair_idx(:,2), 1), feature_last.pts(pair_idx(:,2), 2), 'yx');
% for ii = 1:size(pair_idx, 1)
%     plot([feature.pts(pair_idx(ii,1),1),feature_last.pts(pair_idx(ii,2),1)], ...
%         [feature.pts(pair_idx(ii,1),2),feature_last.pts(pair_idx(ii,2),2)], 'm');
% end
