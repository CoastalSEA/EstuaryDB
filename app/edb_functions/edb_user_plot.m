function edb_user_plots(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_plots.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_user_plots(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined plot or other output
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_user_tools.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%  
listxt = {'Scatter plot','Type plot','Geyer-McCready plot','Convergence plot'};  %<< edit list, cases and function calls below as required
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Scatter plot'
                sample_plot(mobj);
            case 'Type plot'
                get_typePlot(mobj);
            case 'Geyer-McCready plot'
                get_GMplot(mobj);
            case 'Convergence plot'
                get_ConvergencePlot(mobj);
        end
    end
end

%%
function sample_plot(mobj)
    %prompt user to select variables to be used in plot
    promptxt = 'Select X-variable:';    
    indvar = get_variable(mobj,promptxt);
    promptxt = 'Select Y-variable:';    
    depvar = get_variable(mobj,promptxt);
    if isempty(indvar) || isempty(depvar), return; end  

    isvalid = checkdimensions(indvar.data,depvar.data);
    if ~isvalid, return; end
    
    %now do something with selected data
    %indvar and depvar are structs with the following fields:
    %name - variable name, data - selected data, label - variable axis label, 
    %desc - case description
    figure('Tag','UserFig');
    scatter(indvar.data,depvar.data,'DisplayName',depvar.name)
    xlabel(indvar.label)
    ylabel(depvar.label)
    legend('Location','best')
    title(sprintf('%s v %s',depvar.desc,indvar.desc))
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
    
    if isnumeric(typevar)
        %find set of unique index values
        types = unique(typevar);
    elseif ischar(typevar{1}) || isstring(typevar{1})
        %if char or string convert to categorical and ordinal
        typevar = categorical(typevar,'Ordinal',true);    
        types = categories(typevar);
    end
    ntypes = length(types);

    %set color map to identify each type
    mycolormap = cmap_selection();  %prompts user to select a colormap
    ncolor = size(mycolormap,1);
    %subsample the colormap for the number of types required
    custom_colormap = colormap(mycolormap(1:round(ncolor/ntypes):ncolor,:));

    %adjust bar face color to class colors
    ax = gca;
    hb = findobj(ax.Children,'Type','bar');
    hb.FaceColor = 'flat';
    for k = 1:size(typevar)
        %assign color to variable bar based on typevar
        hb.CData(k,:) = custom_colormap(types==typevar(k),:);
    end
    cb = colorbar;
    cb.Ticks = (0.5:1:length(types)-0.5)/ntypes;
    if isnumeric(types)
        cb.TickLabels = num2str(types);  %unique index numbers
    else
        cb.TickLabels = types;           %categories
    end
    cb.Label.String = vardesc{idv};  %add variable description to colorbar
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
    [cobj,classrec] = selectCaseObj(mobj.Cases,[],{'muiTableImport'},promptxt);
    datasets = fields(cobj.Data);
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
        if isempty(idd), return; end
    end
end

%% additional functions here or external-----------------------------------
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
