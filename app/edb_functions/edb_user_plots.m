function edb_user_plots(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_plots.m
% PURPOSE
%   user functions to do provide additional bespoke plot options using the 
%   data loaded in EstuaryDB
% USAGE
%   edb_user_plots(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined plot or other output
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_user_tools.m, edb_regression_plot
%   code for scatter and type_plot based on tableviewer_user_plot.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%  
listxt = {'Scatter plot','Type plot','Range plot','Geyer-McCready plot','Convergence plot'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Scatter plot'
                scatter_plot(mobj);    %muitoolbox function
            case 'Type plot'
                type_plot(mobj);       %muitoolbox function
            case 'Range plot'
                range_plot(mobj)
            case 'Geyer-McCready plot'
                get_GMplot(mobj);
            case 'Convergence plot'
                get_ConvergencePlot(mobj); %calls edb_regression_plot
        end
    end
end

%%
% Default functions can be found in muitoolbox/psfunctions folder
% function scatter_plot(mobj)
% function type_plot(mobj)

%% additional functions here or external-----------------------------------
function range_plot(mobj)
    %prompt user to select variables to be used in plot and call 
    %plot function geyer_mccready_plot
    varnames = {'Xvar','Yvar'};
    promptxt = {'Select variables for X-Axis:',...
                'Select variables for Y-Axis:'};
    %multiple selection returning 2 variables each with 3 selections for
    %upper, central and lower values of a variable
    select = multivar_selection(mobj,varnames,promptxt,...       %muitoolbox function
                       'XYZnset',3,...                           %minimum number of buttons to use for selection
                       'XYZmxvar',[1,1,1],...                    %maximum number of dimensions per selection button, set to 0 to ignore subselection
                       'XYZpanel',[0.05,0.2,0.9,0.3],...         %position for XYZ button panel [left,bottom,width,height]
                       'XYZlabels',{'Upper','Central','Lower'}); %default button labels 
    hfig = figure('Name','Range plot','Tag','FigPlot');
    X = [select.Xvar(:).data];
    Y = [select.Yvar(:).data];

    ax = var_range_plot(hfig,X,Y,select.names);    %muitoolbox function
    ax.XLabel.String = select.Xvar(1).label;
    ax.YLabel.String = select.Yvar(1).label;
    ax.Title.String = get_selection_text(select.Xvar(1),0); %0 = case (dataset)
end

%%
function get_ConvergencePlot(mobj)
    getdialog('This option is specific to Along-Channel datasets')
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select Along-Channel dataset:');
    if isempty(cobj), return; end
    datasets = fields(cobj.Data);
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
    end
    edb_regression_plot(cobj,datasets{idd});
end
