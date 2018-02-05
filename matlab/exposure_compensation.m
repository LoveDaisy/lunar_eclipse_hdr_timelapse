function img = exposure_compensation(img, ev)
% INPUT
%	img:		m * n double array.

a1 = 0.15;
a2 = 1.5;
a3 = -1.0;

idx = img < 0.005;
low_values = img(idx);

ev0 = a3 * log(img.^(-a2) - (1-a1^2));
img = exp((ev0 + ev) / a3) + (1-a1^2);

img(idx) = low_values;
end