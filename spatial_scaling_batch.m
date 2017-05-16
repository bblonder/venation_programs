% assumes we already have the .xcf converted to .mat via 
% spatial_scaling_batch('~/Documents/Oxford/mark fricker hao xu vein collaboration/test images/results', 595, '~/Downloads/result', [1 5 10])
function [] = spatial_scaling_batch(input_dir, px_per_mm, result_dir, index_vals)
    dilation_amount = 5;

    input_files = dir(fullfile(input_dir,'*.mat'));
    
    for i=1:length(input_files)
        fn_this = input_files(i).name;
        
        fprintf('*** %d / %d - %s\n', i, length(input_files), fn_this);
        
        [~, ~, ~] = spatial_scaling(fullfile(input_dir, fn_this),px_per_mm,result_dir, index_vals, dilation_amount);
    end
end