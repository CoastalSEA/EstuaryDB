function hyps = edb_w_hypsometry(obj,uplimit,histint,isplot)
%
%-------function help------------------------------------------------------
% NAME
%   edb_w_hypsometry.m
% PURPOSE
%   compute width hypsometry from grid data
% USAGE
%   hyps = edb_w_hypsometry(grid,uplimit)
% INPUTS
%   obj - handle to class instance for EDBimport 
%   uplimit - upper limit for determining surface areas
%   histint - vertical interval for histogram
%   isplot - generate plot of surface area and volume (optional)
% OUTPUT
%   hypsdst - zcentre, zhist, zsurf, zvol as a matrix with dimensions of z
%            zcentre: vertical elevation of interval mid-point
%            zhist: plan area for each interval (zsurf is cumulative total)
%            zsurf: surface plan area for each interval
%            zvol: cumulative volumes below each interval
% NOTES
%   compute histogram of surface area and volume from a grid
% SEE ALSO
%   similar to gd_basin_hypsometry, bathy_hypsometry and multi_hypsometry
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2025
%--------------------------------------------------------------------------
%    
    if nargin<4, isplot = false; end

    slines = obj.Sections.XSections;
    cumlen = obj.Sections.ChannelProps.ChannelLengths;

    idN = find(isnan(slines.x));
%     delx = abs(grid.x(2)-grid.x(1));
%     dely = abs(grid.y(2)-grid.y(1));
%     % range for histogram data - general
%     lowlimit = floor(min(min(grid.z)));   
%     zedge = lowlimit:histint:uplimit;
%     zedge(zedge>(uplimit+histint)) = [];
%     % calculate histogram and format output
%     zed  = reshape(grid.z,numel(grid.z),1);
%     zhist = histcounts(zed,zedge); %bin counts for each interval defined by zedge
%     zhist = zhist*delx*dely;     %scale occurences by grid cell area
%     zsurf = cumsum(zhist);
%     zvol = zsurf*histint;        %volume of each slice
%     zvol = cumsum(zvol);         %cumulative volume below each elevation
%     zcentre = movsum(zedge,[0,1])/2;
%     zcentre(end) = [];
%     hyps  = {zcentre',zhist',zsurf'}; 
    
    if isplot
        hyps_plot(hyps)
    end
end
%%
function hyps_plot(hyps)
    %genereate plot of the surface area and volume as a function of z
    hf = figure('Name','Hypsometry','Resize','on','Tag','PlotFig');                                           
    ax = axes(hf);
    W = hyps{3};
    x = hyps{1};
    z = hyps{2};
    %create props to define labels for each variable to be plotted
    [X,Z] = meshgrid(x,z);
    contourf(ax,X,Z,W')
    colormap('parula')
    hc = colorbar;
    hc.Label.String = 'Width';
    xlabel('Distance to mouth (m)')
    ylabel('Elevation (mAD)')
end