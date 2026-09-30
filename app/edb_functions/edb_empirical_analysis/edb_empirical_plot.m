function edb_empirical_plot(indvar,depvar,labels,plotxt)
%
%-------function help------------------------------------------------------
% NAME
%   edb_empirical_plot.m
% PURPOSE
%   plot empirical/analytical relationships
% USAGE
%   edb_empirical_plot(indvar,depvar,labels,plotxt)
% INPUTS
%   depvar - selected dependent variable
%   indvar - selected independent variable
%   labels - labels scatter points with estuary id
%   plotxt - struct for plotting labels
% OUTPUT
%   generates a plot
% NOTES
%   called from EstuaryDB option edb_user_tools>edb_empirical_props 
%   or the edb_user_bespoke_tools options for edb_ukdb__analytical_solutions, 
%   abd edb_ukws__analytical_solutions
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
    isfixed = false; %true forces log-log and no labels
    empirical_plot(indvar,depvar,labels,plotxt,isfixed)
    regressionOutput(indvar,depvar,plotxt);
end

%%
function empirical_plot(x,y,Lid,vartxt,isfixed)
    %plot selected empirical relationship    
    promptxt = 'Change axis scale (Log-y for exponential):';
    if isfixed
        answer = 'Log-Log';
        labels = 'No';    %Bespoke selection        
    else
        answer = questdlg(promptxt,'Log-axes','Linear','Log-Log','Log-y','Log-Log');
        labels = questdlg('Include labels?','Point labels','Yes','No','No');
    end

    %for log plots remove any negative values
    if strcmp(answer,'Log-Log') && (any(x<0) || any(y<0))
        idx = x<0 | y<0; 
        x(idx) = []; y(idx) = [];
    elseif strcmp(answer,'Log-y') && any(y<0)
        idy = y<0; x(idy) = []; y(idy) = [];        
    end

    % if contains(vartxt.xlabel,'length')
    %     x = x./1000;  %convert to km
    % end
    % if contains(vartxt.ylabel,'length')
    %     y = y./1000;  %convert to km
    % end

    %create figure and plot
    hf = figure('Resize','on','Tag','PlotFig');
    ax = axes(hf);
    hold on
    if strcmp(labels,'Yes')
        plot(ax,x,y,'o','Color',"#0072BD",'MarkerSize',11,...
                   'DisplayName',vartxt.varname,'ButtonDownFcn',@godisplay); 
        text(ax,x,y,Lid,'FontSize',6,'HorizontalAlignment','center','Clipping','on');   
    else
        plot(ax,x,y,'x','DisplayName',vartxt.varname,'ButtonDownFcn',@godisplay)
    end
    
    %data range
    mx = minmax(x); 
    my = minmax(y); 
    mm = [min([mx,my]),max([mx,my])];
    ixy = x>0 & y>0;
    if mm(1)==0; mm(1) = min([x(ixy),y(ixy)],[],'all'); end
    if mm(2)>1e20; mm(2) = mm(1); end

    %adjust axes based on user selection
    if strcmp(answer,'Log-Log')
        ax.XScale = 'log';
        ax.YScale = 'log';
        [~,~,~,xp,yp,txtp] = regression_model(x,y,'power',100,false);
    elseif strcmp(answer,'Log-y')
        ax.YScale = 'log';
        [~,~,~,xp,yp,txtp] = regression_model(x,y,'exponential',100,false);
    else
        [~,~,~,xp,yp,txtp] = regression_model(x,y,'power',100,false);
    end
    [~,~,~,xl,yl,txtl] = regression_model(x,y,'linear0',100,false);

    if ~strcmp(answer,'Log-y')
        plot(ax,mm,mm,'--k','DisplayName','1:1','ButtonDownFcn',@godisplay)
    end
    plot(ax,xp,yp,'-.k','DisplayName','Power law fit','ButtonDownFcn',@godisplay)
    plot(ax,xl,yl,':k','DisplayName','Linear (0 intercept)','ButtonDownFcn',@godisplay)

    hold off

    xlabel(vartxt.xlabel)
    ylabel(vartxt.ylabel)
    grid on
    if strcmp(answer,'Log-Log')
        axis equal
        xlim(mm); ylim(mm);
    end

    legend('Location','northwest')
    N = numel(x) - sum(isnan(x)| isnan(y));
    ttext = sprintf('%s (N=%d)',vartxt.title,N);
    title(ttext)
    subtitle(sprintf('Linear: %s\nPower: %s',txtl,txtp))
end

%%
function regressionOutput(x,y,vartxt)
    %write the results to screen
    [~,~,~,~,~,txtp] = regression_model(x,y,'power',100,false);
    [~,~,~,~,~,txtl] = regression_model(x,y,'linear0',100,false);
    txtv = sprintf('%s - %s',vartxt.title,vartxt.varname);
    msg = sprintf('%s : Linear: %s | Power: %s\n',txtv,txtl,txtp);
    fprintf(msg)
end
