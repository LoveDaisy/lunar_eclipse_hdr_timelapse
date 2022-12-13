clear; close all; clc;

tiff_folder = 'developed tiff';
image_list = dir(sprintf('%s/*.tif', tiff_folder));

bracket_num = 7;

exp_group_idx = 0;
while true
    % Read exposure bracket images
    if bracket_num * exp_group_idx + i > length(image_list)
        break;
    end
    exp_group_img = cell(bracket_num, 1);
    hist_edges = linspace(0, 1, 101);
    fprintf('Processing exp group #%d...\n', exp_group_idx)
    for i = 1:bracket_num
        fprintf('  Reading image #%d/%d...\n', i, bracket_num)
        img_name = image_list(bracket_num * exp_group_idx + i).name;
        curr_img = im2double(imread(sprintf('%s/%s', tiff_folder, img_name)));
        exp_group_img{i}.original = imresize(curr_img, 0.25);
        exp_group_img{i}.gray = rgb2gray(exp_group_img{i}.original);
        exp_group_img{i}.hist = histcounts(exp_group_img{i}.gray(:), hist_edges);
    end
    clear img_name curr_img;

    % Find best exposure for reference
    over_exp = false(bracket_num, 1);
    over_exp_mask = cell(bracket_num, 1);
    for i = 1:bracket_num
        curr_gray = exp_group_img{i}.gray;
        [grad, ~] = imgradient(curr_gray, 'prewitt');
        curr_mask = grad < 0.008 & curr_gray > 0.7;
        curr_mask = bwareaopen(curr_mask, 50);
        if sum(curr_mask(:)) / numel(curr_gray) > 2e-4
            over_exp(i) = true;
        end
        over_exp_mask{i} = curr_mask;
    end
    if all(over_exp)
        ref_idx = 2;
    else
        for i = [7, 6, 5, 1, 4, 3, 2]
            if ~over_exp(i)
                ref_idx = i;
                break;
            end
        end
    end

    % Register images and warp images to reference
    for i = 1:bracket_num
        if i == ref_idx
            exp_group_img{i}.warp = exp_group_img{i}.original;
            continue;
        end
        fprintf('  Registering image %d to %d...\n', i, ref_idx);
        tf = find_transform(exp_group_img{ref_idx}.gray, exp_group_img{i}.gray);
        output_view = imref2d(size(exp_group_img{ref_idx}.original));
        exp_group_img{i}.warp = imwarp(exp_group_img{i}.original, tf, 'OutputView', output_view);
    end

    % Weighted merge
    ref_w = rgb2gray(exp_group_img{ref_idx}.warp);
    ref_w = (ref_w - 0.5) * 0.8 + 0.6;
    ref_w = imguidedfilter(ref_w, ref_w, 'NeighborhoodSize', [1, 1] * 100, 'DegreeOfSmoothing', 0.1);

    avg_img = 0;
    total_w = 0;
    for i = 1:bracket_num
        w = rgb2gray(exp_group_img{i}.warp);
        if over_exp(i)
            w_valid = ~over_exp_mask{i};
        else
            w_valid = true(size(w));
        end
        w = exp(-abs(w - ref_w).^2 / 0.25^2) .* w_valid;
        w = imguidedfilter(w, w, 'NeighborhoodSize', [1, 1] * 100, 'DegreeOfSmoothing', 0.05);
        avg_img = avg_img + exp_group_img{i}.warp .* w;
        total_w = total_w + w;
    end
    avg_img = avg_img ./ total_w;

    % Display and save
    figure(10); clf;
    imshow(avg_img);
    drawnow;
    exp_group_idx = exp_group_idx + 1;
    imwrite(uint8(avg_img * 256), sprintf('final tiff/%04d.tiff', exp_group_idx));
end