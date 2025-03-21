function output = edb_w_hyps_format(funcall,varargin) 
%
%-------function help------------------------------------------------------
% NAME
%   edb_w_hyps_format.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   width hypsometry data W(x,z), where x is the along-channel distance
%   from the mouth and z is the water elevation, positive above datum (mAD)
% USAGE
%   output = edb_w_hyps_format(funcall,varargin)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%  This file loads the along-channel data for width hypsometry
%   Input data format is a spreadsheet with header row defining x, first
%   column defining z and the data starting in cell B2.
%           z |  x0  |  x23.5  |  x53.3  |  x100.0  |  etc
%       -12.3 |  34  |  12     |    0    |     0    |
%       -1.2  |  230 |  123    |   43    |     0    |
%        1.2  |  420 |  213    |   96    |  27.5    |
%
% Author: Ian Townend
% CoastalSEA (c) Jam 2025
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
    obj.FileSpec = {'on','*.txt; *.csv; *.xlsx;*.xls;'};
end
%%
%--------------------------------------------------------------------------
% getData
%--------------------------------------------------------------------------
function newdst = getData(~,filename,metatxt) 
    %read and load a data set from a file
    dsp = setDSproperties;                  %set metadata
    %load table and clean data to required format
    opts = detectImportOptions(filename,'FileType','spreadsheet');
    itable = readtable(filename,opts);
    %itable = cleandata(itable,filename); %may not be needed
    [~,estname] = fileparts(filename);
    input = reshape(itable{:,2:end}',1,[],height(itable));
    dst = dstable(input,'RowNames',{estname},'DSproperties',dsp);
    X = strip(itable.Properties.VariableNames(2:end),'x'); %remove leading x
    dst.Dimensions.X = cellfun(@str2num, X)';   %convert to double
    dst.Dimensions.Z =itable{:,1};
    dst.Description = estname;
    dst.Source = filename;
    dst.MetaData = metatxt;
    dst.UserData = [];       %unused
    newdst.Width= dst;       %Width is the dataset name for this format
end
%%
%--------------------------------------------------------------------------
% setDSproperties
%--------------------------------------------------------------------------
function dsp = setDSproperties()
    %define the variables and metadata properties for the dataset
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique
    %struct entries are cell arrays and can be column or row vectors
    dsp.Variables = struct(...                      
        'Name',{'W'},...
        'Description',{'Width'},...
        'Unit',{'m'},...
        'Label',{'Width (m)'},...
        'QCflag',{'data'}); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{'Estuary'},...
        'Unit',{'-'},...
        'Label',{'Estuary'},...
        'Format',{''});                    
    dsp.Dimensions = struct(...    
        'Name',{'X','Z'},...
        'Description',{'Distance','Elevation'},...
        'Unit',{'m','mAD'},...
        'Label',{'Distance to mouth (m)','Elevation (mAD)'},...
        'Format',{'',''});   
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
    [var,z,x] = edb_derived_hypsprops(dst,'Width');
    answer = questdlg('Width or CSA','Q-Plot','Width','CSA','Width');
    if strcmp(answer,'CSA')
        Var = var.A;
        zlabel = 'Cross-sectional area (m^2)';
    else
        Var = var.W;
        zlabel = dst.VariableLabels{1};
    end
    Var(Var==0) = NaN;                      %mask zero values
    %create props to define labels for each variable to be plotted
    [X,Z] = meshgrid(x,z);
    contourf(ax,X,Z,Var')
    colormap('parula')
    hc = colorbar;
    hc.Label.String = zlabel;
    xlabel(dst.DimensionLabels{1})
    ylabel(dst.DimensionLabels{2});
    title(sprintf('%s(%s)',dst.Description,dsetname));
    if ~isempty(obj.TidalProps)
        edb_plot_tidelevels(ax,obj.TidalProps);
    end
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

