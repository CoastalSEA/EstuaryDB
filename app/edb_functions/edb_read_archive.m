function est = edb_read_archive(filename)
%
%-------function help------------------------------------------------------
% NAME
%   edb_read_archive.m
% PURPOSE
%   read an archive file to recreate an estuary Case.
% USAGE
%   est = edb_read_archive();
% INPUTS
%   filename - full path and file name to archive file to be read
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
    %when reading files in conjunction with EstuaryDB App use:
    obj = EDBimport();
    propnames = obj.tablenames.dsetnames;
    %else define propnames to be read, e.g:
    %propnmes = {'TidalProps';'RiverProps';'ClassProps';'GrossProps'};

    %read header
    fid = fopen(filename,'r');
    est.Header = readHeader(fid);

    %read the property tables foor Tidal, River, Class and Gross Props.
    allnames = [propnames;{'EndProps';'SurfaceArea';'Width';'TopoEdges';'TopoNodes'}];
    nlines = findTableLines(fid,allnames);
    opts = detectImportOptions(filename);
    opts.VariableNames = {'Name','Description','Unit','Label','QCflag','Data'};
    opts.VariableTypes = {'char','char','char','char','char','char'};
    nprops = length(propnames);
    for i=1:nprops
        if nlines(i)>0                                 %if property table exists
            opts.DataLines = [nlines(i)+2,nlines(i+1)-2]; %DSP properties and data
            est.(propnames{i}) = readtable(filename,opts);
        end
    end

    opts.VariableNames = {'Name','Description','Unit','Label','QCflag'};
    opts.VariableTypes = {'char','char','char','char','char'};
    %read the surface area hypsomtery data
    nlineS = nlines(nprops+2);
    if nlineS>0
        opts.DataLines = [nlineS+2,nlineS+3];
        est.SurfaceArea.DSP = readtable(filename,opts);
        est.SurfaceArea.Sa = readVariable(fid,nlineS+4);
        est.SurfaceArea.Z = readVariable(fid,nlineS+5);
        %linework
        est.WaterBody.X = readVariable(fid,nlineS+7);
        est.WaterBody.Y = readVariable(fid,nlineS+8);
    end

    %read the width hypsomtery data
    nlineW = nlines(nprops+3);
    if nlineW>0
        opts.DataLines = [nlineW+2,nlineW+4];
        est.Width.DSP = readtable(filename,opts);
        est.Width.W = readVariable(fid,nlineW+5);
        est.Width.X = readVariable(fid,nlineW+6);
        est.Width.Z = readVariable(fid,nlineW+7);
        %linework
        est.Boundary.X = readVariable(fid,nlineW+9);
        est.Boundary.Y = readVariable(fid,nlineW+10);    
        est.ChannelLine.X = readVariable(fid,nlineW+11);
        est.ChannelLine.Y = readVariable(fid,nlineW+12);
        est.SectionLines.X = readVariable(fid,nlineW+13);
        est.SectionLines.Y = readVariable(fid,nlineW+14);
        est.ChannelProp = readVariable(fid,nlineW+15);
        est.ChannelLengths = readVariable(fid,nlineW+16);
        
        %Graph tables 
        nlineE = nlines(nprops+4);
        nlineN = nlines(end);
        opts.DataLines = [nlineE+2,nlineN-1];
        opts.VariableNames = {'EndNodes_1','EndNodes_2','Weight','Node1','Node2','Line1','Line2'};
        opts.VariableTypes = repmat({'double'},1,7);
        est.TopoEdges = readtable(filename,opts);
    
        opts.DataLines = [nlineN+2,inf];
        opts.VariableNames = {'Names','Distance'};
        opts.VariableTypes = {'char','char'};
        est.TopoNodes = readtable(filename,opts);
    end
    fclose(fid);
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

%%
function var = readVariable(fid,linenum)
    %read the data for the surface area table
    frewind(fid);
    aline = readLine(fid,linenum);
    vartxt = split(aline,':');
    var = str2num(strip(vartxt{2})); %#ok<ST2NM> read vector
end
