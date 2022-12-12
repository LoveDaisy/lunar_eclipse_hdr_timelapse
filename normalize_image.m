function img_norm = normalize_image(img, varargin)
p = inputParser;
p.addRequired('img', @(x) length(size(x)) == 2 || length(size(x)) == 3 && size(x, 3) == 3);
p.addParameter('Limit', [0, 100], @(x) length(x) == 2 && all(x <= 100) && all(x >= 0));
p.parse(img, varargin{:});
lim = prctile(img(:), p.Results.Limit);
img_norm = (img - lim(1)) / (lim(2) - lim(1));
end
