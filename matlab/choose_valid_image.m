function image_store = choose_valid_image(image_path, files)
total_images = length(files);

exposure_store = zeros(total_images, 2);
for i = 1:total_images
    f_name = sprintf('%s/%s', image_path, files(i).name);
    info = imfinfo(f_name);
    if length(info) > 1
        info = info(1);
    end
    t = info.DigitalCamera.ExposureTime;
    iso = info.DigitalCamera.ISOSpeedRatings;
    exposure_store(i, :) = [t * iso, 0];
end

[exposure_store, idx] = sortrows(exposure_store);
files = files(idx);
clear idx;

load('pca_logit_data.mat', 'hist_store_mean', 'B', 'coeff');

% expo_comp = [-0.67, 0, 0.67];
expo_comp = [-.7, 0, .7];
x = 94:.1:100;
image_store = struct('image', [], 'exposure', []);
image_valid = false(total_images * 3, 1);
for i = 1:total_images
    f_name = files(i).name;
    fprintf('Reading image %s...\n', f_name);
    
    img = imread(sprintf('%s/%s', image_path, f_name));
%     img = srgb_gamma(img);
    max_value = intmax(class(img));
    img_v = mean(img, 3) / double(max_value);
    img_v = imfilter(img_v, fspecial('gaussian', 5, 1.3), 'symmetric');
    img_v = img_v(1:2:end, 1:2:end, :);

    valid_expo_comp = nan(3, 1);
    over_expo = false;
    for ei = 1:length(expo_comp)
        img_v_ec = exposure_compensation(img_v, expo_comp(ei));

        y = prctile(img_v_ec(:), x);
        
        s = (y - hist_store_mean) * coeff;
        p = 1/(1 + exp(s(1:length(B)-1)*B(2:length(B))+B(1)));
        
        fprintf('p: %.4f\n', p);
        if p < 0.6
            if y(1) > 0.6
                fprintf(' Intensity too high\n');
                over_expo = true;
                break;
            else
                fprintf(' Intensity too low\n');
                continue;
            end
        end
        
%         p = prctile(img_v_ec(:), [95.1, 98, 100]);
%         p = srgb_gamma(p);
%         fprintf(' Intensity percentile: [%.2f,%.2f,%.2f]\n', p(1), p(2), p(3));
%         if p(3) < 0.80
%             fprintf(' Intensity too low\n');
%             continue;
%         elseif p(1) > 0.9
%             fprintf(' Intensity too high\n');
%             over_expo = true;
%             break;
%         end

        valid_expo_comp(ei) = expo_comp(ei);
    end

    if any(~isnan(valid_expo_comp))
        [~, f_name, f_ext] = fileparts(f_name);
        if ~strcmpi(f_ext, '.tif') && ~strcmpi(f_ext, '.tiff')
            fprintf('No TIFF file, converting RAW to TIFF...\n');
            system(sprintf('dcraw -v -r 1.95 1.0 1.63 1.0 -k 2047 -S 15490 -g 2.4 12.92 -4 -T -q 2 "%s%s%s"', image_path, f_name, f_ext));
            fprintf('Reading TIFF file %s...\n', f_name);
            img = imread(sprintf('%s%s%s', image_path, f_name, '.tiff'));
%             img = srgb_gamma(img);
            fprintf('Removing temp TIFF file...\n');
            system(sprintf('rm "%s%s%s"', image_path, f_name, '.tiff'));
        end
            

        img_double = im2double(img);
        for ei = 1:length(expo_comp)
            if isnan(valid_expo_comp(ei))
                continue;
            end
            fprintf(' Exposure conpensation: %.2f\n', expo_comp(ei));
            current_img = srgb_gamma(exposure_compensation(img_double, expo_comp(ei)));
            switch class(img)
                case 'uint8'
                    current_img = uint8(current_img * 255);
                case 'uint16'
                    current_img = uint16(current_img * 65535);    
            end
            image_store((i-1)*3+ei, 1).image = current_img;
            image_store((i-1)*3+ei, 1).exposure = exposure_store(i, :) +[0, expo_comp(ei)];
            image_valid((i-1)*3+ei, 1) = true;
        end
    end
    if over_expo
        break;
    end
end
image_store = image_store(image_valid);
end