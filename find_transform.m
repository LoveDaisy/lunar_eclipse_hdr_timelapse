function tf = find_transform(ref_img, moving_img, varargin)
tf = match_point_feature(ref_img, moving_img, varargin{:});
if isempty(tf) || norm(tf.T - eye(3)) > 10
    tf = match_circle(ref_img, moving_img, varargin{:});
end
if isempty(tf) || norm(tf.T - eye(3)) > 10
    tf = affine2d(eye(3));
end
end


function tf = match_point_feature(ref_img, moving_img, varargin)
p = inputParser();
p.addParameter('ShowMatch', false, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});

gaussian_detail_config = {'KernelSize', 0.0015};
ref_img = get_gaussian_detail(ref_img, gaussian_detail_config{:});
moving_img = get_gaussian_detail(moving_img, gaussian_detail_config{:});

mt = 1500;
pts_0  = detectSURFFeatures(ref_img, 'metricthreshold', mt);
pts_1  = detectSURFFeatures(moving_img, 'metricthreshold', mt);
[features_0,  valid_pts_0]  = extractFeatures(ref_img,  pts_0);
[features_1,  valid_pts_1]  = extractFeatures(moving_img,  pts_1);

% Match base image and m3
idx = matchFeatures(features_0, features_1);
matched_pts_0  = valid_pts_0(idx(:, 1));
matched_pts_1  = valid_pts_1(idx(:, 2));

if length(matched_pts_0) < 10 || length(matched_pts_1) < 10
    tf = [];
    return;
end
[tf, inlier1, inlier0] = estimateGeometricTransform(matched_pts_1, matched_pts_0, 'similarity');
if p.Results.ShowMatch
    showMatchedFeatures(ref_img,  moving_img, inlier0, inlier1);
end
end


function tf = match_circle(ref_img, moving_img, varargin)
p = inputParser();
p.addParameter('ShowMatch', false, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});

ref_img = normalize_image(ref_img);
moving_img = normalize_image(moving_img);

circle_config = {'EdgeThreshold', 0.1, 'Sensitivity', 0.99};
rr = [162, 175];
[center_0, ~] = imfindcircles(ref_img, rr, circle_config{:});
[center_1, ~] = imfindcircles(moving_img, rr, circle_config{:});

if isempty(center_0) || isempty(center_1)
    tf = [];
    return;
end

tf = affine2d([1, 0, 0; 0, 1, 0; center_0 - center_1, 1]);
if p.Results.ShowMatch
    showMatchedFeatures(ref_img,  moving_img, inlier0, inlier1);
end
end
