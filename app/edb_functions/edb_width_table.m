function obj = edb_width_table(obj)
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
        obj = []; return; 
    end

    %check whether existing table is to be overwritten or a new table created
    datasetname = setEDBdataset(obj,'Width');

    %get the user to define the upper limit to use for the hypsomety
    slines = obj.Sections.XSections;
    uplimit = {num2str(max(slines.y)),'0.1'};
    inp = inputdlg({'Upper limit for hypsometry (mAD):','Vertical interval (m)'},...        
                                                    'EDBhyps',1,uplimit);
    uplimit = str2double(inp{1});
    histint = str2double(inp{2});    

    %compute the hypsometry
    hyps = edb_w_hypsometry(obj,uplimit,histint,true); %logical true generates plot
    %write results to a dstable and update class instance
    dst = dstable(hyps(:,3)','RowNames',{estuaryname},'DSproperties',setDSproperties);
    dst.Dimensions.X = 1;
    dst.Dimensions.Z = hyps(:,1);
    dst.Description = estuaryname;
    dst.Source = sprintf('Calculated using %s bathymetry',estuaryname);
    dst.MetaData = metatxt;
    obj.Data.(datasetname) = dst;
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