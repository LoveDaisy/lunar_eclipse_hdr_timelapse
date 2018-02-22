function [theta_store, t_store] = refine_transform(theta_store, t_store, feature_store)
% This function refines the transformation between images
total_images = length(feature_store);

cum_theta = zeros(total_images, 1);
cum_trans = zeros(total_images, 2);
for i = 2:total_images
    cum_theta(i) = cum_theta(i-1) + theta_store(i, i-1);
    cum_trans(i, :) = cum_trans(i-1, :) + t_store(:, i, i-1)';
end

for i = 1:total_images
    pts1 = feature_store{i}.pts;
    for j = i+2:total_images
        fprintf('Optimizing (%d,%d)...\n', j, i);
        pts2 = feature_store{j}.pts;
        theta = cum_theta(j) - cum_theta(i);
        t = cum_trans(j, :) - cum_trans(i, :);
        
        pts1_ = transform(pts2, theta, t);
        dist_mat = pdist2(pts1, pts1_);
        matched_idx = find_matched_pair(dist_mat);

        if size(matched_idx, 1) < 10
            break;
        end

        [theta, t, fval] = solve_transform(pts1, pts2, matched_idx, theta, t);
        fprintf('matched points: %d, error: %.4f\n', size(matched_idx, 1), fval);

        theta_store(j, i) = theta;
        theta_store(i, j) = -theta;
        t_store(:, j, i) = t';
        t_store(:, i, j) = -t';
    end
end

is_full = false;
while ~is_full
    is_full = true;
    for i = 1:total_images
        max_i = i;
        for j = i+1:total_images
            if any(abs([t_store(:, j, i); theta_store(j, i)]) > 1e-6)
                max_i = j;
                continue;
            end
        end
        if max_i < total_images
            is_full = false;
        end
        if max_i == total_images
            continue;
        end

        max_j = max_i;
        for j = max_i+1:total_images
            if any(abs([t_store(:, j, max_i); theta_store(j, max_i)]) > 1e-6)
                max_j = j;
                continue;
            end
        end

        for j = max_i+1:max_j
            theta_store(j, i) = theta_store(j, max_i) + theta_store(max_i, i);
            theta_store(i, j) = -theta_store(j, i);
            t_store(:, j, i) = t_store(:, j, max_i) + t_store(:, max_i, i);
            t_store(:, i, j) = -t_store(:, j, i);
        end
        
        figure(1); clf;
        imagesc(theta_store);
        axis equal; axis tight;
    end
end
end


function [theta, t, fval] = solve_transform(pts1, pts2, matched_idx, theta, t)
% obj = @(x)obj_fun(pts2(matched_idx(:,2),:), pts1(matched_idx(:,1),:), x(1), x(2:3));
% options = optimset('disp', 'off');
% [x, fval] = fminsearch(obj, [theta, t], options);
% theta = x(1);
% t = x(2:3);
p2 = pts1(matched_idx(:,1), :);
p1 = pts2(matched_idx(:,2), :);

x1 = mean(p1(:,1)); y1 = mean(p1(:,2));
x2 = mean(p2(:,1)); y2 = mean(p2(:,2));

x1x2 = mean(p1(:,1) .* p2(:,1));
y1y2 = mean(p1(:,2) .* p2(:,2));
x1y2 = mean(p1(:,1) .* p2(:,2));
x2y1 = mean(p2(:,1) .* p1(:,2));
x1_y2 = x1 * y2;
x2_y1 = x2 * y1;
x1_x2 = x1 * x2;
y1_y2 = y1 * y2;

s1 = (x1y2 - x2y1 + x2_y1 - x1_y2) / sqrt(x1x2^2 + x1y2^2 - 2*x1_x2*x1x2 + x1^2*x2^2 - ...
    2*x1y2*x2y1 + x2y1^2 + 2*x1y2*x2_y1 - 2*x2y1*x2_y1 + x2^2*y1^2 + 2*x1x2*y1y2 - ...
    2*x1_x2*y1y2 +y1y2^2 - 2*x1y2*x1_y2 + 2*x2y1*x1_y2 - 2*x1x2*y1_y2 - 2*y1y2*y1_y2 + ...
    x1^2*y2^2 + y1^2*y2^2);
s2 = -s1;
theta1 = asin(s1);
theta2 = asin(s2);
c = sqrt(1 - s1^2);
t1 = [x2 - x1*c + y1*s1, y2 - x1*s1 - y1*c];
t2 = [x2 - x1*c + y1*s2, y2 - x1*s2 - y1*c];

f1 = obj_fun(p1, p2, theta1, t1);
f2 = obj_fun(p1, p2, theta2, t2);

if f1 < f2
    theta = theta1;
    t = t1;
else
    theta = theta2;
    t = t2;
end
fval = min(f1, f2);
end


function pts = transform(pts, theta, t)
matRt = [cos(theta), sin(theta); -sin(theta), cos(theta)];
pts = bsxfun(@plus, pts * matRt, t);
end


function matched_idx = find_matched_pair(dist_mat)
[min_d, row_idx] = min(dist_mat, [], 2);
[~, col_idx] = min(dist_mat);
idx = (col_idx(row_idx) == 1:length(row_idx))' & min_d < 3;
matched_idx = [find(idx), row_idx(idx)];
end


function f = obj_fun(pts1, pts2, theta, t)
d = sqrt(sum(bsxfun(@minus, transform(pts1, theta, t), pts2).^2, 2));
f = mean(hubber(d, 1.2));
end


function y = hubber(x, a)
% y = x^2,          for abs(x) <= a
% y = 2*a*x - a^2,  for abs(x) > a
y = x.^2;
y(abs(x) > a) = 2*a*abs(x(abs(x) > a)) - a^2;
end