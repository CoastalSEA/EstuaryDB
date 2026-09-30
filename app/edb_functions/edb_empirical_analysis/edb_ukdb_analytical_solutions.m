function edb_ukdb_analytical_solutions(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_ukdb_analytical_solutions.m
% PURPOSE
%   bespoke code for UK estuary data to compute analytical solutions and 
%   plot against observations
% USAGE
%   edb_ukdb_analytical_solutions(mobj)
% INPUTS
%   mobj - handle to EstuaryDB App
% OUTPUT
%   generates a range of plots
% NOTES
%   called from edb_user_tools in EstuaryDB
%   NB: hydraulic properties have to be added to dataset
%   Uses project file ERP_ZM_cf.mat
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

    if ~isfield(mobj.Cases.DataSets.muiTableImport(1).Data,'ERPdata') || ...
        ~isfield(mobj.Cases.DataSets.muiTableImport(2).Data,'ZMdata')
        hw = warndlg('Bespoke function for the ERP_ZM_cf.mat project');
        waitfor(hw);
        return;
    end

    erpdata = mobj.Cases.DataSets.muiTableImport(1).Data.ERPdata;
    erphydro = mobj.Cases.DataSets.muiTableImport(1).Data.HydroProps;
    zmdata = mobj.Cases.DataSets.muiTableImport(2).Data.ZMdata;
    zmhydro = mobj.Cases.DataSets.muiTableImport(2).Data.HydroProps;
    eclass = mobj.Cases.DataSets.muiTableImport(3).Data.ERPclass;

    %option to remove selected estuaries from the dataset
    % answer = questdlg('Mask dataset','Mask','Yes','No','Yes');
    % if strcmp(answer,'Yes')
    %     estdesc = datadst.RowNames;
    %     ide = listdlg("ListString",estdesc,"PromptString",'Select estuaries to omit:',...
    %                   'SelectionMode','multiple','ListSize',[160,200],...
    %                   'Name','EDBtools');
    % else
    %     ide = [];
    % end
    ide = [];
    %cases used in Dronkers analysis which used measured convergence
    %lengths and Smhw from the ERP db and not the ZM data set
    % incl = [7	23	34	76	77	81	86	96	100	106	107	108	109	110	111	112	114	117	119	128	129	130	131	132	133	134	136	137	138	139	140	144	146	147	150	151	153	154	155];
    % ide = ~ismember(eclass.id,incl');
    

    qrdata = getDSTable(erpdata,[],13:18);  %add discharge data to ZM
    zmdata = activatedynamicprops(horzcat(zmdata,qrdata));

    lwdata = getDSTable(zmdata,[],[13,18]); %add convergenve length to ERP
    erpdata = activatedynamicprops(horzcat(erpdata,lwdata)); 

    ok = 0;
    while ok<1
        answer = questdlg('Select dataset','Empirical','ERP','ZM','Quit','ERP');
        if strcmp(answer,'ERP')        
            [depvar,indvar,plotxt] = edb_get_variables(erpdata,erphydro,...
                                                          eclass);
        elseif strcmp(answer,'ZM')  
            [depvar,indvar,plotxt] = edb_get_variables(zmdata,zmhydro,...
                                                          eclass);
        else
            ok =1; continue;
        end
        if isempty(depvar) || isempty(indvar), continue; end

        %define point lables use estuary id
        labels = eclass.id;
        if isnumeric(labels)
            labels = num2str(labels);        %id used for point labels
        end
        
        %remove any estuaries to be excluded
        idi = false(size(depvar));
        idi(ide) = true;
        idn = indvar<0 | depvar<0;
        idi = idi | idn;
        if ~isempty(idi)
            indvar(idi) = NaN;  %remove estuaries to be excluded
            depvar(idi) = NaN;
        end
        % nrec = sum(~isnan(depvar));
        % plotxt.title = sprintf('%s (N=%d)',zmdata.Description,nrec);      
        %generate plot
        edb_empirical_plot(indvar,depvar,labels,plotxt)
    end
end    