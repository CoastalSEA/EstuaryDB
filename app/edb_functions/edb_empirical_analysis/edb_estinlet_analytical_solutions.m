function edb_estinlet_analytical_solutions(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_estinlet__analytical_solutions.m
% PURPOSE
%   bespoke code for a merged set of estuary and inlet data covering the UK
%   and WS to compute analytical solutions and plot against observations
% USAGE
%   edb_estinlet_analytical_solutions(mobj)
% INPUTS
%   mobj - handle to EstuaryDB App
% OUTPUT
%   generates a range of plots
% NOTES
%   called from edb_user_bespoke_tools in EstuaryDB
%   NB: hydraulic properties have to be added to dataset
%   Uses project file UK_WS_data.mat
% SEE ALSO
%   edb_empirical_props - single table call to functions
%   edb_ukws_analytical_solutions - bespoke call to UK and WS datasets
%   functions called include: edb_get_variables.m, edb_empirical_plot.m,
%   edb_modified_variable_functions.m
%   THIS IS RESEARCH CODE AND SHOULD NOT BE USED FOR GENERAL APPLICATIONS
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
    if ~isfield(mobj.Cases.DataSets.muiTableImport.Data,'EIdata')
        hw = warndlg('Bespoke function for the UK_WS_merged.mat project');
        waitfor(hw);
        return;
    end

    eidata = copy(mobj.Cases.DataSets.muiTableImport(1).Data.EIdata);
    ide = find(ismember(eidata.ID,{'UK77','UK88','UK99'}));
    eidata.DataTable(ide,:) = [];

    eihydro = copy(mobj.Cases.DataSets.muiTableImport(1).Data.HydroProps);
    eihydro.DataTable(ide,:) = [];
    eiclass = getDSTable(eidata,[],18:20); 

    idx = ismember(eidata.GeomorType,{'Tidal flat','Tidal inlet'});
    estdata = copy(eidata);
    estdata.DataTable = eidata.DataTable(~idx,:);
    esthydro = copy(eihydro);
    esthydro.DataTable  = eihydro.DataTable(~idx,:);
    estclass = copy(eiclass);
    estclass.DataTable  = eiclass.DataTable(~idx,:);

    inldata = copy(eidata);
    inldata.DataTable  =  eidata.DataTable(idx,:);
    inlhydro = copy(eihydro);
    inlhydro.DataTable  = eihydro.DataTable(idx,:);
    inlclass = copy(eiclass);
    inlclass.DataTable  = eiclass.DataTable(idx,:);
    
    clear eidata eihydri eiclass

    ok = 0;
    while ok<1
        answer = questdlg('Select dataset','Empirical','Estuary',...
                                                 'Inlet','Quit','Estuary');
        if strcmp(answer,'Estuary')        
            [depvar,indvar,plotxt] = edb_get_variables(estdata,esthydro,...
                                                          estclass);
            labels = estclass.ID;
        elseif strcmp(answer,'Inlet') 
            [depvar,indvar,plotxt] = edb_get_variables(inldata,inlhydro,...
                                                          inlclass);
            labels = inlclass.ID;
        else
            ok =1; continue;
        end
        if isempty(depvar) || isempty(indvar), continue; end

        %define point lables use estuary id
        if isnumeric(labels)
            labels = num2str(labels);        %id used for point labels
        end
        
        %remove any estuaries to be excluded
        if ~isempty(ide)
            indvar(ide) = NaN;  %remove estuaries to be excluded
            depvar(ide) = NaN;
        end
        
        %generate plot
        edb_empirical_plot(indvar,depvar,labels,plotxt)
    end
end

%%
    