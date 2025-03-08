function edb_hypsometry_plots(mobj)                       
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
listxt = {'Convergence plot'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Convergence plot'
                get_ConvergencePlot(mobj); %calls edb_regression_plot
        end
    end
end

%%
% Default functions can be found in muitoolbox/psfunctions folder
% function: scatter_plot(mobj)
% function: type_plot(mobj)

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

%% additional functions here or external-----------------------------------

%     %multiple selection returning 2 variables each with 3 selections for
%     %upper, central and lower values of a variable
%     [select,set] = multivar_selection(mobj,varnames,promptxt,1,... %muitoolbox function
%                        'XYZnset',3,...                             %minimum number of buttons to use for selection
%                        'XYZmxvar',[1,1,1],...                      %maximum number of dimensions per selection button, set to 0 to ignore subselection
%                        'XYZpanel',[0.05,0.2,0.9,0.3],...           %position for XYZ button panel [left,bottom,width,height]
%                        'XYZlabels',{'Upper','Central','Lower'});   %default button labels 


% function [select,set,dst] = xy_select(mobj)
%     %code to select a X and Y vectors and check they are same length
%     varnames = {'Var'};
%     promptxt = {'Select variables:'};
%     %multiple selection returning 1 variable set with 2 selections for
%     %X and Y values to use
%     ok = 0;
%     while ok<1   %need to ensure same number of rows in each variable
%         [select,set] = multivar_selection(mobj,varnames,promptxt,0,... %muitoolbox function
%                        'XYZnset',2,...                             %minimum number of buttons to use for selection
%                        'XYZmxvar',[1,1,1],...                      %maximum number of dimensions per selection button, set to 0 to ignore subselection
%                        'XYZpanel',[0.05,0.2,0.9,0.3],...           %position for XYZ button panel [left,bottom,width,height]
%                        'XYZlabels',{'X','Y'});                     %default button labels
%         if length(select.Var(1).data)==length(select.Var(2).data)            
%             ok = 1;          %same number of rows in each variable
%         end
%     end
%     %retrieve the dstable used for the X variable
%     cobj = getCase(mobj.Cases,set.Var(1).caserec);
%     dst = cobj.Data.(select.Var(1).dset);
% end








