function [hist_store, exp_store, valid_flags] = test_valid_image(image_path, files)
total_images = length(files);

% load('pca_logit_data.mat', 'hist_store_mean', 'B', 'coeff');
load('svm_model.mat', 'mdl', 'hist_store_mean', 'exp_mean', 'coeff');

expo_comp = [-.7, 0, .7];
x = 94:.1:100;
hist_store = zeros(total_images * 3, length(x));
exp_store = zeros(total_images * 3, 1);
valid_flags = false(total_images * 3, 1);
for i = 1:total_images
    f_name = files(i).name;
    fprintf('Reading image %s...\n', f_name);
    
    img = imread(sprintf('%s/%s', image_path, f_name));
%     img = srgb_gamma(img);
    max_value = intmax(class(img));
    img_v = mean(img, 3) / double(max_value);
    img_v = imfilter(img_v, fspecial('gaussian', 5, 1.3), 'symmetric');
    img_v = img_v(1:2:end, 1:2:end, :);
    
    info = imfinfo(sprintf('%s/%s', image_path, f_name));
    t = info(1).DigitalCamera.ExposureTime;
    iso = info(1).DigitalCamera.ISOSpeedRatings;

    for ei = 1:length(expo_comp)
        img_v_ec = exposure_compensation(img_v, expo_comp(ei));

        y = prctile(img_v_ec(:), x);
        
        s = [y - hist_store_mean, log2(t*iso)+expo_comp(ei)-exp_mean] * coeff;
        [~, p] = predict(mdl, s(1:10));
        
        figure(1); clf;
        set(gcf, 'Position', [300, 250, 800, 400]);
        subplot(1,2,1);
        imshow(img_v_ec);
        title(sprintf('p: %.4f', 1./(1+exp(p(1)))));
        subplot(1,2,2)
        plot(x, y, [94.5, 94.5], [0, 1], 'k:', [94.3, 94.3], [0, 1], 'k:', ...
            [94,100],[0.5,0.5], 'k:', [94,100],[0.7,0.7], 'k:');
        title(sprintf('EV: %.2f', expo_comp(ei)));
        axis([94, 100, 0, 1]);
%         drawnow;
%         pause(.2);
        pause;
        key = get(gcf, 'CurrentKey');
        
        hist_store(3*(i-1)+ei, :) = y(:)';
        exp_store(3*(i-1)+ei) = log2(t*iso)+expo_comp(ei);

        if strcmpi(key, 'return')
            valid_flags(3*(i-1)+ei) = true;
        elseif strcmpi(key, 'q')
            break;
        elseif strcmpi(key, 'a')
            valid_flags(3*(i-1)+ei:3*i) = true;
            break;
        end
    end
end
end