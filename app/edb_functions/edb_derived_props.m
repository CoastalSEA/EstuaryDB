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
    
    promptxt = 'Select case to derive addtional gross properties:';
    [cobj,classrec,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    if isempty(cobj), return; end
    dst = cobj.Data.(datasets{idd});  %selected dataset
    Hmlw = dst.Vmlw./dst.Smlw;
    Hmtl = dst.Vmtl./dst.Smtl;
    Hmhw = dst.Vmhw./dst.Smhw;

    dsp = derived_dsprops(); %set metadata properties
    dvdst = dstable(Hmlw,Hmtl,Hmhw,'RowNames',dst.RowNames,'DSproperties',dsp);
    
    answer = questdlg('Add dataset to existing case or create a new one?','EDB derive','Add','New','New');
    if strcmp(answer,'Add')
        %to assign as a dataset to the selected case
        dsetname = 'Derived';
        if any(contains(datasets,dsetname))
            overwrite = questdlg('Overwrite existing Derived dataset?','EDB derive','Yes','No','Yes');
            if strcmp(overwrite,'No') 
                newname = inputdlg('New name for dataset','EDB derive',1,{[dsetname,'_1']});
                dsetname = newname{1};
            end
        end
        cobj.Data.(dsetname) = dvdst;
        updateCase(muicat,cobj,classrec,true); %true is to include message
    else
        %to assign as a new case use:
        anobj = muiTableImport;
        %suggest output description but allow user to edit
        casetxt = sprintf('Derived using %s',dst.Description);
        setDataSetRecord(anobj,muicat,dvdst,'model',{casetxt},false); %true to suppress user prompt
    end
end
%%
function dsp = derived_dsprops()
    %define the variables in the dataset
    dsp = blank_dsprops();
    %variables to be included
    dsp.Variables.Name = {'Hlw','Hmt','Hhw'};
    dsp.Variables.Description = {'Depth at Low Water',...
                                 'Depth at Mean Tide',...
                                 'Depth at High Water'};
    dsp.Variables.Unit = {'m','m','m'};
    dsp.Variables.Label = {'Hydraulic depth (m)',...
                           'Hydraulic depth (m)',...
                           'Hydraulic depth (m)'};
    dsp.Variables.QCflag = repmat({'derived'},1,length(dsp.Variables.Name));
end
%%
function dsp = blank_dsprops()
    %blank metadata properties for the derived data set
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %struct entries are cell arrays and can be column or row vectors
    dsp.Variables = struct(...                      
        'Name',{''},...
        'Description',{'',},...
        'Unit',{''},...
        'Label',{''},...
        'QCflag',{''}); 
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
