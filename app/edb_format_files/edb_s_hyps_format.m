function output = edb_s_hyps_format(funcall,varargin) 
%
%-------function help------------------------------------------------------
% NAME
%   edb_s_hyps_format.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   hypsometry estuary data (z,S)
% USAGE
%   output = edb_s_hyps_format(funcall,varargin)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%   This file loads the surface area data for the whole estuary 
%   Input data format is a spreadsheet with header row defining variables,
%    first column defining z and the data starting in cell B2. This is the
%    output from multi_hypsometry.m and is converted to an Excel
%    spreadsheet using save_estuary_hypsometry.m
%           z |  h  |  S   |  V   | 
%       -12.3 |  3  |  12  |  67  |
%       -1.2  |  23 |  128 |  138 |
%        1.2  |  42 |  226 |  446 |
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
    itable = readtable(filename);
    itable = cleandata(itable,filename);
    [~,estname] = fileparts(filename);
    dst = dstable(itable{:,2}','RowNames',{estname},'DSproperties',dsp);
    dst.Dimensions.Z = itable{:,1};
    dst.Description = estname;
    dst.Source = filename;
    dst.MetaData = metatxt;
    dst.UserData = [];         %unused
    newdst.SurfaceArea= dst;  %SurfaceArea is the dataset name for this format
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

%%
function datable = cleandata(datable,~)
    %correct issues in data and order of variables  
    datable = datable(:,[1,3]);
end

%%
%--------------------------------------------------------------------------
% getPlot
%--------------------------------------------------------------------------
function ok = getPlot(obj,src,dsetname)                    
    %generate a plot on the src graphical object handle  
    ok = [];
    tabcb  = @(src,evdat)tabPlot(obj,src);
    ax = tabfigureplot(obj,src,tabcb,false,'x-axis'); %false for no rotate button 
    %get data and variable id
    dst = obj.Data.(dsetname);
    S = dst.Sa;
    Z = dst.Dimensions.Z;
    delZ = abs(Z(2)-Z(1));
    V = cumsum(S)*delZ;      %hypsometry volume
    %create props to define labels for each variable to be plotted
    plot(ax,S,Z,'DisplayName',dst.VariableDescriptions{1},'ButtonDownFcn',@godisplay);
    hold on
    plot(ax,V,Z,'DisplayName','Volume (derived)','ButtonDownFcn',@godisplay);
    hold off
    xlabel(sprintf('%s and %s',dst.VariableLabels{1},'Volume (m^3)'));
    ylabel(dst.DimensionLabels{1});
    title(dst.Description)
    legend('Location','southeast')
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

