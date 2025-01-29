function output = edb_bathy_format(funcall,varargin) 
%
%-------function help------------------------------------------------------
% NAME
%   edb_bathy_format.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   estuary bathymetry data Z(X,Y)
% USAGE
%   output = edb_bathy_format(funcall,varargin)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%   This file loads the bathymetry data for an estuary 
%   Input data format is a text file or a .mat file containing a grid
%   object
%   text file header defines format and X,Y,Z data follows in columns, e.g.
%           %f %f %f
%           12.7 14.5 -3.4
%           15.6 3.6   2.8
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2024
%--------------------------------------------------------------------------
%
    switch funcall
        %standard calls from muiDataSet - do not change if data class 
        %inherits from muiDataSet. The function getPlot is called from the
        %Abstract method tabPlot. The class definition can use tabDefaultPlot
        %define plot function in the class file, or call getPlot
        case 'getFormat'
            output = getFormat(varargin{:});
        case 'getData'
          output = getData(varargin{:});
        case 'dataQC'
            output = dataQC(varargin{1});  
        case 'getPlot'
            %output = 0; if using the default tab plot in muiDataSet, else
            output = getPlot(varargin{:});
    end
end
%
%%
%--------------------------------------------------------------------------
% getFormat
%--------------------------------------------------------------------------
function obj = getFormat(obj,formatfile)
    %return the file import format settings
    obj.DataFormats = {'muiUserData',formatfile,'data'};
    obj.idFormat = 1;
    obj.FileSpec = {'on','*.txt; *.csv; *.mat;'};
end
%%
%--------------------------------------------------------------------------
% getData
%--------------------------------------------------------------------------
function newdst = getData(obj,filename,metatxt) 
    %read and load a data set from a file
%     dsp = setDSproperties;                  %set metadata
    %load table and clean data to required format
    [~,estname,ext] = fileparts(filename);

    if strcmp(ext,'.mat')
        promptxt = {'X grid-spacing','Y grid-spacing'};
        gridints = inputdlg(promptxt,'Input',1,{'2','2'});
        data = readmatfile(filename{1,1},gridints);
    else
        data = readinputfile(filename,1,'%f %f %f');  %header defines file read format
    end
    if isempty(data), return; end                
    data{3} = setDataRange(data{3});
    grid = formatGridData(data);          %assign data to struct for x,y,z 
    if isempty(grid), return; end         %user deleted orientGrid UI
    [grid,rotate] = orientGrid(obj,grid); %option to flip or rotate grid
    if isempty(grid), return; end         %user deleted orientGrid UI

    %default values used when not a channnel or not required
    dims = struct('x',grid.x,'y',grid.y,'t',[]);
                                 
    %assign metadata about data source and save grid
    meta.source{1} = filename;  %can be multiple files in GDinterface
    meta.data = sprintf('%s (Rotate option = %d)',metatxt,rotate);
    newgrid(1,:,:) = grid.z;
    obj = setGrid(obj,{newgrid},dims,meta);

    dst = obj.Data.Grid;
    dst.Description = estname;
    newdst.Grid = dst;  %Grid is the dataset name for this format
end

%%
function grid = formatGridData(data)
    %format grid to load into a dstable as single row per grid
    %saves data as z array [1,Nx,Ny] for each time step
    %X and Y assumed fixed and saved as dimensions 
    grid.x = unique(data{:,1},'stable'); %stable so that orientatioin of 
    grid.y = unique(data{:,2},'stable'); %grid is preserved to input direction
    z = data{:,3};
    try
        Nx = length(grid.x);
        Ny = length(grid.y);
        grid.z = reshape(data{:,3},Nx,Ny);
    catch
        try
            %[grid.x,grid.y,grid.z] = xyz2grid(data{:,1},data{:,2},data{:,3});
            [grid.x,~,xi] = unique(data{:,1},'sorted'); 
            [grid.y,~,yi] = unique(data{:,2},'sorted'); 
            grid.z = accumarray([xi yi],z(:),[],[],NaN); 
            %grid.z = flipud(Z);
        catch
            warndlg('Unable to resolve grid from data')
            grid = [];
        end
    end
end

%%
function zdata = setDataRange(zdata)
    %display z range of data and allow user to set new bounds
    minz = num2str(min(zdata));
    maxz = num2str(max(zdata));
    defaults = {minz,maxz};
    promptxt = {'Maximum z value','Minimum z value'};
    answer = inputdlg(promptxt,'Data range',1,defaults);
    if isempty(answer), return; end %user cancelled, limits unchanged
    maxz = str2double(answer{1});
    minz = str2double(answer{2});    
    zdata(zdata<minz) = NaN;
    zdata(zdata>maxz) = NaN;
end

%%
%--------------------------------------------------------------------------
% getPlot
%--------------------------------------------------------------------------
function ok = getPlot(obj,src,dsetname)                    
    %generate a plot on the src graphical object handle  
    ok = [];
    tabcb  = @(src,evdat)tabPlot(obj,src);
    ax = tabfigureplot(obj,src,tabcb,false);
    %get data and variable id
    dst = obj.Data.(dsetname);
    grid = getGrid(obj,1);

    %plot form as a contour plot
    contourf(grid.x,grid.y,grid.z');
    ax = gd_ax_dir(ax,grid.x,grid.y);    
    gd_colormap([min(grid.z,[],'all'),max(grid.z,[],'all')])
    cb = colorbar;
    try
        lims = clim;
        clim([lims(1),20])
    catch
        lims = caxis;
        caxis([lims(1),20])
    end
    cb.Label.String = 'Elevation (mAD)';
    xlabel('Length (m)'); 
    ylabel('Width (m)');    
    title(dst.Description);
    ax.Color = [0.96,0.96,0.96];  %needs to be set after plot
end

%%
%--------------------------------------------------------------------------
% dataQC
%--------------------------------------------------------------------------
function output = dataQC(ob1j) %#ok<INUSD> 
    %quality control a dataset
    % datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
    % dst = obj.Data.(datasetname);      %selected dstable
    warndlg('No quality control defined for this format');
    output = [];    %if no QC implemented in dataQC
end