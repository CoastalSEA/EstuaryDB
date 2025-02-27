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
    obj.FileSpec = {'on','*.txt; *.csv; *.tif; *.tiff; *.mat;'};
end
%%
%--------------------------------------------------------------------------
% getData
%--------------------------------------------------------------------------
function newdst = getData(obj,filename,metatxt) 
    %read and load a data set from a file
    [~,estname,ext] = fileparts(filename);

    if strcmp(ext,'.mat')
        %read a mat file containing a grid object stored in a dstable 
        %eg as when a Grid is saved using Project>Save Dataset
        % promptxt = {'X grid-spacing','Y grid-spacing'};
        % gridints = inputdlg(promptxt,'Input',1,{'2','2'});
        data =load(filename,"-mat"); 
        if isempty(data) || ~isstruct(data) || ~isfield(data,'dst')
            warndlg(sprintf('Incorrect dat type in %s',filename))
            newdst = []; return
        else
            newdst.Grid = data.dst;  %dst is asssmued to hold a Grid dataset
            return
        end
    elseif any(strcmp(ext,{'.tif','.tiff'}))
        %read a tiff file with geo-coordinates
        [grid,props] = readtiff(filename);
        grid.z = setDataRange(grid.z');
    else
        %read an x,y,z ascii text file
        data = readinputfile(filename,1,'%f %f %f');  %header defines file read format
        if isempty(data), return; end     
        data{3} = setDataRange(data{3});
        grid = formatGridData(data);          %assign data to struct for x,y,z 
        props = getGridProps(grid);
    end   
    if isempty(grid), return; end         %z not determined in formatGridData

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
    dst.UserData.props = props;
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
            grid = []; return;
        end
    end
    grid = checkGrid(grid);
end

%%
function grid = checkGrid(grid)
    %In EstuaryDB images are used as alternative to grids as the backdrop
    %grids with unveven grid spacing can cause problems, see:
    %https://uk.mathworks.com/matlabcentral/answers/2173624-plot-an-image-with-axes-that-match-the-source-surface-plot
    %to prevent this reformat the grid if required
    dx = diff(grid.x);
    if ~all(diff(dx)==0)
       figure; plot(dx);
       xlabel('diff(x)')
       ylabel('x-increment')
       title('Increments along x-axis are not constant')
    end
    %
    dy = diff(grid.y);
    if ~all(diff(dy)==0)
       figure; plot(dy);
       xlabel('diff(y)')
       ylabel('y-increment')
       title('Increments along y-axis are not constant')
    end
    %
    answer = questdlg('Regrid at constant increments?','Bathymetry','Yes','No','Yes');
    if strcmp(answer,'Yes')
        defaults = {num2str(mode(dx)), num2str(mode(dy))};
        promptxt = {'x-interval','y-interval'};
        inp = inputdlg(promptxt,'Bathymetry',1,defaults);
        if isempty(inp)
            warndlg('Regridding cancelled'); 
            grid = [];
        else
            dx = str2double(inp{1});
            xmnmx = minmax(grid.x);  %assume extent of grid is correct
            xq = xmnmx(1):dx:xmnmx(2);
            dy = str2double(inp{2});
            ymnmx = minmax(grid.y);            
            yq = ymnmx(1):dy:ymnmx(2);

            [X,Y] = meshgrid(grid.x,grid.y);
            [Xq,Yq] = meshgrid(xq,yq);
            Zq = griddata(X,Y,grid.z',Xq,Yq);
            %check plots---------------------------------------------------        
            figure
            subplot(1,2,1)
            pcolor(X,Y,grid.z');
            shading interp
            title('Source data')
            subplot(1,2,2)
            pcolor(Xq,Yq,Zq);
            shading interp 
            title('Re-gridded data')
            %--------------------------------------------------------------
            grid.x = Xq(1,:); 
            grid.y =Yq(:,1); 
            grid.z = Zq';
        end
    end
end

%%
function zdata = setDataRange(zdata)
    %display z range of data and allow user to set new bounds
    minz = min(zdata,[],'all');
    maxz = max(zdata,[],'all');
    if maxz>1000,  maxz = 999; end
    if minz<-1000, minz = -999; end
    defaults = cellstr(num2str([maxz;minz]));
    promptxt = {'Maximum z value','Minimum z value'};
    answer = inputdlg(promptxt,'Data range',1,defaults);
    if isempty(answer), return; end %user cancelled, limits unchanged
    maxz = str2double(answer{1});
    minz = str2double(answer{2});    
    zdata(zdata<minz) = NaN;
    zdata(zdata>maxz) = NaN;
end

%%
function props = getGridProps(grid)
    %get the grid properties from the imported data
    dd.x = abs(grid.x(2)-grid.x(1));               %dx
    dd.y = abs(grid.x(2)-grid.x(1)); 
    % if dd.y>0; dd.y=-dd.y; end                             %dy (should be negative for use below)
    origin.x = grid.x(1);             %origin left
    origin.y = grid.y(1);             %origin top
    NDval = NaN;      %no data value   

    sze.x=size(grid.x);
    sze.y=size(grid.y);
    %output struct for properties of grid
    props = struct('dd',dd,'origin',origin,'NDval',NDval,'size',sze);
end

%%
function [data,props] = readtiff(filename)
    %read data from a tiff file
    data.z = imread(filename,1);
    info = imfinfo(filename);

    dd.x = info.ModelPixelScaleTag(1);              %dx
    dd.y = info.ModelPixelScaleTag(2); 
    dy = dd.y;
    if dy>0; dy=-dy; end    %dy (should be negative for use below)
    origin.x = info.ModelTiepointTag(4);            %origin left
    origin.y = info.ModelTiepointTag(5);            %origin top
    NDval=single(str2double(info.GDAL_NODATA));     %no data value

    meta=[dd.x,0,0,dy,origin.x,origin.y]; %info as if read from a *.tfw file
    
    %%% For top left of each pixel
    % data.x=meta(5):meta(1):meta(5)+(meta(1)*(size(Z,2)-1));
    % data.y=meta(6):meta(4):meta(6)+(meta(4)*(size(Z,1)-1));
    
    %%% For centre of each pixel
    data.x = meta(5)+(meta(1)/2):meta(1):meta(5)+(meta(1)/2)+...
                                              (meta(1)*(size(data.z,2)-1));
    data.y = meta(6)+(meta(4)/2):meta(4):meta(6)+(meta(4)/2)+...
                                              (meta(4)*(size(data.z,1)-1));
    sze.x=size(data.x);
    sze.y=size(data.y);
    %output struct for properties of grid
    props = struct('dd',dd,'origin',origin,'NDval',NDval,'size',sze);
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
    grid = getGrid(obj,1,[],dsetname);

    %plot form as a contour plot
    contourf(grid.x,grid.y,grid.z');
    %ax = gd_ax_dir(ax,grid.x,grid.y);    
    gd_colormap([min(grid.z,[],'all'),max(grid.z,[],'all')])
    axis equal tight
    cb = colorbar;
    cb.Label.String = 'Elevation (mAD)';
    xlabel('Eastings (m)'); 
    ylabel('Northings (m)');    
    title(sprintf('%s(%s)',dst.Description,dsetname));
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