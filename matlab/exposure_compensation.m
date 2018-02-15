function img = exposure_compensation(img, ev)
% INPUT
%	img:		m * n double array.

if abs(ev) < 0.05
    return
end

a1 = 0.15;
a2 = 1.5;
a3 = -1.0;

% Original algorithm could be expressed as follows:
%   ev0 = a3 * log(exp(log(img).*(-a2)) - (1-a1^2));
%   img = exp(log(exp((ev0 + ev) / a3) + (1-a1^2)).*(-1/a2));

% And rewrite like this can speed up:
img = exp(-log((1-a1^2) + exp(ev/a3) * (a1^2-1) + exp(ev/a3+log(img).*(-a2)))./a2);
end