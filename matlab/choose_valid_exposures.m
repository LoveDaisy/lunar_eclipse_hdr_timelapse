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
    exposure_store(i, :) = t * iso;
end

[exposure_store, idx] = sortrows(exposure_store);
files = files(idx);
clear idx;

load('svm_model.mat', 'mdl', 'hist_store_mean', 'exp_mean', 'coeff');

x = 94:.1:100;
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
    
    info = imfinfo(sprintf('%s/%s', image_path, f_name));
    t = info(1).DigitalCamera.ExposureTime;
    iso = info(1).DigitalCamera.ISOSpeedRatings;


    img_v_ec = exposure_compensation(img_v, 0);

    y = prctile(img_v_ec(:), [50, x]);
    img_v_med = y(1); y = y(2:end);
    
    s = [y - hist_store_mean, log2(t*iso)-exp_mean] * coeff;
    [~, p] = predict(mdl, s(1:10));
    p = 1./(1 + exp(p(1)));
    scores(i) = p;
    
    fprintf('p: %.4f\n', p);

    image_info(i).name = f_name;
    image_info(i).expo = exposure_store(i);
    image_info(i).ev = 0;
    if p(1) > 0.45
        flags(i) = true;
        image_info(i).type = 1;
    elseif img_v_med > 0.8
        fprintf('star expo\n');
        image_info(i-1).type = 2;
        flags(i-1) = true;
        break;
    else
        image_info(i).type = 0;
        fprintf('unsuitable expo\n');
    end
end
if all(~flags)
    [~, idx] = nanmax(scores);
    flags(idx) = true;
end
if img_v_med < 0.8
    flags(total_images) = true;
    image_info(total_images).type = 2;
end
image_info = image_info(flags);
end