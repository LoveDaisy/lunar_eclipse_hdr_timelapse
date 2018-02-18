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

% expo_comp = [-.7, 0, .7];
expo_comp = 0;
x = 94:.1:100;
image_info = struct('name', [], 'ev', []);
flags = false(total_images, 1);
scores = nan(total_images, length(expo_comp));
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

    valid_expo_comp = nan(length(expo_comp), 1);
    over_expo = false;
    for ei = 1:length(expo_comp)
        img_v_ec = exposure_compensation(img_v, expo_comp(ei));

        y = prctile(img_v_ec(:), x);
        
        s = [y - hist_store_mean, log2(t*iso)+expo_comp(ei)-exp_mean] * coeff;
        [~, p] = predict(mdl, s(1:10));
        p = 1./(1 + exp(p(1)));
        scores(i, ei) = p;
        
        fprintf('p: %.4f\n', p);
        if p(1) < 0.45
            if y(1) > 0.6
                fprintf('over expo\n');
                over_expo = true;
                break;
            else
                fprintf('unsuitable expo\n');
                continue;
            end
        end

        valid_expo_comp(ei) = expo_comp(ei);
    end
    image_info(i).name = f_name;
    image_info(i).expo = exposure_store(i);
    if sum(~isnan(valid_expo_comp)) > 0
        image_info(i).ev = valid_expo_comp(~isnan(valid_expo_comp));
        flags(i) = true;
    end
    if over_expo
        break;
    end
end
if all(~flags)
    [~, idx] = nanmax(nanmax(scores, [], 2));
    flags(idx) = true;
    [~, evidx] = nanmax(scores(idx, :));
    image_info(idx).ev = expo_comp(evidx);
end
image_info = image_info(flags);
end