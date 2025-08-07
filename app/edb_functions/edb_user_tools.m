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
    listxt = {'Table figure','Hydraulic properties','Empirical properties',...
              'Convergence table','Export convergence table'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Table figure'
                get_dataTable(mobj);
            case 'Hydraulic properties'
                edb_hydraulic_props(mobj);
            case 'Empirical properties'
                edb_empirical_props(mobj);
            case 'Convergence table'
                get_ConvergenceTable(mobj);
            case 'Export convergence table'
                exportTable(mobj);
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

function get_ConvergenceTable(mobj)
    %add convergence analysis results as a dataset to existing case
    getdialog('This option is specific to along-channel vector datasets')
    muicat = mobj.Cases;                      %handle to model catalogue
    
    promptxt = 'Select case(s) to analyse for convergence:';
    [caserec,ok] = selectCase(muicat,promptxt,'multiple',2,true);
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
        if ~isvector(cobj.Data.(datasetname)(1,1)), dst(i) =[]; end
    end
    if isempty(dst), return; end

    cnvdst = edb_convergence_analysis(dst);
    anobj = muiTableImport;  
    %suggest output description but allow user to edit
    setDataSetRecord(anobj,muicat,cnvdst,'model',{'Convergence analysis'},false); 
end

%%
function exportTable(mobj)
    %export a convergence table to a spreadsheet or text file
    muicat = mobj.Cases;                      %handle to model catalogue
    promptxt = 'Select case to export:';
    [caserec,ok] = selectCase(muicat,promptxt,'single',2,true);
    if ok<1, return; end
    [cobj,~] = getCase(muicat,caserec(1));    %find first case instance
    datasetname = selectDataset(muicat,cobj); %assume all selected cases
    if isempty(datasetname), return; end      %use same dataset name
    dst = cobj.Data.(datasetname);     %datasets to be included in output
    
    %get location and name of output file
    promptxt = {'File path:','Filename for convergence file:',...
                'File extension (txt or xlsx)'};
    inp = inputdlg(promptxt,'convergence',1,{pwd,'convergence_table','xlsx'});    
    if isempty(inp), return; end
    dimnames = dst.DimensionNames;
    dim1 = dst.Dimensions.(dimnames{1});
    dim2 = dst.Dimensions.(dimnames{2});
    idz = listdlg('PromptString','Select water level:',...
                  'SelectionMode','single','ListString',dim2);
    filename = [inp{1},'\',inp{2},'_',dim2{idz},'.',inp{3}];
    
    %write data to file. If Excel seperate data into area, widht and depth
    if strcmp(inp{3},'txt')
        subtable = getDataTable(dst,'Dimensions.WL',dim2{idz});                 
        writetable(subtable,filename,'WriteRowNames',true);
    else       
        for j=1:3
            %NB hard code dimension names as test****
            subtable = getDataTable(dst,'Dimensions.Var',dim1{j},...
                'Dimensions.WL',dim2{idz});        
            writetable(subtable,filename,'WriteRowNames',true,...
                                                       'Sheet',dim1{j});
        end
    end
    getdialog(sprintf('Data written to %s',filename))
end




