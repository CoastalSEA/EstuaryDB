function edb_ukws_analytical_solutions(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_ukws_analytical_solutions.m
% PURPOSE
%   bespoke code for UK estuary data to compute analytical solutions and 
%   plot against observations
% USAGE
%   edb_ukws__analytical_solutions(mobj)
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
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
    if ~isfield(mobj.Cases.DataSets.muiTableImport(1).Data,'UKdata') || ...
        ~isfield(mobj.Cases.DataSets.muiTableImport(2).Data,'WSdata')
        hw = warndlg('Bespoke function for the UK_WS_data.mat project');
        waitfor(hw);
        return;
    end

    ukdata = mobj.Cases.DataSets.muiTableImport(1).Data.UKdata;
    ukhydro = mobj.Cases.DataSets.muiTableImport(1).Data.HydroProps;
    ukclass = mobj.Cases.DataSets.muiTableImport(1).Data.UKclass;

    wsdata = mobj.Cases.DataSets.muiTableImport(2).Data.WSdata;
    wshydro = mobj.Cases.DataSets.muiTableImport(2).Data.HydroProps;
    wsclass = mobj.Cases.DataSets.muiTableImport(2).Data.WSclass;

    if strcmp(ukdata.Description,'UK dataset')  %bespoke for UK dataset****
        % remove badly defined estuaries 
        ide = [77,88,145];
        % remove cases with a/h<1 (if required)
        % idx = find(datadst.TidalRange./2./hydrodst.Hmtl>1);
        % ide = sort([ide,idx']);
    else
        ide = [];
    end

    ok = 0;
    while ok<1
        answer = questdlg('Select dataset','Empirical','UK','WS','Quit','UK');
        if strcmp(answer,'UK')        
            [depvar,indvar,plotxt] = edb_get_variables(ukdata,ukhydro,...
                                                          ukclass);
            labels = ukclass.id;
        elseif strcmp(answer,'WS') 
            [depvar,indvar,plotxt] = edb_get_variables(wsdata,wshydro,...
                                                          wsclass);
            labels = wsclass.id;
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