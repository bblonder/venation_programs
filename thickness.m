reps = 5; % number of vein segments to analyze
px_per_mm=179; % image resolution

wd = 'demo/'; % folder that contains the input images

suffix_output = 'RADIUSum-HAND'; % suffix of output CSV files
suffix_input = '-CLAHE.jpg'; % filtering suffix of input CSV files









images = dir(fullfile([wd, sprintf('*%s',suffix_input)]));

for i=1:length(images)
    imageid = strrep(images(i).name,suffix_input,'');
    outfile = sprintf('%s-%s.csv',imageid,suffix_output);
    
    if (exist(fullfile([wd outfile])))
        fprintf('skip %s\n', imageid);
    else
        f = figure();
        
        im = imread(fullfile([wd, images(i).name]));

        width=600;
        imcropped = im(500:(500+width),500:(500+width));

        coords_all = NaN(0, 5);

        RGB = imcropped;

        for j=1:reps
            
            set(f, 'Name', sprintf('%s %d',imageid, j));

            rxy = floor(rand(1,2).*size(imcropped));

            RGB2 = insertShape(RGB, 'Circle', [rxy(1) rxy(2) 10], 'LineWidth', 2,'Color','green');
            imshow(RGB2);
            set(f, 'Position', [0, 0, 800, 800]);

            xy = ginput(2);

            diam = sqrt((xy(2,1) - xy(1,1))^2 + (xy(2,2) - xy(1,2))^2);
            tl = [xy(1,1) xy(1,2) xy(2,1) xy(2,2) diam];

            coords_all = [coords_all; tl];

            RGB = insertShape(RGB, 'Line', tl(1:4), 'LineWidth', 1,'Color','red');

            imshow(RGB);
            set(f, 'Position', [0, 0, 800, 800]);
        end

        coords_all_scaled = coords_all;
        coords_all_scaled(:,5) = coords_all_scaled(:,5) * 1000 / px_per_mm; % convert to microns

        csvwrite(fullfile([wd sprintf('%s-%s.csv',imageid,suffix_output)]),coords_all_scaled);
        
        close(f);
    end
end

