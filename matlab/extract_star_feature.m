function feature = extract_star_feature(img_v)
fprintf('Finding moon area...\n');
% [centers, radii] = imfindcircles(img_v, [595, 625], ...
%     'ObjectPolarity', 'bright', 'Sensitivity', 0.99, 'EdgeThreshold', 0.1);
% if isempty(radii)
%     error('No circle detected!');
% end
% [xx, yy] = meshgrid(1:size(img_v, 2), 1:size(img_v, 1));
% moon_area = (xx - centers(1,1)).^2 + (yy - centers(1,2)).^2 < radii(1)^2;
% moon_area = imdilate(moon_area, strel('disk', 10, 4));
moon_area = img_v >= prctile(img_v(:), 93);
moon_area = bwareaopen(moon_area, 100000);
moon_area = imdilate(moon_area, strel('disk', 20, 4));

img_log = max(imfilter(img_v, -fspecial('log', 10, 2.2), 'symmetric'), 0);
% th = sqrt(mean(img_log(~moon_area).^2)) * 100;
th = 0.035;
bw = (img_log .* ~moon_area) > th;

stats = regionprops(bw, img_log, 'WeightedCentroid', 'MeanIntensity', 'Area');
vol = cat(1, stats.MeanIntensity) .* cat(1, stats.Area);
% vol = ones(length(stats), 1);
pts = cat(1, stats.WeightedCentroid);
sph = convert_coord_img_sph(pts, size(img_v), 820);

fprintf('Extracting feature of each star point...\n');
pf = extract_point_features(sph, vol, 15, 'polarspec');
feature = struct('polar_feature', pf, 'pts', pts, 'sph', sph);
end