function edb_tools(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_tools.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_tools(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   
% NOTES
%    
% SEE ALSO
%   EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%     
    listxt = {'Geyer-McCready plot','Convergence plot',...
                                  'Convergence analysis','User plot'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Geyer-McCready plot'
                get_GMplot(mobj);
            case 'Convergence plot'
                get_ConvergencePlot(mobj);
            case 'Convergence analysis'
                get_ConvergenceAnalysis(mobj);
            case 'User plot'
                edb_user_plot(mobj);
        end
    end
end

%%
function get_GMplot(mobj)
    %prompt user to select variables to be used in plot and call 
    %plot function geyer_mccready_plot
    promptxt = 'Select X-variable:';    
    indvar = get_variable(mobj,promptxt);
    promptxt = 'Select Y-variable:';    
    depvar = get_variable(mobj,promptxt);
    if isempty(indvar) || isempty(depvar), return; end  

    isvalid = checkdimensions(indvar.data,depvar.data);
    if ~isvalid, return; end
    
    figure;
    scatter(indvar.data,depvar.data,'DisplayName',depvar.name)
    xlabel(indvar.label)
    ylabel(depvar.label)
    legend('Location','best')
    title(sprintf('%s v %s',depvar.desc,indvar.desc))
end

%%
function get_ConvergencePlot(mobj)
    getdialog('This option is specific to the SeaZone data set')
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select SeaZone type dataset:');
    if isempty(cobj), return; end
    edb_regression_plot(cobj);
end

%%
function get_ConvergenceAnalysis(mobj)
    getdialog('This option is specific to the SeaZone data set')
    [cobj,classrec] = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select SeaZone type dataset:');
    if isempty(cobj), return; end
    cnvdst = edb_regression_analysis(cobj);
    cobj.Data.Analysis = cnvdst;
    %setDataRecord classobj, muiCatalogue obj, dataset, classtype
    updateCase(mobj.Cases,cobj,classrec,true);
end

%%
function isvalid = checkdimensions(x,y)
    %check that the dimensions of the selected data match
    if length(x)==length(y)
        isvalid = true;
    else
        isvalid = false;
    end
    %
    if ~isvalid
        warndlg('Dimensions of selected variables do not match')
    end
end

