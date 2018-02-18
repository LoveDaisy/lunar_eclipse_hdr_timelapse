clear; close all; clc;

path0 = getenv('PATH');
if ~contains(path0, '/usr/local/Cellar/dcraw/9.27.0_2/bin')
% if isempty(strfind(path0, '/usr/local/Cellar/dcraw/9.27.0_2/bin'))
    path1 = ['/usr/local/Cellar/dcraw/9.27.0_2/bin:', path0];
    setenv('PATH', path1);
end

work_path = '/Volumes/ZJJ-4TB/Photos/18.01.31 Lunar Eclipse by Wang Letian/';
input_image_path = [work_path, '02/'];
% output_image_path = './';
output_image_path = [work_path, 'timelapse/tiff/'];

k = 1;
expo_group.idx_range = [0, 0];
start_time = tic;
while true
    t0 = tic;
    group_start = t0;
    expo_group = find_next_exposure_group(input_image_path, expo_group.idx_range(2) + 1);
    if isempty(expo_group.idx_range)
        break;
    end
    fprintf(' find_next_exposure_group: %.2fs\n', toc(t0));
    
    t0 = tic;
    image_info = choose_valid_exposures(input_image_path, expo_group.files);
    fprintf(' choose_valid_exposures: %.2fs\n', toc(t0));
    
    t0 = tic;
    image_store = read_exposures(input_image_path, image_info);
    fprintf(' read_exposures: %.2fs\n', toc(t0));
    
    t0 = tic;
    trans_mat = align_images(image_store);
    fprintf(' align_images: %.2fs\n', toc(t0));
    
    t0 = tic;
    merge_result = hdr_merge(image_store, trans_mat);
    fprintf(' hdr_merge: %.2fs\n', toc(t0));
    
    fprintf('Local Laplacian...\n');
    t0 = tic;
    alpha = 0.09 + 0.025 * length(image_store);
    merge_result_enh = local_laplacian(merge_result, 8, alpha, 0.9);
    merge_result_enh = merge_result_enh / prctile(merge_result_enh(:), 99.95) * 0.98;
    fprintf(' local_laplacian: %.2fs\n', toc(t0));
    
    fprintf('Write image...\n');
    t0 = tic;
    imwrite(uint16(merge_result_enh * 65535), sprintf('%s%03d.tiff', output_image_path, k));
    fprintf(' imwrite: %.2fs\n', toc(t0));
    fprintf(' Group ellapsed: %.2fs\n', toc(group_start));
    k = k + 1;

%     expo_group.idx_range(2) = expo_group.idx_range(2) + 150;
%     if k > 10
%         break;
%     end
end
fprintf(' Total ellapsed: %.2f\n', toc(start_time));
