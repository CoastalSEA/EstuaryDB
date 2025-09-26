function edb_plot_update(src,ax)
%
%-------function help------------------------------------------------------
% NAME
%   edb_plot_update.m
% PURPOSE
%   callback function used to update plots based on slider position for 2
%   tile plot with one or two sliders created using set_slider_figure
% USAGE
%   edb_plot_update(src,ax)
% INPUTS
%   src - 
%   ax - 
% OUTPUT
%   
% NOTES
%   The left and right plots are accessed using the Tags 'lefttile' and
%   'righttile'. The sliders are accessed using the Tags 'slider1' and
%   'slider2'.
% SEE ALSO
%   called in edb_form_plots as part of EstuaryDB. requires figure created 
%   using set_slider_figure
%
% Author: Ian Townend
% CoastalSEA (c) Sept 2025
%--------------------------------------------------------------------------
%       
    sliders = findobj(src.Parent,'Style','slider');

    if length(sliders)==2
        updateXintegralPlot(src,ax);
    else
        updateWidthPlot(src,ax);
    end
end

%%
function updateXintegralPlot(src,ax)
    %sliders control selection of reach to use to intgrate over to create
    %variable for right tile
    s1 = findobj(src.Parent,'Tag','slider1');
    s2 = findobj(src.Parent,'Tag','slider2');
    stxt1 = findobj(src.Parent,'Tag','stxt1');
    stxt2 = findobj(src.Parent,'Tag','stxt2');

    %update selected line
    if strcmp(src.Tag,'slider1')
        if src.Value>s2.Value
            src.Value = s2.Value-100;     %ensure that x1<x2
        end
        hline = findobj(ax,'Tag','x1-distance');
        stxt1.String = sprintf('%.1f km',src.Value/1000);
    else
        if src.Value<s1.Value
            src.Value = s1.Value+100;     %ensure that x1<x2
        end
        hline = findobj(ax,'Tag','x2-distance');
        stxt2.String = sprintf('%.1f km',src.Value/1000);
    end
    hline.XData = [1,1]*src.Value;        %update position line

    %update right tile plot    
    t2 = src.UserData.t2;

    [~,idx1] = min(abs(src.UserData.X-s1.Value));
    [~,idx2] = min(abs(src.UserData.X-s2.Value)); 
    subvar = src.UserData.Var(idx1:idx2,:);       %extract selected variable at distance X
    subvar(isnan(subvar)) = 0;
    XX = src.UserData.X(idx1:idx2);
    for i=1:length(src.UserData.Z)
        xvar(i,1) = trapz(XX,subvar(:,i),1); %#ok<AGROW>
    end

    sline = findobj(t2,'Tag','x1-section');
    sline.XData = xvar;
    t2.XLim = [0,max(xvar)+100];
    ttxt = split(t2.Title.String,'over');
    st1 = split(stxt1.String);
    t2.Title.String = sprintf('%sover %s to %s',ttxt{1},st1{1},stxt2.String);
    %update extend of tide level lines
    tline = findobj(t2,'Tag','tlevels');
    for i=1:3
        tline(i).XData = t2.XLim;
    end
end

%%
function updateWidthPlot(src,ax)
    %single slider controls selection of section to be plotted in right tile
    hline = findobj(ax,'Tag','x1-distance');
    k = src.Value;
    hline.XData = [1,1]*k;
    % ttxt = ax.Title.String;
    % titxt = strsplit(ttxt,'(');
    % title(ax,sprintf('%s (Dist=%.1f km)',titxt{1}(1:end-1),k/1000));

    %update right tile plot
    t2 = src.UserData.t2;
    sline = findobj(t2,'Tag','x1-section');
    [~,idx] = min(abs(src.UserData.X-k));
    xvar = src.UserData.Var(idx,:);       %extract selected variable at distance X
    sline.XData = xvar;
    t2.XLim = [0,max(xvar)+100];
    ttxt = split(t2.Title.String,'at');
    t2.Title.String = sprintf('%sat %.1f km',ttxt{1},k/1000);
    %update extend of tide level lines
    tline = findobj(t2,'Tag','tlevels');
    for i=1:3
        tline(i).XData = t2.XLim;
    end
end
