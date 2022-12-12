clear; close all; clc;

tiff_folder = 'developed tiff';
image_list = dir(sprintf('%s/*.tif', tiff_folder));

bracket_num = 7;

exp_group_idx = 176;
exp_group_img = cell(bracket_num, 1);
fprintf('Processing exp group #%d...\n', exp_group_idx)
for i = 1:bracket_num
    fprintf('  Reading image #%d/%d...\n', i, bracket_num)
    img_name = image_list(bracket_num * exp_group_idx + i).name;
    curr_img = im2double(imread(sprintf('%s/%s', tiff_folder, img_name)));
    exp_group_img{i}.original = imresize(curr_img, 0.25);
    exp_group_img{i}.gray = rgb2gray(exp_group_img{i}.original);
end
clear img_name curr_img;
exp_group_img{1}.warp = exp_group_img{1}.original;

%%
for i = 2:bracket_num
    fprintf('  Registering image %d...\n', i);
    tf = find_transform(exp_group_img{1}.gray, exp_group_img{i}.gray);
    output_view = imref2d(size(exp_group_img{1}.original));
    exp_group_img{i}.warp = imwarp(exp_group_img{i}.original, tf, 'OutputView', output_view);
end

avg_img = 0;
for i = 1:bracket_num
    avg_img = avg_img + exp_group_img{i}.warp;
end
avg_img = avg_img / bracket_num;

figure(1); clf;
imshow(avg_img);
