function output = edb_zm_data_format(funcall,varargin) 
%
%-------function help------------------------------------------------------
% NAME
%   edb_zm_data_format.m
% PURPOSE
%   Functions to define metadata, read and load data from file for:
%   Zhang Min's estuary cross-section data
% USAGE
%   output = edb_zm_data_format(funcall,varargin)
% INPUTS
%   funcall - function being called
%   varargin - function specific input (filename,class instance,dsp,src, etc)
% OUTPUT
%   output - function specific output
% NOTES
%   ZM analysed UK estuaries using the SEAZONE bathymetry. This file loads
%   the along-channel data
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
function newdst = getData(obj,filename) %#ok<INUSD>
    %read and load a data set from a file
    dsp = setDSproperties;                  %set metadata
    %load table and clean data to required format
    itable = readtable(filename);
    itable = cleandata(itable,filename);
    idx = 1:height(itable);
    dst = dstable(itable,'RowNames',idx,'DSproperties',dsp);
    dst.Description = itable.Properties.Description;
    newdst.ZMdata = dst;                    %ZMdata is the dataset name for this format
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
        'Name',{'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'},...
        'Description',{'Depth at Low Water','Depth at Mean Tide','Depth at High Water',...
                       'Width at Low Water','Width at Mean Tide','Width at High Water',...
                       'CSA at Low Water','CSA at Mean Tide','CSA at High Water',...
                       'Distance'},...
        'Unit',{'m','m','m','m','m','m','m^2','m^2','m^2','m'},...
        'Label',{'Hydraulic depth (m)','Hydraulic depth (m)','Hydraulic depth (m)',...
                 'Width (m)','Width (m)','Width (m)',...
                 'Cross-sectional area (m^2)','Cross-sectional area (m^2)','Cross-sectional area (m^2)',...
                 'Distance from mouth (m)'},...
        'QCflag',repmat({'data'},1,10)); 
    dsp.Row = struct(...
        'Name',{'XIndex'},...
        'Description',{'X-Index'},...
        'Unit',{'-'},...
        'Label',{'X-index'},...
        'Format',{''});        
    dsp.Dimensions = struct(...    
        'Name',{''},...
        'Description',{''},...
        'Unit',{''},...
        'Label',{''},...
        'Format',{''});   
end

%%
function datable = cleandata(datable,fname)
    %ZM data has no header and the following variables (columns)
    %
    %correct issues in data and re-order variables
    if datable{1,8}>datable{end,8}
        datable = varfun(@flipud,datable);
    end  
    
%     datable = varfun(@transpose,datable);
    [~,location,~] = fileparts(fname);    
    %datable.Properties.RowNames = {location};
    datable.Properties.Description = location;
    datable = removevars(datable,1);                %remove id
    datable = movevars(datable,[2,4,6],'Before',1); %move depths to start
    datable = movevars(datable,7,'After',10);       %move distance to end
    datable = movevars(datable,3,'After',1);        %move mtl values after lw values
    datable = movevars(datable,6,'After',4);        %move mtl values after lw values
    datable = movevars(datable,9,'After',7);        %move mtl values after lw values
    for i=1:3
        %find data with zero depth but a defined width and set to 0.5
        idx = datable{:,i}==0 & datable{:,i+3}>0;
        datable{idx,i} = 0.5;
        datable{idx,i+6} = 0.5*datable{idx,i+3};
    end
    %check that distance starts at zero
    if datable{1,10}>0
        datable{:,10} = datable{:,10}-datable{1,10};
    end    
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
    %get data and variable id - select lw value and plot lw,mt,hw
    varoffset = [1,4,7];
    [dst,idv,props] = selectVariable(obj,dsetname,varoffset);        %dataset specific
    if isempty(idv), return; end
    %create props to define labels for each variable to be plotted
    props = repmat(props,3,1);
    idv = varoffset(idv);
    props(2).desc = dst.VariableDescriptions{idv+1};
    props(3).desc = dst.VariableDescriptions{idv+2}; 
    idv = idv:idv+2;
    %test for a vector data set
    if isvector(dst.(dst.VariableNames{idv(1)}))
        idx = find(strcmp(dst.VariableNames,'xCh')); %index of distance from mouth
        pmax = EDBimport.vectorplot(ax,dst,props,idv,idx);

        %add text box with min max range of variable and length
        boxtxt = sprintf('Length: %.0f m\nMax at LW: %.1e, MT: %.1e, HW: %.1e',pmax.x,pmax.var{:});
        ydist = ax.YLim(1);
        text(0.1,ydist+0.06,boxtxt) 
        ok = 1;
    else
        ok = 0;  %no plot implemented in getPlot
    end
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

