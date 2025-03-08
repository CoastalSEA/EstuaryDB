function [Estuary,Reach] = edb_w_hypsometry(obj,zmax,histint,isplot)
%
%-------function help------------------------------------------------------
% NAME
%   edb_w_hypsometry.m
% PURPOSE
%   compute width hypsometry from cross-section data
% USAGE
%   [Estuary,Reach] = edb_w_hypsometry(obj,zmax,histint,isplot)
% INPUTS
%   obj - handle to class instance for EDBimport 
%   zmax - upper limit for determining surface areas
%   histint - vertical interval for histogram
%   isplot - generate plot of surface area and volume (optional)
% OUTPUT
%   Estuary - struct containing compound estuary widths, X and Z
%   Reach - struct array of reach width and distance
% NOTES
%   whole estuary is based on interpolation and summation of reach widths
% SEE ALSO
%   similar to gd_basin_hypsometry, bathy_hypsometry and multi_hypsometry
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2025
%--------------------------------------------------------------------------
%    
    if nargin<4, isplot = false; end

    x = obj.Sections.ChannelProps.ChannelLengths;
    idN = [0,find(isnan(x))];
    nreach = length(idN)-1;

    sections = obj.Sections.XSections;
    zmin = round(min(sections.y),1);
    Z = zmin:histint:zmax;
    
    cplines = gd_plines2cplines(gd_lines2points(sections));
    count = 1;
    for i=1:nreach
        Xr{i} = x(idN(i)+1:idN(i+1)-1);
        nsections = length(Xr{i});        
        for j=1:nsections        
            section = cplines{1,count};
            yi = [section(:).x];
            dely = abs(yi(2)-yi(1));       %grid interval
            zi = [section(:).y];           %depth values
            Dmax{i}(j) = round(min(zi),1);
            for k=1:length(Z)            
                Wr{i}(j,k) = interpWidth(zi,Z(k),dely);     
            end 
            count = count+1;
        end
    end

    %now combine reaches
    mnmx = minmax(x);
    %set up a chainage from mouth to most distant point
    if isfield(obj.Sections.ChannelProps,'cint')
        cint = obj.Sections.ChannelProps.cint;
    else
        cint = PLinterface.setInterval();
        obj.Sections.ChannelProps.cint = cint;
    end
    X =  mnmx(1):cint:mnmx(2);
   
    W = zeros(length(X),length(Z));
    maxW = 0;
    for i=1:nreach
        for k=1:length(Z) 
            [~,idx1] = min(abs(X-Xr{i}(1)));   %index of nearest point
            [~,idx2] = min(abs(X-Xr{i}(end))); 
            xr = X(idx1:idx2);
            wr = interp1(Xr{i},Wr{i}(:,k)',xr,'makima'); %makima extrapolates by default
            W(idx1:idx2,k) = W(idx1:idx2,k)+wr';
            maxW = max(maxW,max(wr));
        end
    end

    %write outputs for whol estuary and reaches
    Estuary = struct('W',W,'X',X,'Z',Z); 
    Reach = struct('Wr',Wr,'Xr',Xr);

    if isplot
        hf = figure('Name','Hypsometry','Resize','on','Tag','PlotFig');
        ax = axes(hf);
        hyps_plot(ax,W,X,Z,'All reaches');
        axis tight
        xlimits = ax.XLim;

        hf = figure('Name','Hypsometry','Units','Normalized','Resize','on','Tag','PlotFig');
        subplot(axes(hf));
        for i=1:nreach
            si = subplot(nreach,1,i);
            titletxt = sprintf('Reach %d',i);
            hyps_plot(si,Wr{i},Xr{i},Z,titletxt);
            si.CLim(2) = ceil(maxW);
            si.XLim = xlimits;
            sgtitle('Reach contribution to widths')
        end
        hf = gcf;
        hf.Position = [0.40,0.28,0.31,0.65];
    end
end

%%
function w = interpWidth(zi,zwl,dely)
    %get the width at distance x and elevation zwl    
    zi(zi>zwl) = NaN;
    w = sum(~isnan(zi)*dely);   %width at zwl
end
%%
function hyps_plot(ax,W,x,z,titletxt)
    %genereate plot of the width as a function of z
    %create props to define labels for each variable to be plotted
    [X,Z] = meshgrid(x,z);
    %W(W>0) = log(W(W>0));
    contourf(ax,X,Z,W')
    colormap('parula')
    hc = colorbar;
%     vals = hc.Ticks;
%     hc.TickLabels = num2str(round(exp(vals),1));
    hc.Label.String = 'Width';
    xlabel('Distance to mouth (m)')
    ylabel('Elevation (mAD)')
    title(titletxt)
end