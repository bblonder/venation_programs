function [] = batchleaf_grayscale(directory, extension)
    claheRadius = 400; % local radius (pixels) for contrast-limited adaptive histogram equalization (CLAHE)
    gain = 0.01; % contrast enhancement (from 0 to 1)
    channel = 2; % grayscale convert using red(1), green(2), or blue(3) channel of image
   
    
    
    
    files = dir([directory sprintf('*%s', extension)])
    numFiles = numel(files);

    for k = 1:numFiles
        
        im_raw = imread([directory files(k).name]);    
        
        % if the image is in color, change it to grayscale
        if (length(size(im_raw)) > 2)
            img = im_raw(:,:,channel);
        else
            img = im_raw;
        end
        
        grayimg = imadjust(im2double(img));

        
        claheImage = adapthisteq(grayimg, 'NumTiles', floor(size(grayimg)/claheRadius), 'ClipLimit', gain);

        G = fspecial('gaussian',[5 5],2);
        claheImage = imfilter(claheImage,G,'same');
        
	imwrite(claheImage, sprintf('%s-CLAHE.JPG', files(k).name(1:(end-length(extension)))), 'jpg', 'Quality',100);
        
        fprintf('%f\n', k/numFiles);
    end
end
