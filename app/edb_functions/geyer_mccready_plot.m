function ax = geyer_mccready_plot(cobj,dset)
%
%-------function help------------------------------------------------------
% NAME
%   geyer_mccready_plot.m
% PURPOSE
%   create a plot of X against Y as proposed by Geyer and McCready, 2014
% USAGE
%   geyer_mccready_plots(select)
% INPUTS
%   cobj - handle to selected case instance
%   dset - name of dataset from case to be used
% OUTPUT
%   Geyer and McCready plot
% NOTES
%   generate figure the matches Figure 6 in Geyer W R and MacCready P, 
%   2014, The Estuarine Circulation. Annual Review of Fluid Mechanics, 
%   46 (1), 175-197
% SEE ALSO
%   EstuaryDB, called from edb_user_tools
%
% Author: Ian Townend
% CoastalSEA (c) Nov 2024
%--------------------------------------------------------------------------
%     
    dst = cobj.Data.(dset);  %selected dataset
    %experimental options for depth, prism and csa.
    promptxt = {'Hydraulic depth (1-3)','Tidal prism (1-2)','CSA at mouth (1-2)'};
    inp = inputdlg(promptxt,'GM plot',1,{'3','2','1'});
    if isempty(inp),return; end
    inp = num2cell(str2double(inp));
    %get Freshwater Fround number and Mixing parameters
    [x,y,loc] = getPlotVariables(dst,inp{:});
    mnmxX = minmax(x,'omitnan');
    mnmxY = minmax(y,'omitnan');
    
    hf = figure('Name','GMcC-diagram','Units','normalized', ......
                'Resize','on','HandleVisibility','on', ...
                'Tag','PlotFig');
    ax = getGMfig(hf);
    
    hold on
        ax = var_range_plot(ax,x,y,loc,{'low-mean-high','no flow data'},1);
        he = findobj(ax,'Tag','ErrSym');
        he.Color = 'b';
    hold off

    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    xlim([mnmxX(:)]);
    ylim([mnmxY(:)]);
    
    ax.Title.String = sprintf('%s (%d, %d, %d)',ax.Title.String,inp{:});
    legend({'low-mean-high','no flow data'},'Location','best');     
end
%%
function [M,Frf,loc] = getPlotVariables(dst,op1,op2,op3)
    %modify flow and tidal range to Froude no. Frf, and mixing parameter, M
    % op1 - hydrualic depth
    % op2 - tidal prism
    % op3 - area at mouth

    %define constants
    g = 9.81;                   %acceleration due to gravity
    cD = 0.002;                 %friction coefficient    
    beta = 0.00077;             %density coefficient
    s = 34;                     %ocean sainity
    omega = 2*pi()/(12.4*3600); %tidal angular frequency
    
    %main variables - tidal range and river discharge
    x(:,1) = dst.NeapRange;
    x(:,2) = dst.MeanRange;
    x(:,3) = dst.SpringRange;
    y(:,1) = dst.Qlow;
    y(:,2) = dst.Qmean;
    y(:,3) = dst.Qhigh;
    loc = dst.RowNames;

    %remove rows with missing values
    TT = [x(:,2),y(:,2)];            %central values
    [~,idn] = rmmissing(TT,1);       %removing rows with NaN central values
    
    TT = [dst.Vmtl,dst.Amtl];        %volume and csa to use
    [~,idv] = rmmissing(TT,1);       %removing rows with NaN central values

    id0 = dst.Vmtl==0 | dst.Amtl==0; %zero values

    idx = find(~idn & ~idv & ~id0);  %combined valid indices

    promptxt = sprintf('Subsample estuaries\nSelect values to include\nPress Cancel to use full list'); 
    idl = listdlg('PromptString',promptxt,'ListString',loc(idx),...
                         'SelectionMode','multiple','ListSize',[180,300]);
    if isempty(idl), idl = 1:length(loc(idx)); end
  
    %For scaling variables to match need to apply location selection to 
    %any removal of missing rows
    idx = idx(idl);
    %subselect main variables
    x = x(idx,:); y = y(idx,:); loc = loc(idx);

    %scaling variables - assumes that the variable names are as used in
    %app/example/Estuary_DSproperties.xlsx
    vHW = dst.Vmhw(idx);
    vLW = dst.Vmlw(idx);
    vMT = dst.Vmtl(idx);
    sHW = dst.Smhw(idx);
    sLW = dst.Smlw(idx);
    sMT = dst.Smtl(idx);
    aMT = dst.Amtl(idx);
    wMT = dst.Wmouth(idx);

    %derived parameters
    switch op1                             %hydraulic depth
        case 1
            H = (vHW+vLW)./(sHW+sLW);      %average hydraulic depth
        case 2
            H = vMT./sMT;
        case 3
            H = 1.5*(vHW+vLW)./(sHW+sLW);  %hydraulic depth at mouth Ho=H.Lw/La
    end

    switch op2                            %tidal prism
        case 1
            P = sMT/2.*x;                 %tidal prism
        case 2
            P = (vHW-vLW).*x./x(:,2);     %scale mean tide volume estimate
    end
  
    switch op3                           %CSA at mouth
        case 1
            A = aMT;                     %csa at mouth
        case 2
            A = wMT.*H;                  %csa at mouth based on width and av.depth
    end
    
    NoH = sqrt(beta*g*s*H);              %factor for Frf and M
    Ur = y./A;                           %river velocity
    Ut = omega*P./2./A;                  %tidal velocity
    
    Frf = Ur./NoH;                       %freshwater Froude number
    M = (cD/omega./NoH./H).*Ut.^2;       %mixing coefficient
end 

%%
function ax = getGMfig(hf)
    %generate the base plot for the Geyer_McCready diagram
    alpha = 3.4;                 %fit coefficient
    Frf_salt_limit = 7e-2;       %limit for salt wedge
    Frf_strat_limit = 2.3e-3;    %limit for startification
    
    ax = axes('Parent',hf);
    M = linspace(0.1,2,500);     %100 points between 0.1 and 2
    Frf = (M.^2/sqrt(alpha)).^3; %Eqn.22 as corrected by Maitane
    Fr0 = (M.^2/.2).^3;          %the additional diagonals are not defined
    Fr1 = (M.^2/5).^3;           %in paper. Offets obtained by changing denominator
    Fr2 = (M.^2/20).^3;          %to give lines that are in approx right position
   
    id0 = Fr0>=Frf_strat_limit & Fr0>1e-5; %limit extent of boundary lines
    id1 = Fr1<=Frf_salt_limit & Fr1>1e-5;  %based on salt wedge and stratification
    id2 = Fr2>1e-5;                        %limits and a lower bound of 1e-5
    idf = Frf>1e-5;

    Mst_salt =interp1(Fr0,M,Frf_salt_limit);     %start of salt limit    
    Mnd_strat = interp1(Fr1,M,Frf_strat_limit);  %end of stratification limit
    
    %find intersections that define corner points of polygons
    [~,idm1] = min(abs(Frf-7e-2));        %eq(22) and salt wedge limit
    [~,idm2] = min(abs(Frf-2.3e-3));      %eq(22) and stratification limit
    [~,idm3] = min(abs(Fr0-2.3e-3));      %upper boundary and stratification limit
    [~,idm4] = min(abs(Fr1-7e-2));        %first lower boundary salt wedge limit
    [~,idm5] = min(abs(Fr1-2.3e-3));      %second lower boundary and stratification limit

    %polygon of domain examined by Geyer and McCready
    p1 = polyshape([M(1),M(end),M(end),M(1)],[1,1,1e-5,1e-5]);
    %polygon of domain for stongly stratified systems
    x = [Mst_salt,M(idm1),M(idm2),M(idm3)];
    y = [7e-2,7e-2,2.3e-3,2.3e-3]; %uppe and lower limits of stratification
    p2 = polyshape(x,y);   
    %polygon of domain for partially stratified systems
    x = [M(idm1),M(idm4),M(idm5),M(idm2)];
    p3 = polyshape(x,y);

    %plot polygons and bounding lines
    plot(p1,'FaceColor', 'y', 'FaceAlpha', 0.1, 'EdgeColor','none','HandleVisibility','off');

    xlim_salt = [Mst_salt, M(end)];                          
    xlim_strat = [M(idm3),Mnd_strat];
    green = mcolor('green'); 
    hold on 
        plot(p2,'FaceColor', green, 'FaceAlpha', 0.2, 'EdgeColor','none','HandleVisibility','off');
        plot(p3,'FaceColor', 'g', 'FaceAlpha', 0.2, 'EdgeColor','none','HandleVisibility','off');
        plot(ax,M(idf),Frf(idf),'-r','HandleVisibility','off')             %plot main diagonal based on Eq.22
        plot(ax,M(id0),Fr0(id0),'--r','HandleVisibility','off')            %plot boundary
        plot(ax,M(id1),Fr1(id1),'--r','HandleVisibility','off')            %plot sedondary diagonal
        plot(ax,M(id2),Fr2(id2),'--r','HandleVisibility','off')            %plot lower boundary
        plot(xlim_salt, Frf_salt_limit*[1 1],'-.r','HandleVisibility','off');  %plot salt wedge limit
        plot(xlim_strat, Frf_strat_limit*[1 1],'-.r','HandleVisibility','off');%plot stratification limit
    hold off

    %change axis scale to log and add labels
    ax.XLim(1) = 0; ax.YLim(1) = 0; %set the xy limits to be non-negative
    ax.XScale = 'log';
    ax.YScale = 'log';

    ax.XLabel.String = 'Mixing parameter, M';
    ax.YLabel.String = ('Freshwater Froude number, Fr_f');
    ax.Title.String = 'Geyer-McCready Diagram';
end