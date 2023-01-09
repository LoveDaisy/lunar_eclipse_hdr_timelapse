function pyr = make_pyramid(img, varargin)
dims = size(img);
p = inputParser();
p.addRequired('img', @(x) isnumeric(x) && (length(dims) == 2 || length(dims) == 3 && dims(3) == 3));
p.addParameter('Levels', 5, @(x) isscalar(x));
p.addParameter('Type', 'gaussian', @(x) ischar(x) && (strcmpi(x, 'gaussian') || strcmpi(x, 'laplacian')));
p.parse(img, varargin{:});

pyr = make_gaussian_pyr(img, p.Results.Levels);
if strcmpi(p.Results.Type, 'laplacian')
    pyr = make_laplacian_pyr(pyr);
end
end

function pyr = make_gaussian_pyr(img, levels)
pyr.type = 'Gaussian';
pyr.img = cell(levels, 1);
pyr.img{1} = img;
for i = 2:levels
    img = pyr.img{i-1};
    img = imgaussfilt(img, 1.5);
    img = imresize(img, 0.5);
    pyr.img{i} = img;
end
end

function pyr = make_laplacian_pyr(pyr)
pyr.type = 'Laplacian';
levels = length(pyr.img);
for i = 1:levels-1
    img_size = size(pyr.img{i});
    pyr.img{i} = pyr.img{i} - imresize(pyr.img{i+1}, img_size(1:2));
end
end
