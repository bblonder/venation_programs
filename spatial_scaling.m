% [m_sub, m_roi, stats] = [m_sub, m_roi, stats] = spatial_scaling('~/Documents/Oxford/mark fricker hao xu vein collaboration/test images/results/BEL-T209-B2S (R)-CLAHE_results.mat',595,'~/Downloads/result', [], 5);

% fn is path to a .mat file produced by Mark's Binary_Leaf_Network code
% px_per_mm is image resolution
% result_dir is folder to put outputs in
% index_vals is the pixel values to try for edge deletion (if [], set to
% all possible values)
% dilate_px, if >0, shows ONLY in animated gif wider edges
function [m_sub, m_roi, stats] = spatial_scaling(fn, px_per_mm, result_dir, index_vals, dilate_px)
    if nargin < 5
        dilate_px = 5;
    end

    if (7~=exist(result_dir,'dir'))
        mkdir(result_dir);
    end

    m = load(fn);
    
    [~, fn_base, ~] = fileparts(fn); 
    
    tmp_folder = tempdir;
    
    colormap_gif = [0 0 0; 1 1 1; parula(256-2)]; % black background, white ROI, parula colors
    colormap_analysis = [0 0 0; 1 1 1; 1 0 0]; % black background, white ROI, red veins
    
    maxwidth = max(m.width(:));
    m_sub = double(m.width);
    m_roi = double(m.roi);
   
    stats = table;
    
    if (nargin < 4 || isempty(index_vals))
        index_vals = 1:(maxwidth);
    end
    
    for index=1:numel(index_vals)
        i = index_vals(index);
        fprintf(sprintf('%s %d/%d\n', fn_base, index, numel(index_vals)));
        
        m_this = m_roi; % set bg = 0, veins = 1
        m_sub_this = m_sub + 1; % give each vein a value corresponding to its radius + 1
        m_sub_this(m_sub_this < (i+1)) = 0; % remove all veins below the critical value(+1)
        
        
        m_this(m_sub_this > 0) = m_sub_this(m_sub_this > 0); % copy all veins to the new image
        

        % make animated gif
        im_indexed = uint8(ceil(double(m_this) / maxwidth * (256))); % scale colors to 1-256 scale
        im_indexed_raw = im_indexed; % store copy for quantitative use
        
        % make pretty animated output
        % dilate image to make it clearer
        if (dilate_px > 0)
            im_indexed = imdilate(im_indexed, strel('square',5));
        end
        im_indexed_gif_rgb = ind2rgb(im_indexed, colormap_gif);
        im_indexed_gif_rgb = insertText(im_indexed_gif_rgb,[1 1],sprintf('> %07.2f um',i/px_per_mm*1000),'FontSize',24,'BoxColor','black','TextColor','white','BoxOpacity',1);
        im_indexed_gif_ind = rgb2ind(im_indexed_gif_rgb, colormap_gif);
        if (i==1)
            imwrite(im_indexed_gif_ind, colormap_gif, sprintf('%s_animated.gif',fullfile(result_dir, fn_base)),'LoopCount',Inf,'DelayTime',0.01);
        else
            imwrite(im_indexed_gif_ind, colormap_gif, sprintf('%s_animated.gif',fullfile(result_dir, fn_base)), 'WriteMode','append','DelayTime',0.01);
        end
        
        % estimate statistics
        % make ROI + bg image as RGB for input to next function
        im_indexed_analysis = im_indexed_raw;
        im_indexed_analysis(im_indexed_analysis >= 2) = 2; % take any retained veins and set to the same value
        im_indexed_analysis_rgb = ind2rgb(im_indexed_analysis, colormap_analysis);
        fn_analysis = sprintf('%s_%08d_analysis.png', fullfile(result_dir, fn_base), i); % need %04 so the vertcat in the table code works
        imwrite(im_indexed_analysis_rgb, fn_analysis);
        
        [fn_analysis_dir, fn_analysis_base, fn_analysis_extension] = fileparts(fn_analysis);
        
        % calculate the statistics
        [stats_this, ~] = calculate_vein_stats(fn_analysis_dir, [fn_analysis_base, fn_analysis_extension], px_per_mm, 0, 0, [255 255 255], [255 0 0], 1, 0); % last argument = 1 if plot_image
        
        stats_this = struct2table(stats_this);
        
        % store the stats
        stats = [stats; stats_this];
       
        % get rid of the test image
        delete(fn_analysis);
    end
    stats.index_mm = index_vals' / px_per_mm;
    
    writetable(stats, sprintf('%s_stats.csv',fullfile(result_dir, fn_base)));
end