function obj = edb_surfacearea_table(obj)
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
%   compute histogram of surface area from a grid and save to a dstable
% SEE ALSO
%   uses the same output format as the edb_s_hyps_format which is also
%   called from EDBimport to create the same dataset.
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2025
%--------------------------------------------------------------------------
%
    datasetnames = fieldnames(obj.Data);
    %check whether existing table is to be overwritten or a new table created
    isdset = any(ismatch(datasetnames,'SurfaceArea'));
    if isdset
        answer = questdlg('Overwrite existing or Add new table?','EDB table',...
                          'Overwrite','Add','Quit','Add');
        if strcmp(answer,'Quit')
            return
        elseif strcmp(answer,'Add')
            nrec = sum(contains(datasetnames,'SurfaceArea'))+1;
            datasetname = sprintf('SurfaceArea%d',nrec);
        else
            datasetname = 'SurfaceArea';
        end
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
    promptxt = 'Select Shapefile if required:';
    [sname,spath,nfile] = getfiles('PromptText',promptxt,'MultiSelect','off',...
                                                     'FileType','*.shp;');
    if nfile>0  
        %load a shape file and apply bounding polygon
        grid = applyBoundary(grid,spath,sname,false); %logical true generates plot
        metatxt = sprintf('Use bathymetry to upper limit of %.2f within polygon defined by %s',uplimit,sname);
    else
        metatxt = sprintf('Use bathymetry to upper limit of %.2f without bounding polygon',uplimit);
    end

    %compute the hypsometry
    hyps = edb_hypsometry(grid,uplimit,histint,false); %logical true generates plot
    %write results to a dstable and update class instance
    dst = dstable(hyps(:,3)','RowNames',{estuaryname},'DSproperties',setDSproperties);
    dst.Dimensions.Z = hyps(:,1);
    dst.Description = estuaryname;
    dst.Source = sprintf('Calculated using %s bathymetry',estuaryname);
    dst.MetaData = metatxt;
    obj.Data.(datasetname) = dst;
end
%%
function grid = applyBoundary(grid,path,filename,isplot)
    %load a shape file and apply bounding polygon
    istoolbox = license('test','MAP_Toolbox');   %toolbox is licensed to use
    if istoolbox
        addons = matlab.addons.installedAddons;
        istoolbox = any(matches(addons.Name,'Mapping Toolbox')); %toolbox is installed
    end  

    [~,shapename,~] = fileparts(filename);
    if istoolbox
        Shp = shaperead([path,shapename]);   %requires Mapping toolbox
    elseif isfile('m_shaperead')
        shp = m_shaperead([path,shapename]); %use M-Map function instead
        Shp.X = shp.ncst{1}(:,1); 
        Shp.Y = shp.ncst{1}(:,2);
    else
        errdlg('Unable to load Shape file\nCheck Mapping toolbox or M-Map is installed'); return;
    end

    [xq,yq] = meshgrid(grid.x,grid.y);
    %insidepoly is faster but only works reliably with shape files 
    %loaded using shaperead which requires mapping toolbox
    if istoolbox
        [inpoints,onpoints] = inpolygon(xq,yq,Shp.X,Shp.Y);
    else
        [inpoints,onpoints] = insidepoly(xq,yq,Shp.X,Shp.Y);
    end

    inpoints = logical(inpoints+onpoints);
    grid.z(~inpoints') = NaN;
    if isplot
     checkplot(grid,Shp)
    end
end
%%
function checkplot(grid,Shp)
    %plot to check sampling within polygon boundary
    hf = figure('Name','Extracted bathymetry','Resize','on','Tag','PlotFig');
    ax = axes(hf);
    contourf(ax,grid.x,grid.y,grid.z');
    ax = gca;
    hold on
    plot(ax,Shp.X,Shp.Y,'r')
    hold off
end
%%
function dsp = setDSproperties()
    %define the variables and metadata properties for the dataset
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique
    %struct entries are cell arrays and can be column or row vectors
    dsp.Variables = struct(...                      
        'Name',{'Sa'},...
        'Description',{'Surface area'},...
        'Unit',{'m^2'},...
        'Label',{'Surface area (m^2)'},...
        'QCflag',{'data'}); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{'Estuary'},...
        'Unit',{'-'},...
        'Label',{'Estuary'},...
        'Format',{''});    
    dsp.Dimensions = struct(...         
        'Name',{'Z'},...
        'Description',{'Elevation'},...
        'Unit',{'mAD'},...
        'Label',{'Elevation (mAD)'},...
        'Format',{''});  
end
