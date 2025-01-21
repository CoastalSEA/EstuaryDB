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
    warndlg('Not yet implemented for Width')
    return

    datasetnames = fieldnames(obj.Data);
    %check whether existing table is to be overwritten or a new table created
    isdset = any(ismatch(datasetnames,'SurfaceArea'));
    if isdset
        answer = questdlg('Overwrite existing or Add new table?','EDB table',...
                          'Overwrite','Add','Quit','Add');
        if strcmp(answer,'Quit')
            return
        elseif strcmp(answer,'Add')
            nrec = sum(contains(datasetnames,'Width'))+1;
            datasetname = sprintf('Width%d',nrec);
        else
            datasetname = 'Width';
        end
    end
    grddst = obj.Data.Grid;  %bathymetry data


end