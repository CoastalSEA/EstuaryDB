function edb_derived_props(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_derived_props.m
% PURPOSE
%   Functions to derive datasets related to estuary gross properties such
%   as hydraulic depths, prism etc.
% USAGE
%   edb_derived_props(mobj)
% INPUTS
%   mobj - handle to EstuaryDB App
% OUTPUT
%   adds Derived dataset to the selected muiTableImport instance
% NOTES
%   
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2024
%--------------------------------------------------------------------------
%
muicat = mobj.Cases;    
dsp = derived_dspops(); %set metadata properties
[caserec,ok] = selectCase(muicat,promptxt,mode,selopt,ischeck);


end
%%
function dsp = derived_dspops()
    %define the variables in the dataset
    %define the metadata properties for the demo data set
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique

    %struct entries are cell arrays and can be column or row vectors
    dsp.Variables = struct(...                      
        'Name',{'Hlw','Hmt','Hhw'},...
        'Description',{'Depth at Low Water','Depth at Mean Tide',...
                       'Depth at High Water',},...
        'Unit',{'m','m','m'},...
        'Label',{'Hydraulic depth (m)','Hydraulic depth (m)',...
                 'Hydraulic depth (m)'},...
        'QCflag',repmat({'derived'},1,3)); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{'Location'},...
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
