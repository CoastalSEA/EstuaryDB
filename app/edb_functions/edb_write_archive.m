function edb_write_archive(obj,vN,projdate,auth)
%
%-------function help------------------------------------------------------
% NAME
%   edb_write_archive.m
% PURPOSE
%   write an estuary Case to a file for achiving
% USAGE
%   edb_write_archive(obj);
% INPUTS
%   obj - handle to class instance for EDBimport
%   vN - version number for EstuaryDB
%   projdate - date project file was created
%   auth - cell array for text to define creator and affiliation
% OUTPUT
%   output dataset saved to a file
% NOTES
%  see Appendix F in EstuaryDB manual for details of the file format
% SEE ALSO
%   called from EDBimport class. see edb_read_archive.m
%
% Author: Ian Townend
% CoastalSEA (c) Mar 2025
%--------------------------------------------------------------------------
%
    dsetnames = fieldnames(obj.Data);
    estname = obj.Data.(dsetnames{1}).Description;
    promptxt = 'Filename for archive file:';
    inp = inputdlg(promptxt,'Archive',1,{[estname,'_archive.txt']});
    if isempty(inp), return; end
    %open file and write header
    fid = fopen(inp{1},'w');
    fprintf(fid,'EstuaryDB archive file\nvNumber: %s\nDate: %s\n',vN,projdate);
    loc = obj.Location;
    fprintf(fid,'Name: %s\nCoordinates: %d, %d\nProjection: %s\n', ...
                         estname,loc.Latitude,loc.Longitude,loc.Projection);
    fprintf(fid,'Creator: %s\nAffiliation: %s\n',auth{1},auth{2});
    if isempty(obj.Summary), obj.Summary = ''; end
    fprintf(fid,'Summary: %s\n\n',strip(reshape(obj.Summary',1,[])));

    %write property tables
    fprintf(fid,'%%\n%% Property Tables ----------------\n%%\n');
    propnames = obj.tablenames.dsetnames;
    for i=1:length(propnames)
        if ~isempty(obj.(propnames{i}))
            dsp = obj.(propnames{i}).DSproperties.Variables;
            dsp = struct2table(dsp,'AsArray',true);
            %to ensure that all variables are character strings
            vars = table2cell(obj.(propnames{i}).DataTable);
            vars = cellfun(@num2str,vars,'UniformOutput',false)';
            nrec = size(vars,2);
            % Assign each column of cell array to new cell array
            for j = 1:nrec
                dvars{1,j} = vars(:, j); %#ok<AGROW> 
            end
            dvar = split(sprintf('Data%d,', 1:nrec),',');
            dsp = addvars(dsp,dvars{:},'NewVariableNames',dvar(1:nrec));
            fprintf(fid,'%s:\n',propnames{i});
            varnames = dsp.Properties.VariableNames;
            writePropTableLine(fid,varnames);
            for j=1:height(dsp)
                writePropTableLine(fid,dsp{j,:});
            end
            fprintf(fid,'\n');
        end
    end
    clear vars dsp

    %write surface area tables
    fprintf(fid,'EndProps:\n%%\n%% Data Tables ----------------\n%%\n');
    fprintf(fid,'SurfaceArea:\n');
    if isfield(obj.Data,'SurfaceArea') && ~isempty(obj.Data.SurfaceArea)
        dst = obj.Data.SurfaceArea;
        dspv = dst.DSproperties.Variables;
        dspv = struct2table(dspv,'AsArray',true);
        varnames = dspv.Properties.VariableNames;
        writePropTableLine(fid,varnames);
        writePropTableLine(fid,dspv{1,:});          %Surface area
        dspd = dst.DSproperties.Dimensions;
        dspd = struct2table(dspd,'AsArray',true);
        writePropTableLine(fid,dspd{1,:});          %Z-dimension
        fprintf(fid,'Sa: ');
        fprintf(fid,'%f\t',dst.Sa);
        fprintf(fid,'\nZ: ');
        fprintf(fid,'%f\t',dst.Dimensions.Z);
        fprintf(fid,'\n');
        fprintf(fid,'\nWaterBody.X: ');
        fprintf(fid,'%f\t',obj.WaterBody.x);
        fprintf(fid,'\nWaterBody.Y: ');
        fprintf(fid,'%f\t',obj.WaterBody.y);
    end
    fprintf(fid,'\n\n');
    clear dst dspv dspd

    %write width tables
    fprintf(fid,'Width:\n');
    if isfield(obj.Data,'Width') && ~isempty(obj.Data.Width)
        dst = obj.Data.Width;
        dsp = dst.DSproperties.Variables;
        dsp = struct2table(dsp,'AsArray',true);
        writePropTableLine(fid,dsp.Properties.VariableNames);
        for i=1:height(dsp)
            writePropTableLine(fid,dsp{i,:});          %Width 
        end
        dsp = dst.DSproperties.Dimensions;
        dsp = struct2table(dsp,'AsArray',true);
        writePropTableLine(fid,dsp{1,:});          %X-dimension
        writePropTableLine(fid,dsp{2,:});          %Z-dimension
        fprintf(fid,'W: ');
        fprintf(fid,'%f\t',dst.W);
        fprintf(fid,'\nX: ');
        fprintf(fid,'%f\t',dst.Dimensions.X);
        fprintf(fid,'\nZ: ');
        fprintf(fid,'%f\t',dst.Dimensions.Z);
        fprintf(fid,'\nReaches:');
        fprintf(fid,'\n%d',width(dst)-1);
        if width(dst)>1
            Wr = cellfun(@squeeze,table2cell(dst.DataTable(1,2:end)),'UniformOutput',false);    
            Xr = dst.UserData.Xr;                
            for i=1:length(Wr)
                fprintf(fid,'\nWr%d: ',i);
                fprintf(fid,'%f\t',Wr{i});
                fprintf(fid,'\nXr%d: ',i);
                fprintf(fid,'%f\t',Xr{i});
            end
        end
        fprintf(fid,'\n');
        writeSectionLines(fid,obj)
        writeTopoTables(fid,obj.Sections.ChannelProps.topo);
    end
    fprintf(fid,'\n');
    fclose(fid);
    getdialog(sprintf('Archive file written to %s',inp{1})),
end

%%
function writePropTableLine(fid,vars)
    %write a line of a property table to the file
    nvars = length(vars);
    for j=1:nvars-1
        fprintf(fid,'%s\t',vars{j});
    end
    fprintf(fid,'%s\n',vars{nvars});
end

%%
function writeSectionLines(fid,obj)
    %write x and y for the section lines, channel props and channel lengths
    fprintf(fid,'\nSectionLines:');
    fprintf(fid,'\nBoundary.X: ');
    fprintf(fid,'%f\t',obj.Sections.Boundary.x);
    fprintf(fid,'\nBoundary.Y: ');
    fprintf(fid,'%f\t',obj.Sections.Boundary.y);        
    fprintf(fid,'\nChannelLine.X: ');
    fprintf(fid,'%f\t',obj.Sections.ChannelLine.x);
    fprintf(fid,'\nChannelLine.Y: ');
    fprintf(fid,'%f\t',obj.Sections.ChannelLine.y);
    fprintf(fid,'\nSectionLines.X: ');
    fprintf(fid,'%f\t',obj.Sections.SectionLines.x);
    fprintf(fid,'\nSectionLines.Y: ');
    fprintf(fid,'%f\t',obj.Sections.SectionLines.y);
    fprintf(fid,'\nChannelProps: ');
    pp = obj.Sections.ChannelProps;
    fprintf(fid,'%f\t',pp.maxwl,pp.dexp,pp.cint);
    fprintf(fid,'\nChannelLengths: ');
    fprintf(fid,'%f\t',obj.Sections.ChannelProps.ChannelLengths);
end

%%
function writeTopoTables(fid,topo)
    %write the Edges and Nodes tables to file
    fprintf(fid,'\nTopoEdges:\n');
    edges = topo.Edges;
    edges = splitvars(edges,'EndNodes');
    writePropTableLine(fid,edges.Properties.VariableNames);
    for i=1:height(edges)
        fprintf(fid,[repmat('%d\t',1,6),'%d\n'],edges{i,:});
    end
    fprintf(fid,'TopoNodes:\n');
    writePropTableLine(fid,topo.Nodes.Properties.VariableNames);
    for i=1:height(topo.Nodes)
        fprintf(fid,'%s\t%s\n',topo.Nodes{i,:});
    end
end