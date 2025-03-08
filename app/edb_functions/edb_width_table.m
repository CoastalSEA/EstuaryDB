function [obj,isok] = edb_width_table(obj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_width_table.m
% PURPOSE
%   use pre-defined cross-sections to compute the widthy hypsometry
% USAGE
%   obj = edb_width_table(obj);
% INPUTS
%   obj - handle to class instance for EDBimport
% OUTPUT
%   obj - handle to updated class instance for EDBimport
%   isok - logical true if output added, false if user cancelled
% NOTES
%   compute histogram of width from defined sections and save to a dstable
% SEE ALSO
%   uses the same output format as the edb_w_hyps_format which is also
%   called from EDBimport to create the same dataset.  
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2025
%--------------------------------------------------------------------------
%
    if isempty(obj.Sections) 
        warndlg('No Sections. Use Setup>Sections to create a set of cross-setions'); 
        isok = 0; return; 
    end

    %check whether existing table is to be overwritten or a new table created
    datasetname = setEDBdataset(obj,'Width');

    %get the user to define the upper limit to use for the hypsomety
    slines = obj.Sections.XSections;
    if isempty(slines)
        warndlg('Cross-sections have not been defined')
        return
    end

    uplimit = {num2str(max(slines.y)),'0.1'};
    inp = inputdlg({'Upper limit for hypsometry (mAD):','Vertical interval (m)'},...        
                                                    'EDBhyps',1,uplimit);
    uplimit = str2double(inp{1});
    histint = str2double(inp{2});    

    %compute the hypsometry
    [Est,Rch] = edb_w_hypsometry(obj,uplimit,histint,true); %logical true generates plot
    nreach = length(Rch);
   
    %write results to a dstable and update class instance
    fnames = fieldnames(obj.Data);
    estuaryname = obj.Data.(fnames{1}).Description;
    W = reshape(Est.W,1,size(Est.W,1),[]);
    for i=1:nreach
        Wr{i} = reshape(Rch(i).Wr,1,[],length(Est.Z));
        Xr{i} = Rch(i).Xr;
    end
    dsp = setDSproperties(nreach); 
    dst = dstable(W,Wr{:},'RowNames',{estuaryname},'DSproperties',dsp);
    dst.Dimensions.X = Est.X;
    dst.Dimensions.Z = Est.Z;
    dst.UserData.Xr = Xr;                   %store reach distances
    dst.Description = estuaryname;
    dst.Source = sprintf('Calculated using %s bathymetry',estuaryname);
    dst.MetaData = sprintf('Use sections to upper limit of %.2f with interval of %.2f',uplimit,histint);
    obj.Data.(datasetname) = dst;
    isok = 1;
end
%%
function dsp = setDSproperties(nr)
    %define the variables and metadata properties for the dataset
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique
    %struct entries are cell arrays and can be column or row vectors
    var = {'W'}; desc = {'Estuary widths'};
    for i=2:nr+1
        var{i,1} = sprintf('Wr%d',i-1);
        desc{i,1} = sprintf('Reach %d widths',i-1);
    end

    dsp.Variables = struct(...                      
        'Name',var(:)',...
        'Description',desc(:)',...
        'Unit',repmat({'m'},1,nr+1),...
        'Label',repmat({'Width (m)'},1,nr+1),...
        'QCflag',repmat({'data'},1,nr+1)); 
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