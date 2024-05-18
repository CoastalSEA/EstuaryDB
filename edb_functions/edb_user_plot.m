function edb_user_plot(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_plot.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_user_plot(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined plot or other output
% NOTES
%    called from edb_tools as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_tools.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%  
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


