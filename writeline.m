function [] = writeline(outfile, structure, writeheader, writedata)
    %// Extract field data
    fields = repmat(fieldnames(structure), numel(structure), 1);
    values = struct2cell(structure);

    %// Convert all numerical values to strings
    idx = cellfun(@isnumeric, values); 
    values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);

    
     %// Write fields to CSV file
    fid = fopen(outfile, 'a');
    fmt_str = repmat('%s,', 1, size(fields, 1));
    
    if (writeheader)
        fprintf(fid, [fmt_str(1:end - 1), '\n'], fields{:});
    end
    if (writedata)
        fprintf(fid, [fmt_str(1:end - 1), '\n'], values{:});
    end
    
    fclose(fid);   
end