reps = 10; % number of vein segments to analyze
px_per_mm=179; % image resolution

width = 600; % should be even number

line_color = 'red';

wd = 'demo/'; % folder that contains the input images

suffix_input = '.jpg'; % filtering suffix of input CSV files
suffix_output = 'coords_scaled'








images = dir(fullfile([wd, sprintf('*%s',suffix_input)]));

for i=1:length(images)
    imageid = strrep(images(i).name,suffix_input,'');
    outfile = sprintf('%s-%s.csv',imageid,'counted');
    
    if (exist(fullfile([wd outfile])))
        fprintf('Outfile exists - skipping %s\n', imageid);
    else
        f = figure();
        
        im = imread(fullfile([wd, images(i).name]));


        coords_all = NaN(0, 5);

        current_rep = 1;
        while current_rep <= reps
            rand_x = randi([width/2 (size(im,2) - width/2)], 1, 1);
            rand_y = randi([width/2 (size(im,1) - width/2)], 1, 1);
            
            imcropped = imcrop(im, [ rand_x - width/2, rand_y - width/2, width, width ]);
            
            RGB = imcropped;
            
            set(f, 'Name', sprintf('%s %d',imageid, current_rep));

            rxy = floor(rand(1,2).*size(imcropped));

            RGB2 = insertShape(RGB, 'Circle', [rxy(1) rxy(2) 10], 'LineWidth', 2,'Color','green');
            imshow(RGB2);
            set(f, 'Position', [0, 0, 800, 800]);
            
            
            k = waitforbuttonpress;
            if (k==0)
                figure(f);
                coord_1 = ginput(1);
                coord_2 = ginput(1);

                diam = sqrt((coord_2(1) - coord_1(1))^2 + (coord_2(2) - coord_1(2))^2);
                tl = [coord_1(1) + rand_x - width/2,  coord_1(2) + rand_y - width/2, coord_2(1) + rand_x - width/2, coord_2(2) + rand_y - width/2, diam];

                coords_all = [coords_all; tl];
                
                current_rep = current_rep + 1;
            else
                fprintf('Key pressed; skipping\n');
            end  
        end

        coords_all_scaled = double(coords_all);
        coords_all_scaled(:,5) = coords_all_scaled(:,5) * 1000 / px_per_mm; % convert to microns

        csvwrite(fullfile([wd sprintf('%s-%s.csv',imageid,suffix_output)]),coords_all_scaled);
        
        RGB_final = im;
        for clrow=1:size(coords_all,1)
            RGB_final = insertShape(RGB_final, 'Line', coords_all(clrow,1:4), 'LineWidth', 2,'Color',line_color);
        end
        imwrite(RGB_final, fullfile([wd sprintf('%s-%s.jpg',imageid,'segments')]));
        
        close(f);
    end
end

