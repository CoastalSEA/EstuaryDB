function edb_regression_plot(obj,datasetname)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_regression_plot.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_regression_plot(obj)
% INPUTS
%   obj - selected case to use for plot
%   datasetname - selected dataset name
% OUTPUT
%   
% NOTES
%    selected case must have variables that use the ZM SeaZone data set
%    conventions, with variables named:
%    'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'
% SEE ALSO
%   EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%
    d = obj.Data.(datasetname);    
    casedesc = d.Description;
    h_pan = panelFigure('Convergence plots',casedesc);    
    lab.x = 'Distance from mouth (km)';
    %lab.leg = {'Low water','Mean tide','High water'};
    lab.leg = {'LW','MT','HW'};
    res = table;
    
    ax1 = subplot(2,2,2,'Parent',h_pan);
    lab.y = 'Width (m)';
    res = getsubplot(ax1,d.xCh,[d.wLW,d.wMT,d.wHW],lab,res);
    %title(ax1,casedesc);
    
    ax2 = subplot(2,2,3,'Parent',h_pan);
    lab.y = 'Cross-section area (m^2)';
    res = getsubplot(ax2,d.xCh,[d.aLW,d.aMT,d.aHW],lab,res);
    
    ax3 = subplot(2,2,4,'Parent',h_pan);
    lab.y = 'Hydraulic depth (m)';
    res = getsubplot(ax3,d.xCh,[d.hLW,d.hMT,d.hHW],lab,res);
       
    if any(contains(fieldnames(obj.Data),'image','IgnoreCase',true))
        dsetnames = fieldnames(obj.Data);
        idn = contains(dsetnames,'image','IgnoreCase',true);
        ax4 = subplot(2,2,1,'Parent',h_pan);
        ax4.Position = [0.05,0.5,0.45,0.45];
        estmap =  obj.Data.(dsetnames{idn}).DataTable{1,1};
        image(ax4,estmap{1})
        axis equal
        axis off
        set(ax4,'XTickLabel','','YTickLabel','')
    end
    
    %add a summary line to res to ease creation of consolidated data set
    res = [res;{res{1,1}/1000,res{2,2},res{2,3},res{2,4},res{5,2},...
                                                        res{5,3},res{5,4}}];    
    res.Properties.VariableNames = {'Lobs','v0obs','v0','Lv','vR2',...
                                                       'v_mean','v_sdev',};
    res.Properties.RowNames = {'wLW','wMT','wHW','aLW','aMT','aHW',...
                                                   'hLW','hMT','hHW','sum'};
end

%%
function res = getsubplot(ax,x,y,labels,res)
    %generate subplot
    markers = {':k','-.k','--k'};
    maxy = max(max(y))*1.1;
    hold on
    for i=1:size(y,2)
        plot(ax,x/1000,y(:,i));
        ylim([0,maxy]);
        [a,b,Rsq,ex,ey,~] = regression_model(x,y(:,i),'Exponential');
        hp = plot(ax,ex/1000,ey,markers{i});
        set(get(get(hp,'Annotation'),'LegendInformation'),...
                    'IconDisplayStyle','off'); % Exclude line from legend
        labels.leg{i} = sprintf('%s: a=%-3.2e, b=%-3.2e, R^2=%-3.2g',...
                                                labels.leg{i},a,1/b,Rsq); 
        res = [res;{x(end)-x(1),y(1,i),a,1/b,Rsq,mean(y(:,i)),std(y(:,i))}];                                 
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
function h_pan = panelFigure(plotname,titletxt)
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
end