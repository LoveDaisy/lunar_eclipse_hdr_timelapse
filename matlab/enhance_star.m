function stars = enhance_star(image_store)
image_flags = find(bitand(cat(1, image_store.type), 2) > 0);
img = im2double(image_store(image_flags(1)).image);
img_v = mean(img, 3);
img_size = size(img_v);

[centers, radii] = imfindcircles(img_v, [595, 625], ...
    'ObjectPolarity', 'bright', 'Sensitivity', 0.99, 'EdgeThreshold', 0.1);
if ~isempty(radii)
    [xx, yy] = meshgrid(1:img_size(2), 1:img_size(1));
    bw = (xx - centers(1,1)).^2 + (yy - centers(1,2)).^2 < radii(1)^2;
    sky_area = ~imdilate(bw, strel('disk', 20, 4));
else
    fprintf('WARNING: no circle detected!\n');
    bw = img_v >= prctile(img_v(:), 93);
    bw = bwareaopen(bw, 100000);
    bw = imdilate(bw, strel('disk', 30, 4));
    sky_area = ~bw;
end

img_log = max(imfilter(img_v, -fspecial('log', 15, 4), 'symmetric'), 0) .* sky_area;
th = sqrt(mean(img_log(img_log > 0).^2)) * 4.2;
star_v = imfilter(double(img_log > th), ...
    fspecial('gaussian', 8, 1.5), 'symmetric') ...
    .* img_log;
stars = bsxfun(@times, img, star_v).^.6;
stars = stars / prctile(stars(stars > 0), 98) * 0.9;
stars(isnan(stars)) = 0;
end