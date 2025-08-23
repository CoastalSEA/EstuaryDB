function edb_hydraulic_props(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_hydraulic_props.m
% PURPOSE
%   Functions to derive datasets related to estuary hydraulic properties such
%   as hydraulic depths, prism etc.
% USAGE
%   edb_hydraulic_props(mobj)
% INPUTS
%   mobj - handle to EstuaryDB App
% OUTPUT
%   adds Hydro dataset to the selected muiTableImport instance
% NOTES
%   called from edb_user_tools in EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2024
%--------------------------------------------------------------------------
%
    n1 = 0.5;               %exponent for estimate of La
    n2 = 0.6;               %exponent for estimate of La
    muicat = mobj.Cases;
    
    promptxt = 'Select case to derive additional gross properties:';
    [cobj,classrec,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    if isempty(cobj), return; end
    dst = cobj.Data.(datasets{idd});  %selected dataset
    if ~matches(dst.VariableNames,'Vmlw'), return; end
    Hmlw = dst.Vmlw./dst.Smlw;
    Hmtl = dst.Vmtl./dst.Smtl;
    Hmhw = dst.Vmhw./dst.Smhw;
    Pr = dst.Vmhw-dst.Vmlw;
    PrTr = Pr./dst.TidalRange;
    PrSb = Pr./dst.Smhw;
%     La1 = 0.35*dst.Smhw.^n1.*(1+dst.Smlw./dst.Smhw);
%     La2 = 0.35*dst.Smhw.^n2.*(1+dst.Smlw./dst.Smhw);
%     lamda = sqrt(9.81*Hmtl).*12.4*3600;

    dsp = hydraulic_dsprops(); %set metadata properties
    dvdst = dstable(Hmlw,Hmtl,Hmhw,Pr,PrTr,PrSb,'RowNames',dst.RowNames,...
                                    'DSproperties',dsp);
    
    answer = questdlg('Add dataset to existing case or create a new one?','EDB derived','Add','New','New');
    if strcmp(answer,'Add')
        %to assign as a dataset to the selected case
        dsetname = 'HydroProps';
        if any(contains(datasets,dsetname))
            overwrite = questdlg('Overwrite existing Derived dataset?','EDB derived','Yes','No','Yes');
            if strcmp(overwrite,'No') 
                newname = inputdlg('New name for dataset','EDB derived',1,{[dsetname,'_1']});
                dsetname = newname{1};
            end
        end
        cobj.Data.(dsetname) = dvdst;
        updateCase(muicat,cobj,classrec,true); %true is to include message
    else
        %to assign as a new case use:
        anobj = muiTableImport;
        %suggest output description but allow user to edit
        casetxt = sprintf('Hydraulic properties using %s',dst.Description);
        setDataSetRecord(anobj,muicat,dvdst,'model',{casetxt},false); %true to suppress user prompt
    end
end
%%
function dsp = hydraulic_dsprops()
    %define the variables in the dataset
    dsp = blank_dsprops();
    %variables to be included
    dsp.Variables.Name = {'Hmlw','Hmtl','Hmhw','Pr','PrTr','PrSb'};
    dsp.Variables.Description = {'Depth at Low Water',...
                                 'Depth at Mean Tide',...
                                 'Depth at High Water',...
                                 'Tidal prism',...
                                 'Tidal prism / Tidal range',...
                                 'Tidal prism / Basin area'};
    dsp.Variables.Unit = {'m','m','m','m3','m2','m'};
    dsp.Variables.Label = {'Hydraulic depth (m)',...
                           'Hydraulic depth (m)',...
                           'Hydraulic depth (m)',...
                           'Tidal Prism (m^3)',...
                           'Tidal Prism / Tidal Range (m^2)',...
                           'Tidal Prism / Basin area (m)'};
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
