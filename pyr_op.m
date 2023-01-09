function pyr = pyr_op(pyr1, pyr2, op)
% if ~strcmpi(pyr1.type, pyr2.type)
%     error('Pyramid type not match!');
% end
if length(pyr1.img) ~= length(pyr2.img)
    error('Pyramid levels not match!');
end

levels = length(pyr1.img);
pyr.type = pyr1.type;
pyr.img = cell(levels, 1);
for i = 1:levels
    if strcmpi(op, 'add')
        pyr.img{i} = pyr1.img{i} + pyr2.img{i};
    elseif strcmpi(op, 'minus')
        pyr.img{i} = pyr1.img{i} - pyr2.img{i};
    elseif strcmpi(op, 'mul')
        pyr.img{i} = pyr1.img{i} .* pyr2.img{i};
    elseif strcmpi(op, 'div')
        pyr.img{i} = pyr1.img{i} ./ pyr2.img{i};
    end
end
end