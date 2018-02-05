function image_store = choose_valid_image(image_path, files)
total_images = length(files);

exposure_store = zeros(total_images, 2);
for i = 1:total_images
    f_name = sprintf('%s/%s', image_path, files(i).name);
    info = imfinfo(f_name);
    t = info.DigitalCamera.ExposureTime;
    iso = info.DigitalCamera.ISOSpeedRatings;
    tmp = strsplit(files(i).name, '_');
    if strfind(tmp{end}, '+')
        bias = 1;
    elseif strfind(tmp{end}, '-')
        bias = -1;
    else
        bias = 0;
    end
    exposure_store(i, :) = [t * iso, bias];
end

[exposure_store, idx] = sortrows(exposure_store);
files = files(idx);
clear idx;

image_store = struct('image', [], 'exposure', []);
image_valid = false(total_images, 1);
for i = 1:total_images
    fprintf('Reading image %s...\n', files(i).name);
    img = imread(sprintf('%s/%s', image_path, files(i).name));
    max_value = intmax(class(img));
    img_v = mean(img, 3);
    p = prctile(img_v(:), [90, 95, 100]);
    if p(3) < 0.6 * max_value
        fprintf(' Intensity too low\n');
        continue;
    elseif p(1) > 0.22 * max_value
        fprintf(' Intensity too high\n');
        break;
    end
    image_store(i, 1).image = img;
    image_store(i, 1).exposure = exposure_store(i, :);
    image_valid(i, 1) = true;
end
image_store = image_store(image_valid);
end