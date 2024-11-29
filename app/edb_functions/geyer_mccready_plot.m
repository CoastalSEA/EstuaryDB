function geyer_mccready_plot(x,y,tabledata,inp)
%
%-------function help------------------------------------------------------
% NAME
%   geyer_mccready_plot.m
% PURPOSE
%   create at 
% USAGE
%   geyer_mccready_plots(dst)
% INPUTS
%   
% OUTPUT
%   
% NOTES
%   generate figure the matches Figure 6 in Geyer W R and MacCready P, 
%   2014, The Estuarine Circulation. Annual Review of Fluid Mechanics, 
%   46 (1), 175-197
% SEE ALSO
%   EstuaryDB, called from edb_user_tools
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%     



    
    %get Frf and M parameters
    [x,y,inp] = getPlotVariables(x,y,tabledata,inp);
    mxx = max(max(x)); mnx = min(min(x));
    mxy = max(max(y)); mny = min(min(y));
    %xy1 = [min(mnx,mny),max(mxx,mxy)]; 
    
    hf = figure('Name','GMcC-diagram','Units','normalized', ......
                'Resize','on','HandleVisibility','on', ...
                'Tag','PlotFig');
    ax = getGMfig(hf);
    
    rn = tabledata.Properties.RowNames;
    hold on
    ax = rangeplot(ax,x,y,rn);
    hold off

    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    xlim([mnx,mxx]);
    ylim([mny,mxy]);
    xlabel(replace(inp.xvar,'_',' '));
    ylabel(replace(inp.yvar,'_',' '));
    legend({'low-mean-high','no flow data'},'Location','best');     
end
%%
function [M,Frf,inp] = getPlotVariables(x,y,tabledata,inp)
    %modify flow and tidal range to Froude no. Frf, and mixing parameter, M
    %define constants
    g = 9.81;                   %acceleration due to gravity
    cD = 0.002;                 %friction coefficient    
    beta = 0.00077;             %density coefficient
    s = 34;                     %ocean sainity
    omega = 2*pi()/(12.4*3600); %tidal angular frequency
    
    %scaling variables
    vHW = tabledata.HWvolume;
    vLW = tabledata.LWvolume;
    sHW = tabledata.HWarea;
    sLW = tabledata.LWarea;
    aMT = tabledata.Xsect_area;
    wMT = tabledata.Mouth_width;
    
    %derived parameters
    H = (vHW+vLW)./(sHW+sLW);  %average hydraulic depth
    H = 1.5*(vHW+vLW)./(sHW+sLW);  %hydraulic depth at mouth Ho=H.Lw/La
    NoH = sqrt(beta*g*s*H);    %factor for Frf and M
    P = (sHW+sLW)/2.*x;        %tidal prism
    
    isarea = true;
    
    if isarea
        A = aMT;               %csa at mouth
        atxt = "Amtl";
    else
        A = wMT.*H;            %csa at mouth based on width and av.depth
        atxt = "Wmtl.H";
    end

    Ur = y./A;
    Ut = omega*P./2./A;
    inp.xvar = sprintf('M using %s+%s',inp.xvar,atxt);
    inp.yvar = sprintf('Frf using %s+%s',inp.yvar,atxt);
    
    Frf = Ur./NoH;
    M = (cD/omega./NoH./H).*Ut.^2;    
end
%%
function ax = rangeplot(ax,X,Y,estnames)
    %plot mean values with high and low bars. x and y are 3 column matrices
    %offsets from mean to low and high values
%     mxx = max(max(X)); mnx = min(min(X));
%     mxy = max(max(Y)); mny = min(min(Y));
%     xy1 = [min(mnx,mny),max(mxx,mxy)]; 
    
    x = X(:,2);
    xneg = x-X(:,1);
    xpos = X(:,3)-x;
    y = Y(:,2);
    yneg = y-Y(:,1);
    ypos = Y(:,3)-y;
    %find +ve/-ve values of offset from MT values
%     yneg = getposnegvalues(yneg);
%     ypos = getposnegvalues(ypos);
%     xneg = getposnegvalues(xneg);
%     xpos = getposnegvalues(xpos); 
    
    %find out of bounds HW or LW estuaries
    idv = isnan(xneg) | isnan(xpos) | isnan(yneg) | isnan(ypos);
    divx = x; 
    divx(~idv) = NaN; 
    divy = y; 
    divy(~idv) = NaN;
    
    %offset position for text estuary names
%     xtxt = x+sum([xneg(:,2),xpos(:,1)],2,'omitnan')*1.1;
%     idt = xneg(:,2)>0 & xpos(:,1)>0; %find two sided cases (both +ve)
%     xtxt(idt) = x(idt)+max(xneg(idt,2),xpos(idt,1))*1.1; %use maximum of thw two
    xtxt = x+sum([xneg,xpos],2,'omitnan')*1.1;
    idt = xneg>0 & xpos>0; %find two sided cases (both +ve)
    xtxt(idt) = x(idt)+max(xneg(idt),xpos(idt))*1.1; %use maximum of thw two   
    %index for points that are to be plotted in reverse order (-ve offsets)
   % idr = ~isnan(yneg) | ~isnan(ypos) | ~isnan(xneg) | ~isnan(xpos);
%     rx = x; rx(~idr) = NaN; 
%     ry = y; ry(~idr) = NaN;
    
    %generate plot  
    errorbar(ax,x,y,yneg,ypos,xneg,xpos,'o','CapSize',8)
%     errorbar(ax,x,y,yneg(:,1),ypos(:,1),xneg(:,1),xpos(:,1),'o','CapSize',8)   
%     errorbar(ax,rx,ry,ypos(:,2),yneg(:,2),xpos(:,2),xneg(:,2),'o','CapSize',8)
    plot(divx,divy,'og')
%    plot(xy1,xy1,'-.','Color',[0.5,0.5,0.5])
    text(xtxt,y,estnames,'FontSize',8);
%     if strcmp(plp.axes{1},'1')
%         ax.XScale = 'log';
%     end
%     if strcmp(plp.axes{2},'1')
%         ax.YScale = 'log';
%     end 

end
%%
function pndata = getposnegvalues(data)
    %splits data into positive and negative values and returns absolute
    %values in columns 1(+ve) and 2(-ve)
    idx = data<0;
    pndata = NaN(length(data),2);
    pndata(~idx,1) = data(~idx);      %positive values
    pndata(idx,2) = abs(data(idx));        %negative values
end
%%
function ax = getGMfig(hf)
    %generate the base plot for the Geyer_McCready diagram
    alpha = 3.4;                %fit coefficient
    Frf_salt_limit = 7e-2;
    Frf_strat_limit = 2.3e-3;
    
    ax = axes('Parent',hf);
    M = linspace(0.1,2,100);
    Frf = (M.^2/sqrt(alpha)).^3; %Eqn.22 as corrected by Maitane
    Fr0 = (M.^2/.2).^3;          %the additional diagonals are not defined
    id0 = Fr0>=Frf_strat_limit;  %in paper. Offets obtained by changing denominator
    Fr1 = (M.^2/5).^3;           %to give lines that are in approx right position
    id1 = Fr1<=Frf_salt_limit;
    Fr2 = (M.^2/20).^3;        
    plot(ax,M,Frf,'-r','HandleVisibility','off')                           %plot main diagonal based on Eq.22
    ax.YScale = 'log';
    ax.XScale = 'log';
%     ax.YLim = [1e-4,1.0];
%     ax.XTick = [0.1,.2,.5,1,2];
     
    hold on 
    plot(ax,M,Fr0.*(id0),'--r','HandleVisibility','off')                   %plot boundary
    plot(ax,M,Fr1.*(id1),'--r','HandleVisibility','off')                   %plot sedondary diagonal
    plot(ax,M,Fr2,'--r','HandleVisibility','off')                          %plot lower boundary
    xlim_salt = [interp1(Fr0,M,Frf_salt_limit), ax.XLim(2)];
    xlim_strat = [ax.XLim(1),interp1(Fr1,M,Frf_strat_limit)];
    plot(xlim_salt, Frf_salt_limit*[1 1],'--r','HandleVisibility','off');  %plot salt wedge limit
    plot(xlim_strat, Frf_strat_limit*[1 1],'--r','HandleVisibility','off');%plot stratification limit
    hold off
    %
    ax.XLabel.String = 'M';
    ax.YLabel.String = 'Fr_f';
    ax.Title.String = 'Geyer-McCready Diagram';
end
