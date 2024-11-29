function output = edb_zm_image_format(funcall,varargin) % <<Edit to identify data type
%
%-------function help------------------------------------------------------
% NAME
%   edb_zm_image_format.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   Zhang Min's estuary image data
% USAGE
%   output = edb_zm_image_format(funcall,varargin)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%   ZM analysed UK estuaries using the SEAZONE bathymetry. This file loads
%   the images showing the location of the sections used
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
%%
%--------------------------------------------------------------------------
% getFormat
%--------------------------------------------------------------------------
function obj = getFormat(obj,formatfile)
    %return the file import format settings
    obj.DataFormats = {'muiUserData',formatfile,'image'};
    obj.idFormat = 1;
    obj.FileSpec = {'on','*.jpg;'};
end
%%
%--------------------------------------------------------------------------
% getData
%--------------------------------------------------------------------------
function newdst = getData(obj,filename) %#ok<INUSD>
    %read and load a data set from a file
    dsp = setDSproperties;                 %set metadata
    [~,location,~] = fileparts(filename);   
    imdata = {imread(filename)};
    %load the results into a dstable - ZMimage is the dataset name for this format
    dst = dstable(imdata,'RowNames',{location},'DSproperties',dsp);  
    dst.Description = location;
    newdst.ZMimage = dst;                    %ZMdata is the dataset name for this format
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
        'Name',{'image'},...
        'Description',{'Image'},...
        'Unit',{''},...
        'Label',{'Image'},...
        'QCflag',repmat({'data'},1,1)); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{''},...
        'Unit',{'-'},...
        'Label',{'Location'},...
        'Format',{''});        
    dsp.Dimensions = struct(...    
        'Name',{''},...
        'Description',{''},...
        'Unit',{''},...
        'Label',{''},...
        'Format',{''});   
end

%%
%--------------------------------------------------------------------------
% getPlot
%--------------------------------------------------------------------------
function ok = getPlot(obj,src,dsetname)
    %generate a plot on the src graphical object handle
    ok = [];
    tabcb  = @(src,evdat)tabPlot(obj,src);
    tabfigureplot(obj,src,tabcb,false);
    %get data and variable id
    [dst,idv,props] = selectVariable(obj,dsetname);     %dataset specific
    if isempty(idv), return; end
    %test for array of allowed data types for a color image
    isim = isimage(dst.DataTable{1,1});
    if isim(1) %isim(1) is color and isim(2) is greyscale
        img = dst.(dst.VariableNames{idv});
        imshow(img{1});        
        title(get_selection_text(props,1));
        ok = 1;
    else
        ok = 0;  %no plot implemented in getPlot
    end
end

%%
%--------------------------------------------------------------------------
% dataQC
%--------------------------------------------------------------------------
function output = dataQC(obj)                    %#ok<INUSD> 
    %quality control a dataset
    % datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
    % dst = obj.Data.(datasetname);      %selected dstable
    warndlg('No quality control defined for this format');
    output = [];    %if no QC implemented in dataQC
end


