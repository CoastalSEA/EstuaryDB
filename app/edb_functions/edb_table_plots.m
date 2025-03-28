function edb_table_plots(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_table_plots.m
% PURPOSE
%   user functions to do provide additional bespoke plot options using the 
%   data loaded as scalar tables in EstuaryDB
% USAGE
%   edb_table_plots(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined plot or other output
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_hypsometry_plots, edb_user_plots
%   code for scatter and type_plot based on tableviewer_user_plot.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%
listxt = {'Scatter plot','Type plot','Range plot','Geyer-McCready plot'};
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
        end
    end
end
%%
% Default functions can be found in muitoolbox/psfunctions folder
% function: scatter_plot(mobj)
% function: type_plot(mobj)

function range_plot(mobj)
    %prompt user to select variables to be used in plot and call 
    %plot function geyer_mccready_plot
    varnames = {'Xvar','Yvar'};
    promptxt = {'Select variables for X-Axis:',...
                'Select variables for Y-Axis:'};
    %multiple selection returning 2 variables each with 3 selections for
    %upper, central and lower values of a variable
    [select,set] = multivar_selection(mobj,varnames,promptxt,1,... %muitoolbox function
                       'XYZnset',3,...                             %minimum number of buttons to use for selection
                       'XYZmxvar',[1,1,1],...                      %maximum number of dimensions per selection button, set to 0 to ignore subselection
                       'XYZpanel',[0.05,0.2,0.9,0.3],...           %position for XYZ button panel [left,bottom,width,height]
                       'XYZlabels',{'Upper','Central','Lower'});   %default button labels 
    hfig = figure('Name','Range plot','Tag','FigPlot');
    X = [select.Xvar(:).data];
    Y = [select.Yvar(:).data];

    islog = strcmp(set.Xvar(1).scale,'Log') | strcmp(set.Yvar(1).scale,'Log'); %only test first selection
    ax = var_range_plot(hfig,X,Y,select.names,[],islog);    %muitoolbox function
    ax.XLabel.String = select.Xvar(1).desc;
    ax.YLabel.String = select.Yvar(1).desc;
    ax.Title.String = get_selection_text(select.Xvar(1),0); %0 = case (dataset)
end

%%
function get_GMplot(mobj)
    %generate figure the matches Figure 6 in Geyer and MacCready, 2014
    %this is bespoke code that uses the variable names as defined in
    %app/example/Estuary_DSproperties.xlsx
    promptxt = 'Select Case to use';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    if isempty(cobj), return; end
    geyer_mccready_plot(cobj,datasets{idd});
end