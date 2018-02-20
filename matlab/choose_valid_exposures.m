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

load('svm_model.mat', 'mdl*');

x_highlight = 94:.1:100;
x_median = 47:.1:53;
image_info = struct('name', [], 'ev', [], 'type', []);
flags = false(total_images, 1);
scores = nan(total_images, 3);
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
    
    [~, s0] = predict(mdl0, [y, exposure_store(i)]);
    [~, s1] = predict(mdl1, [y, exposure_store(i)]);
    [~, s2] = predict(mdl2, [y, exposure_store(i)]);
    [~, lbl] = max([s0(:,2), s1(:,2), s2(:,2)], [], 2);
    lbl = lbl - 1;
    scores(i, :) = 1./(1 + exp(-[s0(:,2), s1(:,2), s2(:,2)]));
    
    fprintf('lbl: %d, score: %.4f\n', lbl, scores(i, lbl+1));

    image_info(i).name = f_name;
    image_info(i).expo = exposure_store(i);
    image_info(i).ev = 0;
    image_info(i).type = lbl;
    flags(i) = (lbl ~= 0);
    if lbl == 1
        fprintf('main frame\n');
    elseif lbl == 2
        fprintf('star frame\n');
        break;
    else
        fprintf('unsuitable expo\n');
    end
end
[~, idx] = nanmax(scores(:, 2));
flags(idx) = true;
image_info(idx).type = 1;

if all(cat(1, image_info.type) ~= 2)
    flags(total_images) = true;
    image_info(total_images).type = 2;
end
image_info = image_info(flags);
end