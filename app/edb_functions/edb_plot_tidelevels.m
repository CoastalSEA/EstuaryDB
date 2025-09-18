function ax = edb_plot_tidelevels(ax,tlevels,islegend)
%
%-------function help------------------------------------------------------
% NAME
%   edb_plot_tidelevels.m
% PURPOSE
%   add the high, mean and low water tide levels to a plot
% USAGE
%   ax = edb_plot_tidelevels(ax,tlevels);
% INPUTS
%   ax - handle to plot axes
%   tlevels - dstable with the tidal levels to be used
%   islegend - true to include line names in legend
% OUTPUTS
%   ax - handle to plot axes 
% NOTES
%   if the number of tidal levels in the table is even the central value is
%   based on rounding.
% SEE ALSO
%   edb_w_hyps_format, edb_s_hyps_format,
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2025
%--------------------------------------------------------------------------
%
    if nargin<3, islegend = true; end      

    if width(tlevels)==9        %HAT,MHHW,MHW,MLWW,MTL,MHLW,MLW,MLLW,LAT
        idx = [2,5,8];     
    elseif width(tlevels)==3    %HW,MTL,LW
        idx = 1:3;         
    else                        %any eg: HAT,MHWS,MHWN,MTL,MLWN,MLWS,LAT
        nrec = width(tlevels);
        idx = 1:nrec;       
        idx = [2,round(median(idx)),idx(end-1)];  %offset if nrec even
    end
    [z,ztxt] = setlevels(tlevels,idx);

    %add lines to plot
       glines = {'-.','--','-.'};
       if contains(class(ax.Children),'Contour')
           clr = {'c','m','c'};
       else
           clr = {'k','b','k'};
       end
    hold on
    
    fixlim = xlim;       %fix x-limits
    if abs(ax.YLim(2)-z(1))<0.1
        ax.YLim(2) = z(1)+0.1;    %add offset to y axis
    end

    for i=1:3
        p1 = plot(ax,fixlim,z(i)*[1,1],'LineStyle',glines{i},'LineWidth',0.2,...
                 'Color',clr{i},'Tag','tlevels','DisplayName',ztxt{i},...
                 'ButtonDownFcn',@godisplay);
        if ~islegend
            p1.Annotation.LegendInformation.IconDisplayStyle = 'off'; 
        end
    end
    hold off
end

%%
function [z,ztxt] = setlevels(tlevels,idx)
    %set 3 levels to plot
    varnames = tlevels.VariableNames;
    z = zeros(1,3);
    ztxt = cell(1,3);
    tlevels = activatedynamicprops(tlevels, varnames(idx));
    for i=1:3
        z(i) = tlevels.(varnames{idx(i)});
        ztxt{i} = varnames{idx(i)};
    end
end