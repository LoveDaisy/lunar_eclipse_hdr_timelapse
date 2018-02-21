function image_info = choose_valid_exposures(image_path, files)
% This function choose valide exposures to composite an HDR image
total_images = length(files);

exposure_store = zeros(total_images, 1);
for i = 1:total_images
    f_name = sprintf('%s/%s', image_path, files(i).name);
    info = imfinfo(f_name);
    if length(info) > 1
        info = info(1);
    end
    t = info.DigitalCamera.ExposureTime;
    iso = info.DigitalCamera.ISOSpeedRatings;
    exposure_store(i, :) = log2(t * iso);
end

[exposure_store, idx] = sortrows(exposure_store, 'descend');
files = files(idx);
clear idx;

load('svm_model.mat', 'mdl1', 'hist_store_mean', 'exp_store_mean', 'coeff');

x_highlight = 94:.1:100;
x_median = 50;
image_info = struct('name', [], 'ev', [], 'type', []);
flags = false(total_images, 1);
scores = nan(total_images, 1);
for i = 1:total_images
    f_name = files(i).name;
    fprintf('Reading image %s...\n', f_name);
    
    img = imread(sprintf('%s/%s', image_path, f_name));
    max_value = intmax(class(img));
    img_v = mean(img, 3) / double(max_value);
    img_v = imfilter(img_v, fspecial('gaussian', 5, 1.3), 'symmetric');
    img_v = img_v(1:2:end, 1:2:end, :);
    
%     info = imfinfo(sprintf('%s/%s', image_path, f_name));
%     t = info(1).DigitalCamera.ExposureTime;
%     iso = info(1).DigitalCamera.ISOSpeedRatings;

    img_v_ec = exposure_compensation(img_v, 0);

    y = prctile(img_v_ec(:), [x_median, x_highlight]);
    y_highlight = y(2:end); y_median = y(1);
    sample_score = [y_highlight-hist_store_mean, exposure_store(i)-exp_store_mean] * coeff;
    
    [lbl, s1] = predict(mdl1, sample_score(1:6));
    scores(i) = 1./(1 + exp(-s1(2)));
    
    fprintf('lbl: %d, score: %.4f\n', lbl, scores(i));

    image_info(i).name = f_name;
    image_info(i).expo = exposure_store(i);
    image_info(i).ev = 0;
    image_info(i).type = 0;
%     image_info(i).type = lbl;
%     flags(i) = (lbl ~= 0);
    if y_median < 0.8 && all(bitand(cat(1, image_info.type), 2) == 0)
        fprintf('star frame\n');
        image_info(i).type = 2;
        flags(i) = true;
    end
    
    if lbl > 1
        fprintf('main frame\n');
        image_info(i).type = bitor(image_info(i).type, 1);
        flags(i) = true;
%         break;
    elseif image_info(i).type == 0
        fprintf('unsuitable expo\n');
    end
end

[~, idx] = nanmax(scores);
flags(idx) = true;
image_info(idx).type = 1;

if all(cat(1, image_info.type) ~= 2)
    flags(total_images) = true;
    image_info(total_images).type = 2;
end
image_info = image_info(flags);
end