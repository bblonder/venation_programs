function [im_veins, im_areoles, im_graph, CCareolestrimmed] = drawimageareoles(image_mask, vertexlist, edgelist, CC, discard_boundary) 
    vertex_size = 5; % odd number indicating size of vertex marker (larger erases more small areoles)

    % returns imfinal - all veins with radius above threshold, each with
    % unique color
    % returns imareoles - all areoles defined by veins with radius above
    % threshold, each with unique color
    % returns CCareolestrimmed - connected components of trimmed areoles

    % load in a blank image
    im_veins = uint16(image_mask);  
    % plot edges
    for i=1:length(CC.PixelIdxList)
        im_veins(CC.PixelIdxList{i}) = 2 + i;
    end
    
    % identify vertices that are retained
    verticestokeep = unique(edgelist(:));
    
    % plot vertices (value 2)
    im_vertices = zeros(size(im_veins));
    for i=1:size(vertexlist,1)
        if (ismember(i, verticestokeep))
            im_vertices(vertexlist(i,1), vertexlist(i,2)) = 1;
        end
    end
    im_veins = im_veins + uint16(imdilate(im_vertices, ones(vertex_size)));
    
    % find the areoles
    im_areoles = (im_veins < 2); % background is ==0, mask area is ==1

    CCareoles = bwconncomp(im_areoles, 4);
    
    % create a 'trimmed' result
    CCareolestrimmed = CCareoles;
    CCareolestrimmed.NumObjects = 0;
    CCareolestrimmed.PixelIdxList = {};
    
    % add non-boundary areoles
    for i=1:CCareoles.NumObjects
        [areole_r, areole_c] = ind2sub(CCareoles.ImageSize, CCareoles.PixelIdxList{i});

        % if no pixels are a boundary pixel
        if (~discard_boundary || (~(any(areole_r == 1) || any(areole_r == CCareoles.ImageSize(1)) || any(areole_c == 1) || any(areole_c == CCareoles.ImageSize(2)) )))
            CCareolestrimmed.PixelIdxList = [ CCareolestrimmed.PixelIdxList, CCareoles.PixelIdxList{i} ];
            CCareolestrimmed.NumObjects = CCareolestrimmed.NumObjects + 1;
        end
    end
    % add background mask for areole picture
    im_areoles = uint16(image_mask) + uint16(labelmatrix(CCareolestrimmed));
    
    
    % plot veins and areoles in indexed color maps
    randcolors = winter(double(max(im_veins(:))));
    randcolors = randcolors(randsample(size(randcolors,1),size(randcolors,1)),:);
    map_veins = [[0 0 0]; [1 1 1]; [1 0 0]; randcolors];

    randcolors2 = cool(double(max(im_areoles(:))));
    randcolors2 = randcolors2(randsample(size(randcolors2,1),size(randcolors2,1)),:);
    map_areoles = [0,0,0; [1 1 1]; randcolors2];
    
    im_veins = ind2rgb(im_veins, map_veins);
    im_areoles = ind2rgb(im_areoles, map_areoles);
    
    % draw graph representation of network
    im_graph = ind2rgb(image_mask,[0 0 0; 1 1 1]);
    colors = parula(size(edgelist,1));
    colors = colors(randsample(size(colors,1), size(colors,1)),:);
    im_graph = insertShape(im_graph, 'Line', [vertexlist(edgelist(:,1),2), vertexlist(edgelist(:,1),1), vertexlist(edgelist(:,2),2), vertexlist(edgelist(:,2),1)],'Color',colors,'SmoothEdges',false);
end
