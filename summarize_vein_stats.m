function [] = summarize_vein_stats(logfilename, r_table, r_other, outdir, write_header)
    if (nargin < 4)
        outdir = 'RESULTS';
    end
    
    if (~(exist(outdir)==7))
        fprintf('Creating output folder\n')
        mkdir(outdir)
    end


    
    imwrite(r_other.im_veins, fullfile(outdir, sprintf('%s-VEINS.png',r_table.filecode)));
    imwrite(r_other.im_areoles, fullfile(outdir, sprintf('%s-AREOLES.png',r_table.filecode)));
    imwrite(r_other.im_graph, fullfile(outdir, sprintf('%s-GRAPH.png',r_table.filecode)));

    
    dlmwrite(fullfile(outdir, sprintf('%s-VERTEXLIST.csv', r_table.filecode)), r_other.vertexlist);
    dlmwrite(fullfile(outdir, sprintf('%s-EDGELIST.csv', r_table.filecode)), r_other.edgelist);
    
    % write out statistics
    writeline(fullfile(outdir, logfilename), r_table, write_header, 1);
end