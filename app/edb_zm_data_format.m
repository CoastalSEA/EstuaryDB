function output = edb_zm_data_format(funcall,varargin) % <<Edit to identify data type
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
% getData
%--------------------------------------------------------------------------
function dst = getData(obj,filename,dst) %#ok<INUSD>
    %datable is the DataTable already loaded (if any)
    %set metadata
    dsp = setDSproperties;
    %read and load a data set from a file
    itable = readtable(filename);
    itable = cleandata(itable,filename); 
%     iname = itable.Properties.RowNames;
    idx = 1:height(itable);
    dst = dstable(itable,'RowNames',idx,'DSproperties',dsp);
%     if isempty(dst)
%         dst = dstable(itable,'RowNames',iname,'DSproperties',dsp);
%     else
%         itable.Properties.VariableNames = {dsp.Variables.Name};
%         if any(~ismatch(dst.VariableNames,itable.Properties.VariableNames))
%             warndlg(sprintf('File %s not added',filename))
%             return;
%         end
%         %[dst.DataTable,itable] = checkdims(dst.DataTable,itable);
%         %load the results into a dstable
%         %dst = dstable(itable,'RowNames',iname,'DSproperties',dsp);
%         %dst= [dst;idst];
%     end
    %dst.Dimensions.X = 1:size(dst.DataTable{1,1},2);
end
%%
%--------------------------------------------------------------------------
% dataDSproperties
%--------------------------------------------------------------------------
function dsp = setDSproperties()
    %define the variables in the dataset
    %define the metadata properties for the demo data set
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
%--------------------------------------------------------------------------
% dataQC
%--------------------------------------------------------------------------
function output = dataQC(obj)                        % <<Add any quality control to be applied (optional)
    %quality control a dataset
    % datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
    % dst = obj.Data.(datasetname);      %selected dstable
    warndlg('No quality control defined for this format');
    output = [];    %if no QC implemented in dataQC
end
%%
%--------------------------------------------------------------------------
% getPlot
%--------------------------------------------------------------------------
function ok = getPlot(obj,src)                       % <<Add code for bespoke Q-Plot is required (optional)
    %generate a plot on the src graphical object handle    
    ok = 0;  %ok=0 if no plot implemented in getPlot
    %return some other value if a plot is implemented here
end
%%
function datable = cleandata(datable,fname)
    %correct issues in data and re-order variables
%     if datable{1,8}>datable{end,8}
%         datable = varfun(@flipud,datable);
%     end  
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
        idx = datable{1,i}==0 & datable{1,i+3}>0;
        datable{1,i}(idx) = 0.5;
        datable{1,i+6}(idx) = 0.5*datable{1,i+3}(idx);
    end
    %check that distance starts at zero
    if datable{1,10}(1)>0
        datable{1,10} = datable{1,10}-datable{1,10}(1);
    end    
end

%%
function [datable,itable] = checkdims(datable,itable)
    %check that the variables in the two tables are the same size and if
    %not pad the short table
    if size(datable{1,1},2)==size(itable{1,1},2), return; end %matches
    
    ndat = size(datable{1,1},2);
    nita = size(itable{1,1},2);
    nrec = nita-ndat;
    danames = datable.Properties.VariableNames;
    darows = datable.Properties.RowNames;
    itnames = itable.Properties.VariableNames;
    itrows = itable.Properties.RowNames;

    if nita>ndat           %if table has longer records, pad datable
        nrow = height(datable);
        addrec = NaN(nrow,nrec);
        myfun = @(X) horzcat(X,addrec);
        datable = varfun(myfun,datable);    
        datable.Properties.VariableNames = danames;
        datable.Properties.RowNames = darows;
    else                   %datable has longer records, pad itable
        addrec = NaN(1,-nrec);
        myfun = @(X) [X,addrec]; 
        itable = varfun(myfun,itable);
        itable.Properties.VariableNames = itnames;
        itable.Properties.RowNames = itrows;
    end
end


