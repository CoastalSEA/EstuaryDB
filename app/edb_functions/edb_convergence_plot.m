function res = edb_convergence_plot(obj,dst)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_convergence_plot.m
% PURPOSE
%   generate a plot of along-channel variation in width, csa and hydraulic
%   depth
% USAGE
%   edb_convergence_plot(obj,dst)
% INPUTS
%   obj - instance of EDBimport class containing Width and tidal level data
%   dst - dstable with the along channel variables at defined elevations
% OUTPUT
%   figure with four subplots of width,csa,depth and section layout
%   res - table of values derived for each plot
% NOTES
%    selected case must have variables that use the ZM SeaZone data set
%    conventions, with variables named:
%    'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'
% SEE ALSO
%   EstuaryDB, edb_convergence_analysis
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%   
    casedesc = sprintf('%s using %s',dst.Description,dst.MetaData);
    [h_pan,h_lbl] = panelFigure('Convergence plots',casedesc);    
    lab.x = 'Distance from mouth (km)';
    %lab.leg = {'Low water','Mean tide','High water'};
    lab.leg = {'LW','MT','HW'};
    res = table;
    xCh = dst.Dimensions.X;
    
    if any(contains(fieldnames(obj.Data),'Grid','IgnoreCase',true)) ||...
        any(contains(fieldnames(obj.Data),'GeoImage','IgnoreCase',true)) 
        pobj = obj.Sections;
        ax = viewPlanSections(pobj,obj,'Layout of Sections',h_pan);
        subplot(2,2,1,ax);
    elseif any(contains(fieldnames(obj.Data),'image','IgnoreCase',true))
        dsetnames = fieldnames(obj.Data);
        idn = contains(dsetnames,'image','IgnoreCase',true);
        ax1 = subplot(2,2,1,'Parent',h_pan);
        ax1.Position = [0.05,0.5,0.45,0.45];
        estmap =  obj.Data.(dsetnames{idn}).DataTable{1,1};
        image(ax1,estmap{1})
        axis equal
        axis off
        set(ax1,'XTickLabel','','YTickLabel','')
    end

    var = {'aLW','aMT','aHW';...
           'wLW','wMT','wHW';...
           'hLW','hMT','hHW'};    
    [n,m] = edb_convergence_limits(xCh,dst,var);

    ax2 = subplot(2,2,2,'Parent',h_pan);
    lab.y = 'Width (m)';
    res = getsubplot(ax2,xCh,[dst.wLW',dst.wMT',dst.wHW'],lab,'Lw',res,n,m);
    %title(ax1,casedesc);
    
    ax3 = subplot(2,2,3,'Parent',h_pan);
    lab.y = 'Cross-section area (m^2)';
    res = getsubplot(ax3,xCh,[dst.aLW',dst.aMT',dst.aHW'],lab,'La',res,n,m);
    
    ax4 = subplot(2,2,4,'Parent',h_pan);
    lab.y = 'Hydraulic depth (m)';
    res = getsubplot(ax4,xCh,[dst.hLW',dst.hMT',dst.hHW'],lab,'Lh',res,n,m);
    
    %add variable names and row names 
    res.Properties.VariableNames = {'Lobs','x0','Lx','v0obs','v0fit','Lconv','R2',...
                                                       'v_mean','v_sdev'};
    res.Properties.RowNames = {'wLW','wMT','wHW','aLW','aMT','aHW',...
                                                   'hLW','hMT','hHW'};
    res.Properties.UserData = struct('Lobs',res.Lobs(1),'x0',res.x0(1),'Lx',res.Lx(1));

    h_lbl.String = sprintf('Lobs = %.1f; x0 = %.1f; Lx = %.1f',...
                                        res.Lobs(1),res.x0(1),res.Lx(1));
    res.Lobs = []; res.x0 = []; res.Lx = []; 
end

%%
function res = getsubplot(ax,x,y,labels,Ltxt,res,n,m)
    %generate subplot
    markers = {':k','-.k','--k'};
    maxy = max(max(y))*1.1;
    hold on
    % Ltxt = ['L',lower(labels.y(1))];  %label for convergence length

    for i=1:size(y,2)
        plot(ax,x/1000,y(:,i));
        ylim([0,maxy]);
        [a,b,Rsq,ex,ey,~] = regression_model(x(n:m)-x(n),y(n:m,i),'Exponential');
        hp = plot(ax,(ex+x(n))/1000,ey,markers{i});
        set(get(get(hp,'Annotation'),'LegendInformation'),...
                    'IconDisplayStyle','off'); % Exclude line from legend
        labels.leg{i} = sprintf('%s: a = %-3.2e, %s = %-3.2e, R^2 = %-3.2g',...
                                                labels.leg{i},a,Ltxt,1/b,Rsq); 
        res = [res;{x(end)-x(1),x(n),x(m)-x(n),y(n,i),a,1/b,Rsq,...
                                            mean(y(n:m,i)),std(y(n:m,i))}];  %#ok<AGROW>
    end
    hold off
    xlabel(labels.x);
    if strcmp(labels.y,'Hydraulic depth (m)')
        ax.YDir = 'reverse';
    end
    ylabel(labels.y);
    legend(labels.leg,'Location','best','FontSize',8);
end

%%
function [h_pan,h_lbl] = panelFigure(plotname,titletxt)
    %create figure and add a panel and title
    hf = figure('Name',plotname,'Units','normalized',...
                                            'Resize','on','Tag','PlotFig');                                       
    hf.Position(1) = 0.1;
    hf.Position(2) = 0.1;
    hf.Position(3) = hf.Position(3)*2;
    hf.Position(4) = hf.Position(4)*2;
    if ~isempty(titletxt)
        h_pan = uipanel('Parent',hf,'BorderType','none'); 
        h_pan.Title = titletxt; 
        h_pan.TitlePosition = 'centertop'; 
        h_pan.FontSize = 12;
        h_pan.FontWeight = 'bold';
    else
        h_pan = hf;
    end
    %create a textbox to hold the subtitle (subtitle not an option with uipanel)
    h_lbl = annotation(h_pan, 'textbox','String', "subtitle", ...
                    'HorizontalAlignment','center','EdgeColor','none');
    h_lbl.FontSize = 10;
    h_lbl.Position = [0,1-h_lbl.Position(4),1,h_lbl.Position(4)];
end