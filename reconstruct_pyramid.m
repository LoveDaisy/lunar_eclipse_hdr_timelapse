function img = reconstruct_pyramid(pyr)
if strcmpi(pyr.type, 'gaussian')
    img = pyr.img{1};
else
    levels = length(pyr.img);
    img = pyr.img{levels};
    for i = levels-1:-1:1
        img_size = size(pyr.img{i});
        img = imresize(img, img_size(1:2));
        img = img + pyr.img{i};
    end
end
end
