function est = edb_read_archive()
%
%-------function help------------------------------------------------------
% NAME
%   edb_read_archive.m
% PURPOSE
%   read an archive file to recreate an estuary Case.
% USAGE
%   est = edb_read_archive();
% OUTPUT
%   est - struct of data required to load as a case in EstuaryDB:
%         > header: details of vNumber used, Project date, Estuary name
%         co-ordinates and projection used, Creator, Affiliation, and Summary         
%         vNumber,Data,Coordinates,Projection,Creator,Affiliation,Summary
%         > tables for each property table used including TidalProps,
%         RiverProps, ClassProps, GrossProps
%         > tables for surface area and width hypsometry with defining
%         linework.
% NOTES
%  see Appendix F in EstuaryDB manual for details of the file format
% SEE ALSO
%   called from EDBimport class. see edb_write_archive.m
%
% Author: Ian Townend
% CoastalSEA (c) Mar 2025
%--------------------------------------------------------------------------
%
    [fname,path,nfiles] = getfiles('MultiSelect','off',...
                    'FileType','*.txt;','PromptText','Select archive file:');
    if nfiles<1, return; end
    
    %when reading files in conjunction with EstuaryDB App use:
    obj = EDBimport(true);
    propnames = obj.tablenames.dsetnames;
    %else define propnames to be read, e.g:
    %propnmes = {'TidalProps';'RiverProps';'ClassProps';'GrossProps'};

    %read header
    filename = [path,fname];
    fid = fopen(filename,'r');
    est.header = readHeader(fid);

    %read the property tables foor Tidal, River, Class and Gross Props.
    allnames = [propnames;{'EndProps';'SurfaceArea';'Width';'TopoEdges';'TopoNodes'}];
    nlines = findTableLines(fid,allnames);
    opts = detectImportOptions(filename);
    opts.VariableNames = {'Name','Description','Unit','Label','QCflag','Data'};
    opts.VariableTypes = {'char','char','char','char','char','double'};
    for i=1:length(propnames)
        if nlines(i)>0                                 %if property table exists
            opts.DataLines = [nlines(i)+2,nlines(i+1)-2]; %DSP properties and data
            est.(propnames{i}) = readtable(filename,opts);
        end
    end

    %read the surface area hypsomtery data

    %read the width hypsomtery data

end

%%
function nlines = findTableLines(fid,propnames)
    %find the start and end lines of a property table
    frewind(fid);
    nlines = zeros(size(propnames));
    nline = 1;
    tline = fgetl(fid);
    while ~feof(fid)
        if ischar(tline) && any(matches(propnames,tline(1:end-1)))
            nlines(matches(propnames,tline(1:end-1))) = nline;
        end
        nline = nline+1;
        tline = fgetl(fid);
    end     
end

%%
function aline = readLine(fid,linenum)
    %read specific line in a file
    frewind(fid);
    nline = 0;
    while ~feof(fid)
        nline = nline+1;
        aline = fgetl(fid);
        if nline==linenum
            break;
        end
    end
end

%%
function header = readHeader(fid)
    %read the file header data
    frewind(fid);
    fgetl(fid);
    for i=1:8
        aline = fgetl(fid);
        vartxt = split(aline,':');
        header.(vartxt{1}) = strip(vartxt{2});
    end
    
end
