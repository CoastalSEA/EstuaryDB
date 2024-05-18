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
    listxt = {'Geyer-McCready plot','User plot'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[150,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Geyer-McCready plot'
                set_GMplot(mobj)
            case 'User plot'
                edb_user_plot(mobj);
        end
    end
end
%%
function set_GMplot(mobj)
    %prompt user to select variables to be used in plot and call 
    %plot function geyer_mccready_plot
    promptxt = 'Select X-variable:';    
    indvar = get_variable(mobj,promptxt);
    promptxt = 'Select Y-variable:';    
    depvar = get_variable(mobj,promptxt);
    if isempty(indvar) || isempty(depvar), return; end  

    figure;
    scatter(indvar.data,depvar.data,'DisplayName',depvar.name)
    xlabel(indvar.label)
    ylabel(depvar.label)
    legend('Location','best')
    title(sprintf('%s v %s',depvar.desc,indvar.desc))
end


