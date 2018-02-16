function image_store = read_exposures(input_image_path, image_info)
% This function reads valide exposures

total_files = length(image_info);
file_store = cell(total_files, 1);
image_store = struct('image', [], 'ev', []);
flags = false(total_files * 3);
parfor i = 1:total_files
    [~, f_name, f_ext] = fileparts(image_info(i).name);
    if ~exist([input_image_path, f_name, '.ppm'], 'file')
        fprintf('No image file, converting RAW to image...\n');
        system(sprintf('dcraw -v -r 1.95 1.0 1.63 1.0 -k 2047 -S 15490 -g 2.4 12.92 -4 -q 2 "%s%s%s"', input_image_path, f_name, f_ext));
    end
    fprintf('Reading image file %s...\n', f_name);
    img = imread(sprintf('%s%s%s', input_image_path, f_name, '.ppm'));
    fprintf('Removing temp image file...\n');
    system(sprintf('rm "%s%s%s"', input_image_path, f_name, '.ppm'));
    file_store{i} = img;
end

for i = 1:total_files
    img_double = im2double(file_store{i});
    for ei = 1:length(image_info(i).ev)
        current_ev = image_info(i).ev(ei);
        fprintf(' Exposure conpensation: %.2f\n', current_ev);
        current_img = srgb_gamma(exposure_compensation(img_double, current_ev));
        switch class(file_store{i})
            case 'uint8'
                current_img = uint8(current_img * 255);
            case 'uint16'
                current_img = uint16(current_img * 65535);    
        end
        k = (i-1)*3 + ei;
        image_store(k).expo = image_info(i).expo;
        image_store(k).image = current_img;
        image_store(k).ev = current_ev;
        flags(k) = true;
    end
end
image_store = image_store(flags);
end