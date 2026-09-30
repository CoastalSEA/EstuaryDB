function edb_user_bespoke_tools(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_bespoke_tools.m
% PURPOSE
%   user function to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_user_bespoke_tools(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined
% NOTES
%   called by edb_user_tools as part of EstuaryDB App.
% SEE ALSO
%   edb_empirical_props_multi.m, edb_ukdb__analytical_solutions.m,
%   edb_ukws__analytical_solutions.m
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2025
%--------------------------------------------------------------------------
%   
    listxt = {'UK-WS regressions','UK ERP+ZM analytical',...
                                'UK-WS analytical','Estuary-Inlet'};
    
    selection = listdlg("ListString",listxt,"PromptString",...
                        'Select option:','SelectionMode','single',...
                        'ListSize',[150,120],'Name','EDBtools');
    if isempty(selection), return; end

    %bespoke code function call    
    switch listxt{selection}
        case 'UK-WS regressions'
            % UK-WS regressions for empirical and analytical relationships
            edb_empirical_props_multi(mobj);
        case 'UK ERP+ZM analytical'
            edb_ukdb_analytical_solutions(mobj);
        case 'UK-WS analytical'
            edb_ukws_analytical_solutions(mobj);
        case 'Estuary-Inlet'
            edb_estinlet_analytical_solutions(mobj);
    end
end