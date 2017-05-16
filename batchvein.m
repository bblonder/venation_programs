function [] = batchvein(basedir, outdir, px_per_mm, med_filt, spur_length_max, color_roi, color_vein, discard_boundary)
    % basedir and outdir should end in slash
    % e.g. batchvein('demo', 'demoresults', 200, 5, 10, [255 255 0], [255 0 0], 1)
    % for 200 dpi images with 5px smoothing, 10px spur length removal, with yellow ROI and red veins
    
    log_filename = 'result_veinstats.csv';

    files = dir(fullfile(basedir,'*.png'));
    
    for i=1:length(files)
        % get the file
        filecode = files(i).name;
        
        % console update
        fprintf('%s %d/%d\n', filecode, i, length(files));
        
        % calculate all statistics
        [result_table, result_other] = calculate_vein_stats(basedir, filecode, px_per_mm, med_filt, spur_length_max, color_roi, color_vein, discard_boundary, 0); % 179 pixels per millimeter, 25 px median smoothing, no plotting
        
        % write out files
        write_header = (i==1);
        summarize_vein_stats(log_filename, result_table, result_other, outdir, write_header);
    end
end