function [n,m] = edb_convergence_limits(x,dst,var)
%
%-------function help------------------------------------------------------
% NAME
%   edb_convergence_limits.m
% PURPOSE
%   use figure to allow user to define X start and end range
% USAGE
%   [n,m] = edb_convergence_limits(x,dst,var)
% INPUTS
%   x - distance along channel (m)
%   dst - dstable or table of the along channel variable at hw, mt and lw
%   var - cell array of variable names to use (eg var={'aLW','aMT','aHW'};)
% OUTPUT
%   n,m - start and end indices based on input x values
% NOTES
%   called in edb_convergence_analysisand edb_convergence_plot
% SEE ALSO
%   EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2025
%--------------------------------------------------------------------------
%
    n = 1; m = length(x);  %default values

    hf = figure('Name','PlotFig');
    ax = axes(hf);
    hold on
    for i=1:size(var,2)
        plot(ax,x,dst.(var{1,i}),'.-','DisplayName',var{1,i})
    end
    hold off
    xlabel('Distance from mouth')
    ylabel('Area (m^2)')
    legend
    title(dst.Description)

    inp = inputdlg({'Start distance','End distance'},'Range',1,...
                                            {'0',num2str(x(end))});
    if isempty(inp), return; end %use default values - full data set
    xstart = str2double(inp{1});
    xend = str2double(inp{2});
    [~, n] = min(abs(x - xstart));
    [~, m] = min(abs(x - xend));
    delete(hf)
end