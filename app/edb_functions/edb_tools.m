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
    listxt = {'Dataset table','Type plot',...
              'Geyer-McCready plot','Convergence plot',...
                                  'Convergence analysis','User plot'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Dataset table'
                get_dataTable(mobj);
            case 'Type plot'
                get_typePlot(mobj)
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
function get_dataTable(mobj)
    %generate table figure of selected data set
    promptxt = 'Select Case to tabulate';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj,promptxt);
    dst = cobj.Data.(datasets{idd});
    title = sprintf('Data for %s table',datasets{idd});
    desc = sprintf('Source:%s\nMeta-data: %s',dst.Source{1},dst.MetaData);
    tablefigure(title,desc,dst);
end

%%
function get_typePlot(mobj)
    %generate a plot 
    promptxt = 'Select Case to tabulate';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj,promptxt);

    ax.Tag = 'FigButton';                                            
    tabPlot(cobj,ax);  %generate default Qplot figure

        %select variable to use for classification
    dst = cobj.Data.(datasets{idd});
    varnames = dst.VariableNames;
    vardesc = dst.VariableDescriptions;
    
    promptxt = 'Select classification variable:';   
    idv = listdlg('PromptString',promptxt,'ListString',vardesc,...
                            'SelectionMode','single','ListSize',[180,300]);
    if isempty(idv), return; end

    typevar = dst.(varnames{idv});
    types = unique(typevar);
    if length(types)==length(typevar)

    end

    %adjust bar face color to class colors
    ax = gca;
    hb = findobj(ax.Children,'Type','bar');
    custom_colormap = colormap(parula(length(types)));

    hb.FaceColor = 'flat';
    for k = 1:size(typevar)
        hb.CData(k,:) = custom_colormap(types==typevar(k),:);
    end
    cb = colorbar;
    cb.Ticks = (0.5:1:length(types)-0.5)/length(types);
    cb.TickLabels = num2str(types);
    cb.Label.String = vardesc{idv};
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

%%
function [cobj,classrec,datasets,idd] = selectCaseDataset(mobj,promptxt)
    %select case and dataset for use in plot or analysis
    [cobj,classrec] = selectCaseObj(mobj.Cases,[],{'EDBimport'},promptxt);
    datasets = fields(cobj.Data);
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
        if isempty(idd), return; end
    end
end
