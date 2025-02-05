function obj = edb_width_table(obj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_surfacearea_table.m
% PURPOSE
%   read a set of files for bathymetry, bounding shape files and tidal data 
%   to compute volume and surface area hypsometry
% USAGE
%   obj = edb_surfacearea_table(obj);
% INPUTS
%   obj - handle to class instance for EDBimport
% OUTPUT
%   obj - handle to updated class instance for EDBimport
% NOTES
%   compute histogram of width from a grid and save to a dstable
% SEE ALSO
%   uses the same output format as the edb_w_hyps_format which is also
%   called from EDBimport to create the same dataset.  
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2025
%--------------------------------------------------------------------------
%
%     warndlg('Not yet implemented for Width')
%     return

    datasetnames = fieldnames(obj.Data);
    %check whether existing table is to be overwritten or a new table created
    isdset = any(ismatch(datasetnames,'SurfaceArea'));
    if isdset
        answer = questdlg('Overwrite existing or Add new table?','EDB table',...
                          'Overwrite','Add','Quit','Add');
        if strcmp(answer,'Quit')
            obj = []; return;
        elseif strcmp(answer,'Add')
            nrec = sum(contains(datasetnames,'Width'))+1;
            datasetname = sprintf('Width%d',nrec);
        else
            datasetname = 'Width';
        end
    else
        datasetname = 'Width';
    end
    grid = getGrid(obj);  %bathymetry data

    %get the user to define the upper limit to use for the hypsomety
    uplimit = {num2str(max(grid.z,[],'all')),'0.1'};
    inp = inputdlg({'Upper limit for hypsometry (mAD):','Vertical interval (m)'},...        
                                                    'EDBhyps',1,uplimit);
    uplimit = str2double(inp{1});
    histint = str2double(inp{2});    
    %see if bounding polgon is to be applied from a shape file
    estuaryname = obj.Data.Grid.Description;
    promptxt = 'Select Shapefile:';
    [sname,spath,nfile] = getfiles('PromptText',promptxt,'MultiSelect','off',...
                                                     'FileType','*.shp;');
%     if nfile>0  
%         %load a shape file and apply bounding polygon
%         grid = applyBoundary(grid,spath,sname,false); %logical true generates plot
%         metatxt = sprintf('Use bathymetry to upper limit of %.2f with sections defined by %s',uplimit,sname);
%     else
%         warndlg('Option to construct sections in App not yet implemented')
%         return
%         %metatxt = sprintf('Use bathymetry to upper limit of %.2f with sections constucted in App',uplimit);
%     end
    %compute the hypsometry
    hyps = edb_w_hypsometry(grid,uplimit,histint,true); %logical true generates plot
    %write results to a dstable and update class instance
    dst = dstable(hyps(:,3)','RowNames',{estuaryname},'DSproperties',setDSproperties);
    dst.Dimensions.X = 1;
    dst.Dimensions.Z = hyps(:,1);
    dst.Description = estuaryname;
    dst.Source = sprintf('Calculated using %s bathymetry',estuaryname);
    dst.MetaData = metatxt;
    obj.Data.(datasetname) = dst;
end