clear; close all; clc;

path0 = getenv('PATH');
if ~contains(path0, '/usr/local/Cellar/dcraw/9.27.0_2/bin')
% if isempty(strfind(path0, '/usr/local/Cellar/dcraw/9.27.0_2/bin'))
    path1 = ['/usr/local/Cellar/dcraw/9.27.0_2/bin:', path0];
    setenv('PATH', path1);
end

work_path = '/Volumes/ZJJ-4TB/Photos/18.01.31 Lunar Eclipse by Wang Letian/';
input_image_path = [work_path, '02/'];
output_image_path = [work_path, 'timelapse/tiff/'];

k = 1;
expo_group.idx_range = [0, 0];
while true
    expo_group = find_next_exposure_group(input_image_path, expo_group.idx_range(2) + 1);
    if isempty(expo_group.idx_range)
        break;
    end
    image_info = choose_valid_exposures(input_image_path, expo_group.files);
    image_store = read_exposures(input_image_path, image_info);
    trans_mat = align_images(image_store);
    merge_result = hdr_merge(image_store, trans_mat);
    alpha = 0.09 + 0.0125 * length(image_store);
    merge_result = local_laplacian(merge_result, 8, alpha, 0.9);
    imwrite(uint16(merge_result * 65535), sprintf('%s%03d.tiff', output_image_path, k));
    k = k + 1;

%     expo_group.idx_range(2) = expo_group.idx_range(2) + 150;
%     k = k + 1;
%     if k > 12
%         break;
%     end
end
