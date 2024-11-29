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
    [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,{'data'},...
                                  {'EDBimport','muiTableImport'},promptxt);
    if isempty(cobj), return; end
    dst = cobj.Data.(datasets{idd});
    titletxt = sprintf('Data for %s(%s)',dst.Description,datasets{idd}); 

    %generate table
    table_figure(dst,titletxt)
end

%% additional functions here or external-----------------------------------

function get_ConvergenceAnalysis(mobj)
    %add convergence analysis results as a dataset to existing case
    getdialog('This option is specific to along-channel vector datasets')
    muicat = mobj.Cases;                      %handle to model catalogue
    
    promptxt = 'Select case(s) to analyse for convergence:';
    [caserec,ok] = selectCase(muicat,promptxt,'multiple',1,true);
    if ok<1, return; end
    [cobj,~] = getCase(muicat,caserec(1));    %find first case instance
    if isempty(cobj), return; end
    datasetname = selectDataset(muicat,cobj); %assume all selected cases
    if isempty(datasetname), return; end      %use same dataset name
    nrec = length(caserec);
    
    [cobj,~] = getCase(muicat,caserec(1));
    dst(1,nrec) = cobj.Data.(datasetname);    %pre-allocate memory for dst array
    for i=1:nrec
        [cobj,~] = getCase(muicat,caserec(i));
        dst(i) = cobj.Data.(datasetname);     %datasets to be included in output
        %check that data is vector
        if ~isvector(dst(i).xCh), dst(i) =[]; end
    end
    
    cnvdst = edb_regression_analysis(dst);
    anobj = muiTableImport;  
    %suggest output description but allow user to edit
    setDataSetRecord(anobj,muicat,cnvdst,'model',{'Convergence analysis'},false); 
end





