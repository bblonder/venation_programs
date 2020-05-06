function [result_table, result_other] = calculate_vein_stats(basedir, filecode, px_per_mm, med_filt, spur_length_max, color_roi, color_vein, discard_boundary, plot_image)
    x = imread(fullfile(basedir, filecode));

    image_veins = (x(:,:,1) == color_vein(1) & x(:,:,2) == color_vein(2) & x(:,:,3) == color_vein(3));
    image_mask = image_veins | (x(:,:,1) == color_roi(1) & x(:,:,2) == color_roi(2) & x(:,:,3) == color_roi(3));
    
    % do smoothing
    if (med_filt > 0)
        image_veins = medfilt2(image_veins, [med_filt med_filt]);
    end        
    
    % skeletonize
    image_veins = bwmorph(image_veins, 'skel',Inf);
    
    % clean lonely pixels
    image_veins = bwmorph(image_veins, 'clean');

    % remove spurs
    for (i=1:spur_length_max)
        image_veins = bwmorph(image_veins, 'spur');
    end
    
    % fill any little holes
    image_veins = bwmorph(image_veins, 'fill');
    
    % reskeletonize after trimming
    image_veins = bwmorph(image_veins, 'skel',Inf);

    if (plot_image==1)
        imshow(image_veins)
    end
    
    imep = bwmorph(image_veins, 'endpoints');
    imbp = bwmorph(image_veins, 'branchpoints');
    imcp = imep | imbp;
    [r, c] = find(imcp == 1); % the locations of the vertices of the graph
    [r_ep, c_ep] = find(imep == 1);
    isep = ismember([r, c], [r_ep, c_ep], 'rows');

    imdisconnected = image_veins & ~imdilate(imcp, ones(3)); % fully disconnect the graph by removing all the branchpoints and endpoints

    % find all the vein segments
    CC = bwconncomp(imdisconnected);
    edgelist = NaN([length(CC.PixelIdxList) 2]); % initialize an edgelist
    vertexlist = [r c]; % build the list of vertices

    for i=1:length(CC.PixelIdxList)
        % get x/y coordinates for each section
        [zcc_r, zcc_c] = ind2sub(size(image_veins), CC.PixelIdxList{i});

        % get the endpoints of this segment
        linepoints = reshape([zcc_r([1 end]) zcc_c([1 end])],2,2);
        % figure out which vertex the start and endpoint of the segment is
        % closest to
        distvals = pdist2([r c], linepoints);

        % get the vertex ID (vbeg, vend)
        [~,vbeg] = min(distvals(:,1));
        [~,vend] = min(distvals(:,2));

        edgelist(i,1) = vbeg;
        edgelist(i,2) = vend;
    end

    % remove network loops
    %id_edge_notloop = find(edgelist(:,1)~=edgelist(:,2));
    %CC.NumObjects = length(id_edge_notloop);
    %CC.PixelIdxList = CC.PixelIdxList(id_edge_notloop);
    %edgelist = edgelist(id_edge_notloop,:);

    % draw image fixed
    [image_veins, image_areoles, image_graph, areoles_CC] = drawimageareoles(image_mask, vertexlist, edgelist, CC, discard_boundary);

    % do distance transform
    areoles = regionprops(areoles_CC, 'Image');
    areoleDistances = zeros(length(areoles), 1);
    for j=1:length(areoles)
        distances = bwdist(~(areoles(j).Image));
        areoleDistances(j) = max(max(distances));
    end
    areoleDistances = areoleDistances(isfinite(areoleDistances));
    
    % get the path length divided by the axis length for each edge
    edgeperims = regionprops(CC, 'Perimeter');
    edgeperims = cat(1, edgeperims.Perimeter) / 2; % note /2 to avoid double-counting
    edgemas = regionprops(CC, 'MajorAxisLength');
    edgemas = cat(1, edgemas.MajorAxisLength);
    edgetortuosity = edgeperims ./ edgemas;
    
    % find minimum spanning tree (unweighted by distance)
    if (size(edgelist, 1)>0)
        adj_edges = sparse([edgelist(:,1) edgelist(:,2)], [edgelist(:,2) edgelist(:,1)], 1, max(edgelist(:)), max(edgelist(:)));
        adj_edges(logical(eye(size(adj_edges)))) = 0; % set diagonal to zero
    
        [w_mst, ~, ~] = kruskal(edgelist, edgemas); % weight uniformly each edge
        stat_mst_ratio = w_mst / sum(edgemas);
        
        % network statistics
        index_fevs = find(sum(adj_edges, 1)==1); % freely ending veins have degree one
        stat_fev_ratio = length(index_fevs) / length(edgeperims); % Nr of singleton edges divided by number of edges
        stat_meshedness = (size(edgelist,1) - size(vertexlist,1) + 1) / (2*size(vertexlist,1) - 5);

    else
        stat_mst_ratio = NaN;
        stat_fev_ratio = NaN;
        stat_meshedness = NaN;
    end
    
     % get the image characteristic of this radius

    % get vein statistics
    stat_vein_density = sum(edgeperims) / bwarea(image_mask);
    stat_vein_distance_mean = mean(areoleDistances);
    stat_vein_distance_median = median(areoleDistances);
    stat_vein_distance_sd = std(areoleDistances);
    stat_vein_distance_n = length(areoleDistances);
    
    stat_vein_length_mean = mean(edgeperims);
    stat_vein_length_median = median(edgeperims);
    stat_vein_length_sd = std(edgeperims);
    stat_vein_length_n = length(edgeperims);
    
    stat_vein_tortuosity_mean = mean(edgetortuosity);
    stat_vein_tortuosity_median = median(edgetortuosity);
    stat_vein_tortuosity_sd = std(edgetortuosity);
    stat_vein_tortuosity_n = length(edgetortuosity);
    

    % get areole statistics
    areole_length_major = regionprops(areoles_CC, 'MajorAxisLength');
    areole_length_major = cat(1, areole_length_major.MajorAxisLength);

    areole_length_minor = regionprops(areoles_CC, 'MinorAxisLength');
    areole_length_minor = cat(1, areole_length_minor.MinorAxisLength);

    areole_area = regionprops(areoles_CC, 'Area');
    areole_area = cat(1, areole_area.Area);

    areole_perim = regionprops(areoles_CC, 'Perimeter');
    areole_perim = cat(1, areole_perim.Perimeter);   

    % ratio of long to short axis
    ae = areole_length_major ./ areole_length_minor;
    stat_areole_elongation_mean = mean(ae);
    stat_areole_elongation_median = median(ae);
    stat_areole_elongation_sd = std(ae);
    stat_areole_elongation_n = length(ae);

    % perim^2 / area
    p2a = areole_perim.^2 ./ areole_area;
    stat_areole_roughness_mean = mean(p2a);
    stat_areole_roughness_median = median(p2a);
    stat_areole_roughness_sd = std(p2a);
    stat_areole_roughness_n = length(p2a);
    
    % circularity (4pi*area/perim^2)
    circ = 4*pi*areole_area ./ areole_perim.^2;
    circ = circ(~isinf(circ));
    stat_areole_circularity_mean = mean(circ);
    stat_areole_circularity_median = median(circ);
    stat_areole_circularity_sd = std(circ);
    stat_areole_circularity_n = length(circ);

    % number / area
    stat_areole_loopiness = length(areole_area) / sum(areole_area);
    stat_areole_loop_index = stat_areole_loopiness ./ stat_vein_density^2;
    
    % area analyzed
    stat_area_analyzed = bwarea(image_mask);
    stat_num_areoles = areoles_CC.NumObjects;
    

    % apply scaling factors
    result_table = struct( ...
        'filecode', filecode, ...
        'timestamp', datestr(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z')), ...
        'px_per_mm', px_per_mm, ...
        'med_filt', med_filt, ...
        'spur_length_max', spur_length_max, ...
        'stat_area_analyzed', stat_area_analyzed / px_per_mm^2, ... % mm^2
        'stat_num_areoles', stat_num_areoles, ... % dimensionless
        'stat_vein_density', stat_vein_density * px_per_mm, ... % mm-1
        'stat_vein_distance_mean', stat_vein_distance_mean / px_per_mm, ... % mm
        'stat_vein_distance_median', stat_vein_distance_median / px_per_mm, ... % mm
        'stat_vein_distance_sd', stat_vein_distance_sd / px_per_mm, ... % mm
        'stat_vein_distance_n', stat_vein_distance_n, ... % count
        'stat_vein_length_mean', stat_vein_length_mean / px_per_mm, ... % mm
        'stat_vein_length_median', stat_vein_length_median / px_per_mm, ... % mm
        'stat_vein_length_sd', stat_vein_length_sd / px_per_mm, ... % mm
        'stat_vein_length_n', stat_vein_length_n, ... % count
        'stat_vein_tortuosity_mean', stat_vein_tortuosity_mean, ... % dimensionless
        'stat_vein_tortuosity_median', stat_vein_tortuosity_median, ... % dimensionless
        'stat_vein_tortuosity_sd', stat_vein_tortuosity_sd, ... % dimensionless
        'stat_vein_tortuosity_n', stat_vein_tortuosity_n, ... %  count
        'stat_mst_ratio', stat_mst_ratio, ... % dimensionless
        'stat_areole_elongation_mean', stat_areole_elongation_mean, ... % dimensionless
        'stat_areole_elongation_median', stat_areole_elongation_median, ... % dimensionless
        'stat_areole_elongation_sd', stat_areole_elongation_sd, ... % dimensionless
        'stat_areole_elongation_n', stat_areole_elongation_n, ... % count
        'stat_areole_roughness_mean', stat_areole_roughness_mean, ... % dimensionless
        'stat_areole_roughness_median', stat_areole_roughness_median, ... % dimensionless
        'stat_areole_roughness_sd', stat_areole_roughness_sd, ... % dimensionless
        'stat_areole_roughness_n', stat_areole_roughness_n, ... % count
        'stat_areole_circularity_mean', stat_areole_circularity_mean, ... % dimensionless
        'stat_areole_circularity_median', stat_areole_circularity_median, ... % dimensionless
        'stat_areole_circularity_sd', stat_areole_circularity_sd, ... % dimensionless
        'stat_areole_circularity_n', stat_areole_circularity_n, ... % count
        'stat_areole_loopiness', stat_areole_loopiness * px_per_mm^2, ... % mm-2
        'stat_areole_loop_index', stat_areole_loop_index, ... % dimensionless
        'stat_meshedness', stat_meshedness, ... % dimensionless
        'stat_fev_ratio', stat_fev_ratio ... % dimensionless
    );

    result_other = struct( ...
        'im_veins', image_veins, ...
        'im_areoles', image_areoles, ...
        'im_graph', image_graph, ...
        'vertexlist', vertexlist, ...
        'edgelist', edgelist, ...
        'edgeperims', edgeperims ...
    );

 end