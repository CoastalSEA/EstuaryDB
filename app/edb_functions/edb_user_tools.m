function edb_user_tools(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_tools.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_user_tools(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   
% NOTES
%   called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%     
    listxt = {'Table figure','Derived gross properties','Convergence analysis'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Table figure'
                get_dataTable(mobj);
            case 'Derived gross properties'
                edb_derived_props(mobj)
            case 'Convergence analysis'
                get_ConvergenceAnalysis(mobj);
        end
    end
end

%%
function get_dataTable(mobj)
    %generate table figure of selected data set
    promptxt = 'Select Case to tabulate';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,[],...
                                             {'muiTableImport'},promptxt);
    dst = cobj.Data.(datasets{idd});
    firstcell = dst.DataTable{1,1};
    if ~isscalar(firstcell) || ...
            (iscell(firstcell) &&...
            ~(iscellstr(firstcell) || isstring(firstcell)) && ...
            ~isscalar(firstcell{1}))
        %not tabular data
        warndlg('Selected dataset is not tabular')
        return; 
    end 
    title = sprintf('Data for %s table',datasets{idd});
    desc = sprintf('Source:%s\nMeta-data: %s',dst.Source{1},dst.MetaData);
    ht = tablefigure(title,desc,dst);
    ht.Units = 'normalized';
    uicontrol('Parent',ht,'Style','text',...
               'Units','normalized','Position',[0.1,0.95,0.8,0.05],...
               'String',['Case: ',dst.Description],'FontSize',10,...
               'HorizontalAlignment','center','Tag','titletxt');
end

%% additional functions here or external-----------------------------------

function get_ConvergenceAnalysis(mobj)
    getdialog('This option is specific to along-channel vector datasets')
    [cobj,classrec] = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select along-channel dataset:');
    if isempty(cobj), return; end
    %check that data is vector


    cnvdst = edb_regression_analysis(cobj);
    %check that Case does not already include a dataset called 'Analysis'
    %if it does prompt for new name or overwrite.
    

    datasetname = 'Analysis';
    cobj.Data.(datasetname) = cnvdst;
    %setDataRecord classobj, muiCatalogue obj, dataset, classtype
    updateCase(mobj.Cases,cobj,classrec,true);
end


