function [hist_store, valid_flags] = test_valid_image(image_path, files)
total_images = length(files);

expo_comp = [-.7, 0, .7];
x = 94:.1:100;
hist_store = zeros(total_images * 3, length(x));
valid_flags = false(total_images * 3);
for i = 1:total_images
    f_name = files(i).name;
    fprintf('Reading image %s...\n', f_name);
    
    img = imread(sprintf('%s/%s', image_path, f_name));
%     img = srgb_gamma(img);
    max_value = intmax(class(img));
    img_v = mean(img, 3) / double(max_value);
    img_v = imfilter(img_v, fspecial('gaussian', 5, 1.3), 'symmetric');
    img_v = img_v(1:2:end, 1:2:end, :);

    for ei = 1:length(expo_comp)
        img_v_ec = exposure_compensation(img_v, expo_comp(ei));

        y = prctile(img_v_ec(:), x);
        figure(1); clf;
        set(gcf, 'Position', [300, 250, 800, 400]);
        subplot(1,2,1);
        imshow(img_v_ec);
        subplot(1,2,2)
        plot(x, y, [94.5, 94.5], [0, 1], 'k:', [94.3, 94.3], [0, 1], 'k:', ...
            [94,100],[0.5,0.5], 'k:', [94,100],[0.7,0.7], 'k:');
        title(sprintf('EV: %.2f', expo_comp(ei)));
        axis([94, 100, 0, 1]);
        pause;
        key = get(gcf, 'CurrentKey');
        
        hist_store(i, :) = y(:)';

        if strcmpi(key, 'return')
            valid_flags(i) = true;
        end
    end
end
end