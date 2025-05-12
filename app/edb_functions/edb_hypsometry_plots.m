function edb_hypsometry_plots(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_hypsometry_plots.m
% PURPOSE
%   functions to do provide bespoke hypsometry plot options using the 
%   data loaded in EstuaryDB
% USAGE
%   edb_hypsometry_plots(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   Plots for along-channel convergence, Surface area hypsometry, Reach 
%   Width and Reach CSA hypsometry
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_user_tools.m, edb_regression_plot, edb_table_plots
%   code for scatter and type_plot based on tableviewer_user_plot.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%
listxt = {'Convergence plot','Surface area','Reach Width plot','Reach CSA plot'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[160,200],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Convergence plot'
                get_ConvergencePlot(mobj); %calls edb_regression_plot
            case {'Reach Width plot','Reach CSA plot'}
                get_reachPlot(mobj,listxt{selection});
            case 'Surface area'
                get_surfaceArea(mobj);
        end
    end
end

%%
function get_ConvergencePlot(mobj)
    getdialog('This option is specific to Along-Channel datasets')
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select Along-Channel dataset:');
    if isempty(cobj), return; end
    datasets = fields(cobj.Data);
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
        if isempty(idd), return; end
    end
    dst = edb_convergence_data(cobj,datasets{idd});
    if isempty(dst), return; end
    edb_regression_plot(cobj,dst);
end

%%
function  get_reachPlot(mobj,option)
    %plot of width or CSA for system as whole and by reach (this is similar
    %code to the plotting in edb_w_hypsometry)
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select Along-Channel dataset:');
    if isempty(cobj), return; end
    datasets = fields(cobj.Data);
    datasets = datasets(contains(datasets,'Width'));
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
    end
    
    dst = cobj.Data.(datasets{idd});
    Vall = squeeze(dst.W);    
    Z = dst.Dimensions.Z;
    X = dst.Dimensions.X;   

    if width(dst)>1
        Vr = cellfun(@squeeze,table2cell(dst.DataTable(1,2:end)),'UniformOutput',false);    
        Xr = dst.UserData.Xr;
        nreach = length(Vr);
        if strcmp(option,'Reach CSA plot')
            Vall = getCSA(X,Z,Vall);
            for i=1:nreach
                Vr{i} = getCSA(Xr{i},Z,Vr{i});
            end
            plottxt{1} = 'CSA (m^2)'; vartxt = 'CSA';
        else
            plottxt{1} = 'Width (m)'; vartxt = 'Width';
        end
        maxV = cellfun(@(x) max(x,[],'all'),Vr,'UniformOutput',false); 
        maxV = max([maxV{:}]);
    else
        nreach = 0;
        if strcmp(option,'Reach CSA plot')
            Vall = getCSA(X,Z,Vall);
            plottxt{1} = 'CSA (m^2)'; vartxt = 'CSA';
        else
            plottxt{1} = 'Width (m)'; vartxt = 'Width';
        end
        maxV = max(Vall);
    end

    %tidal levels
    if ~isempty(cobj.TidalProps)
        %adds spring tide levels and mtl to a plot (y-axis must be elevations)
        tlevels = cobj.TidalProps; 
    else
        tlevels = [];
    end

    %create plots
    hf = figure('Name','Hypsometry','Resize','on','Tag','PlotFig');
    ax = axes(hf);
    plottxt{2} = sprintf('%s hypsometry for %s',vartxt,dst.Description);
    Vall(Vall==0) = NaN;                      %mask zero values
    hyps_plot(ax,Vall,X,Z,plottxt,tlevels);
    axis tight
    xlimits = ax.XLim;
    
    if nreach>0
        hf = figure('Name','Hypsometry','Units','Normalized','Resize','on','Tag','PlotFig');
        subplot(axes(hf));
        for i=1:nreach
            si = subplot(nreach,1,i);
            plottxt{2} = sprintf('%s for reach %d',vartxt,i);
            Var = Vr{i};
            Var(Var==0) = NaN;                    %mask zero values
            hyps_plot(si,Var,Xr{i},Z,plottxt,tlevels);
            si.CLim(2) = ceil(maxV);
            si.XLim = xlimits;        
        end
        sgtitle(sprintf('Reach contributions for %s',dst.Description))
        hf = gcf;
        hf.Position = [0.40,0.28,0.31,0.65];
    end
end


%%
function hyps_plot(ax,W,x,z,plottxt,tlevels)
    %genereate plot of the width as a function of z
    %create props to define labels for each variable to be plotted
    [X,Z] = meshgrid(x,z);
    %W(W>0) = log(W(W>0));
    contourf(ax,X,Z,W')
    colormap('parula')
    hc = colorbar;
    hold on
    if ~isempty(tlevels)
        edb_plot_tidelevels(ax,tlevels);
    end    
    hold off
    hc.Label.String = plottxt{1};
    xlabel('Distance to mouth (m)')
    ylabel('Elevation (mAD)')
    title(plottxt{2})
end

%%
function A = getCSA(X,Z,W)
    %compute the cross-section area by integrating width hypsometry
    delZ = abs(Z(2)-Z(1));
    A = zeros(size(W));
    for i =1:length(X)
        A(i,:) = cumsum(W(i,:))*delZ;  %hypsometry cross-sectiional area
    end
end

%%
function get_surfaceArea(mobj)
    %plot of bounding polygon and hypsomtery for surface area
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select Surface area dataset:');
    if isempty(cobj), return; end
    datasets = fields(cobj.Data);
    datasets = datasets(contains(datasets,'Surface'));
    if isempty(datasets), getdialog('No Surface area data'); return; end
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
    end
    dst = cobj.Data.(datasets{idd});
    [var,Z] = edb_derived_hypsprops(dst,datasets{idd},'Sa'); %get S and V
    shp = cobj.WaterBody;  %current saved waterbody polygon
    %add spring tide levels and mtl to a plot (y-axis must be elevations)
    tlevels = [];
    if ~isempty(cobj.TidalProps)        
        tlevels = cobj.TidalProps;   
    end
    
    %gereate figure with plot of waterbody and hypsometry alongside
    hf = figure('Name','Hypsometry','Units','Normalized','Resize','on',...
                'Position',[0.28 0.50 0.38 0.30],'Tag','PlotFig');
    %plot bathymetry and bounding polygon
    ax = PL_Sections.getGrid(cobj,hf);
    hold on
    plot(ax,shp.x,shp.y,'r')
    hold off

    %plot hypsometry and tidal levels (if available)
    subplot(1,3,[1,2],ax);
    s2 = subplot(1,3,3);
    plot(s2,var.S,Z,'DisplayName','Surface area');
    hold on
    plot(s2,var.V,Z,'DisplayName','Volume');

    if ~isempty(tlevels)
        edb_plot_tidelevels(s2,tlevels);
    end 
    hold off
    xlabel('Surface area & Volume');
    legend('Location','southeast')
    sgtitle(sprintf('Surface area hypsometry for %s',dst.Description))
end







