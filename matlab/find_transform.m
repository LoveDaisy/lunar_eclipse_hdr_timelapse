function [theta, t] = find_transform(pts1, pts2, pair_idx)
% This function finds transform from pts1 to pts2
%   pts1 * matR' + t = pts2

matched_pts = 0;
while matched_pts < 0.3 * size(pair_idx, 1)
    idx = pair_idx(randsample(size(pair_idx, 1), 1), :);
    t = pts2(idx(2), :) - pts1(idx(1), :);

    dist_mat = pdist2(bsxfun(@plus, pts1, t), pts2);
    matched_idx = find_matched_pair(dist_mat);
    matched_pts = size(matched_idx, 1);
end
fprintf('Find matched points: %d\n', matched_pts);
obj = @(x)obj_fun(pts1(matched_idx(:,1), :), pts2(matched_idx(:,2), :), x(1), x(2:end));
options = optimset('disp', 'off');
[x, fval] = fminsearch(obj, [0, t], options);
fprintf('theta: %.3e, t: [%.3f, %.3f]\nMean error: %.3f pixel\n', x(1), x(2), x(3), fval);

theta = x(1);
t = x(2:end);
end


function matched_idx = find_matched_pair(dist_mat)
[min_d, row_idx] = min(dist_mat, [], 2);
[~, col_idx] = min(dist_mat);
idx = (col_idx(row_idx) == 1:length(row_idx))' & min_d < 3;
matched_idx = [find(idx), row_idx(idx)];
end


function f = obj_fun(pts1, pts2, theta, t)
matRt = [cos(theta), sin(theta); -sin(theta), cos(theta)];
d = sqrt(sum((bsxfun(@plus, pts1 * matRt, t) - pts2).^2, 2));
f = mean(hubber(d, 1));
end


function y = hubber(x, a)
% y = x^2,          for abs(x) <= a
% y = 2*a*x - a^2,  for abs(x) > a
y = x.^2;
y(abs(x) > a) = 2*a*abs(x(abs(x) > a)) - a^2;
end