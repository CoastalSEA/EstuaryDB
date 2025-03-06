function [obj,isok] = edb_surfacearea_table(obj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_surfacearea_table.m
% PURPOSE
%   use grid, bounding shape files to compute surface area hypsometry
% USAGE
%   obj = edb_surfacearea_table(obj);
% INPUTS
%   obj - handle to class instance for EDBimport
% OUTPUT
%   obj - handle to updated class instance for EDBimport
%   isok - logical true if output added, false if user cancelled
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
    isok = 0; 
    if ~isfield(obj.Data,'Grid') || isempty(obj.Data.Grid)
        warndlg('No Grid. Use Setup>Import Spatial Data to load a grid'); 
        return; 
    end

    %check whether existing table is to be overwritten or a new table created
    datasetname = setEDBdataset(obj,'SurfaceArea');
    grid = getGrid(obj);  %bathymetry data

    %get the user to define the upper limit to use for the hypsomety
    defaults = {num2str(max(grid.z,[],'all')),'0.1','1','1'};
    inp = inputdlg({'Upper limit for hypsometry (mAD):',...
                'Vertical interval (m)',...
                'Check plots (1/0-not recommended)'},'EDBhyps',1,defaults);                                                       
    if isempty(inp), return; end               %user cancelled
    uplimit = str2double(inp{1});
    histint = str2double(inp{2});
    isplot  = logical(str2double(inp{3}));     %logical true generates plot

    if isempty(obj.WaterBody)
        answer = 'Load';        
    else
        answer = questdlg('A water-body boundary exists. Use Saved version, or Load from file?',...
                                  'SurfaceArea','Saved','Load','Saved');
    end

    if strcmp(answer,'Load')
        %see if bounding polgon is to be applied from a shape file        
        promptxt = 'Select Shapefile if required:';
        [sname,spath,nfile] = getfiles('PromptText',promptxt,...
                                  'MultiSelect','off','FileType','*.shp;');
        if nfile>0
            %load a shape file and apply bounding polygon
            obj.WaterBody = gd_readshapefile(spath,sname);
            [grid,ax,h_but] = applyBoundary(grid,obj.WaterBody,isplot);
            if isempty(grid), obj = []; return; end                 %failed to load shape file
            metatxt = sprintf('Use bathymetry to upper limit of %.2f within polygon defined by %s',uplimit,sname);
        else
            metatxt = sprintf('Use bathymetry to upper limit of %.2f without bounding polygon',uplimit);
            if isplot
                [ax,h_but] = checkplot(grid,[]);
            end
        end
    else
        %use saved boundary created using PL_Boundary
        [grid,ax,h_but] = applyBoundary(grid,obj.WaterBody,isplot);
        metatxt = sprintf('Use bathymetry to upper limit of %.2f within saved polygon',uplimit);
    end

    %compute the hypsometry
    hyps = edb_s_hypsometry(grid,uplimit,histint,false);  %false - plot as subplot to grid plot if isplot=true
    %write results to a dstable and update class instance
    estuaryname = obj.Data.Grid.Description;
    dst = dstable(hyps(:,3)','RowNames',{estuaryname},'DSproperties',setDSproperties);
    dst.Dimensions.Z = hyps(:,1);
    dst.Description = estuaryname;
    dst.Source = sprintf('Calculated using %s bathymetry',estuaryname);
    dst.MetaData = metatxt;

    if isplot
        subplot(1,3,[1,2],ax);
        hyps_plot(hyps,subplot(1,3,3))
        ok = 0;
        while ok<1
            waitfor(h_but,'Tag')
            if ~ishandle(h_but)     %this handles the user deleting figure window 
                obj = []; isok = 0; %and rejects results
            elseif strcmp(h_but.Tag,'Reject') 
                obj = []; isok = 0; delete(h_but.Parent)  %tidy-up
            else   %user accepted
                obj.Data.(datasetname) = dst;
                delete(h_but);     %keep figure but delete buttons
            end   
            ok = 1; 
        end
    else
        obj.Data.(datasetname) = dst;
        isok = 1;  
    end    
end

%%
function [grid,ax,h_but] = applyBoundary(grid,shp,isplot)
    %use a shape file or boundary and apply bounding polygon    
    [xq,yq] = meshgrid(grid.x,grid.y);
    %insidepoly is faster but only works reliably with shape files 
    %loaded using shaperead which requires mapping toolbox
    hwb = progressbar([],'Computing centre-line');
    if isfile(which('insidepoly.m'))
        [inpoints,onpoints] = insidepoly(xq,yq,shp.x,shp.y);
    else
        [inpoints,onpoints] = inpolygon(xq,yq,shp.x,shp.y);
    end
    progressbar(hwb);

    inpoints = logical(inpoints+onpoints);
    grid.z(~inpoints') = NaN;
    if isplot
        [ax,h_but] = checkplot(grid,shp);
    end
end

%%
function [ax,h_but] = checkplot(grid,shp)
    %plot to check sampling within polygon boundary
    figtitle = sprintf('Accept results');
    figtxt = 'To save the results press Accept';
    tag = 'PlotFig'; %used for collective deletes of a group
    butnames = {'Accept','Reject'};
    position = [0.2,0.4,0.4,0.4];
    [h_plt,h_but] = acceptfigure(figtitle,figtxt,tag,butnames,position);
    ax = axes(h_plt);
    idz =isnan(grid.z);
    idx = ~all(idz,2);
    idy = ~all(idz,1);
    contourf(ax,grid.x(idx),grid.y(idy),grid.z(idx,idy)');
    axis padded
    if ~isempty(shp)
        hold on
        plot(ax,shp.x,shp.y,'r')
        hold off
    end    
end

%%
function hyps_plot(hyps,ax)
    %genereate plot of the surface area and volume as a function of z                                       
    plot(ax,hyps(:,3),hyps(:,1),'DisplayName','Surface area');
    hold on
    plot(ax,hyps(:,4),hyps(:,1),'DisplayName','Volume');
    xlabel('Surface area & Volume');
    ylabel('Elevation (mAD)')
    legend('Location','southeast')
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
