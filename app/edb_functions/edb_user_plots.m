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
%   EstuaryDB and edb_table_plots, edb_hypsometry_plots
%
% Author: Ian Townend
% CoastalSEA (c) Mar 2025
%--------------------------------------------------------------------------
%  
listxt = {'User plot 1','User plot 2'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'User plot 1'

                muiPlotsObj = muiPlots.get_muiPlots();
%--------------------------------------------------------------------------
% Plot implementation - see muiPlots.m for existing examples of different 
% types of plot. An instance of muiPlots is passed as obj and contains the
% user selection in UIsel and UIset, along with the Data, Labels, Legend
% text, etc (see properties of muiPlots).% 
%--------------------------------------------------------------------------                
                user_plot(muiPlotsObj,mobj);   %default muitoolbox template
            case 'User plot 2'
                %plot as defined below
                my_user_plot(mobj);   
        end
    end
end

%%
function my_user_plot(mobj)
    %user defined plot using data held in cases in mobj.Cases
end
