function edb_user_bespoke_tool(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_bespoke_tool.m
% PURPOSE
%   user function to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_user_bespoke_tool(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined
% NOTES
%   called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2025
%--------------------------------------------------------------------------
%   

    %bespoke code or function call
    edb_empirical_props_multi(mobj);   %user option
end