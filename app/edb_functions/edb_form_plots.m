function edb_form_plots(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_form_plots.m
% PURPOSE
%   functions to do provide bespoke hypsometry and convergence plot options 
%   using the data loaded in EstuaryDB
% USAGE
%   edb_form_plots(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   Plots for along-channel convergence, Surface area, Volume, Width and CSA
%   hypsometry. Plots reach data if defined. Plots width/CSA at selected
%   distances from mouth (X) and plots the surface area or volume by
%   integrating the width data between two sections.
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
listxt = {'Convergence plot',...
          'Surface area','Width','CSA',...
          'Surface area Increment','Width Increment','CSA Increment',...
          'Reach Width','Reach CSA','Reach Width Increment','Reach CSA Increment',...
          'Width @ X','CSA @ X','Surface area from Width','Volume from CSA'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[160,220],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Convergence plot'
                get_ConvergencePlot(mobj); %calls edb_convergence_plot
            case {'Surface area','Surface area Increment'}
                get_surfaceArea(mobj,listxt{selection});
            case {'Width','CSA','Width Increment','CSA Increment'}
                get_Width(mobj,listxt{selection});
            case {'Reach Width','Reach CSA','Reach Width Increment','Reach CSA Increment'}
                get_reachPlot(mobj,listxt{selection});
            case {'Width @ X','CSA @ X'}
                get_x_sliderPlot(mobj,listxt{selection})
            case {'Surface area from Width','Volume from CSA'}
                get_x1tox2_sliderPlot(mobj,listxt{selection})
        end
    end
end

%%
function get_ConvergencePlot(mobj)
    getdialog('This option is specific to Along-Channel datasets',[],1)
    [cobj,srcdst,dname] = selectData(mobj,'Select Along-Channel dataset:','Width');
    if isempty(cobj), return; end

    if any(contains(srcdst.VariableNames,'hLW'))
        dst = srcdst;
    else
        dst = edb_convergence_data(cobj,dname);
    end

    if isempty(dst), return; end
    edb_convergence_plot(cobj,dst)
end

%%
function [var,Z,ptxt] = get_surfaceArea(mobj,option)
    %plot of bounding polygon and hypsomtery for surface area
    [cobj,dst,dname] = selectData(mobj,'Select Surface area dataset:','Surface');
    if isempty(cobj) || isempty(dst), return; end
    [var,Z] = edb_derived_hypsprops(dst,dname,dst.VariableNames{1}); %get S and V

    %create figure with option to include location plot if required
    [hf,sp] = setLocationPlot(cobj,'Polygon');

    if strcmp(option,'Surface area')
        Svar = var.S;
        Vvar = var.V;
    else
        Svar = diff(var.S);
        Vvar = diff(var.V);
        Z(1) = [];
    end
    xlabtxt = option;
    plot(sp,Svar,Z,'DisplayName','Surface area''ButtonDownFcn',@godisplay);

    addvol = questdlg('Include volume?','Hypsometry','Yes','No','No');
    if strcmp(addvol,'Yes')
        hold(sp,'on')
        plot(sp,Vvar,Z,'DisplayName','Volume''ButtonDownFcn',@godisplay);    
        hold(sp,'off')
        if contains(xlabtxt,'Increment')
            xlabtxt = 'Surface area and Volume Increments';
        else
            xlabtxt = 'Surface area and Volume';
        end
    end

    %add tide levels and mtl to a plot (y-axis must be elevations)
    if ~isempty(cobj.TidalProps)
        tlevels = cobj.TidalProps;  
        edb_plot_tidelevels(sp,tlevels);
    end 

    ax = findobj(hf.Children,'Type','axes');
    if isscalar(ax)
        ylabel('Elevation (mAD)') %avoids duplication on composite plot
    end
    xlabel(xlabtxt);      
    legend('Location','southeast')    
    ptxt = dst.Description;
    sgtitle(sprintf('Surface area hypsometry for %s',ptxt))
end


%%
function [Var,Z,X,ptxt] = get_Width(mobj,option)
    %plot of bounding polygon and hypsomtery for surface area
    [cobj,dst,dname] = selectData(mobj,'Select Width dataset:','Width');
    if isempty(cobj) || isempty(dst), return; end

    %create figure with option to include location plot if required
    [~,sp] = setLocationPlot(cobj,'Sections');

    %initialise variable and plotting text for selected variable
    [Var,Z,X,ptxt] = getWidthCSASelection(cobj,dst,dname,option);
    %contour surface plot with tidal levels if available
    hyps_plot(sp,Var,X,Z,ptxt,cobj.TidalProps)
    axis tight
end

%%
function  get_reachPlot(mobj,option)
    %plot of width or CSA for system as whole and by reach (this is similar
    %code to the plotting in edb_w_hypsometry)
    [cobj,dst,~] = selectData(mobj,'Select Along-Channel dataset:','Width');
    if isempty(cobj), return; end
    % Vall = squeeze(dst.(dst.VariableNames{1}));    
    Z = dst.Dimensions.Z;
    X = dst.Dimensions.X;   
    xlimits = minmax(X);

    if width(dst)>1
        Vr = cellfun(@squeeze,table2cell(dst.DataTable(1,2:end)),'UniformOutput',false);    
        Xr = dst.UserData.Xr;
        nreach = length(Vr);
        if strcmp(option,'Reach CSA')
            %hypsometry cross-sectional area (as used in edb_derived_hypsprops.m)
            for i=1:nreach
                Vr{i} = cumtrapz(Z,Vr{i},2);  %hypsometry cross-sectional area
            end
            ptxt{1} = 'CSA (m^2)';  ptxt{2} = 'Width';  vartxt = 'CSA';
        else
            ptxt{1} = 'Width (m)';  ptxt{2} = 'CSA';    vartxt = 'Width';
        end
        maxV = cellfun(@(x) max(x,[],'all'),Vr,'UniformOutput',false); 
        maxV = max([maxV{:}]);

        if contains(option,'Increment')
            for i=1:nreach
                Vr{i} = diff(Vr{i},1,2);
            end
            Z(1) = [];             
            vartxt = sprintf('%s Increment',vartxt);
        end
    else
        getdialog('No reaches available',1)
        return;
    end

    %tidal levels
    if ~isempty(cobj.TidalProps)
        %adds spring tide levels and mtl to a plot (y-axis must be elevations)
        tlevels = cobj.TidalProps; 
        varnames = tlevels.VariableNames;
        hwvar = find(contains(varnames,'HW'),1,'first');
        HWL = tlevels.(varnames{hwvar})+0.5;            %add 0.5 offset
    else
        tlevels = [];
        HWL = max(Z);
    end

    %limit the maximum Z value used in the plot
    inp = inputdlg('Upper limit for plots?','Width Hypsometry',1,{num2str(HWL)});
    if ~isempty(inp)
        HWL = str2double(inp{1});
        [~,idx] = min(abs(Z-HWL));
        Z(idx:end) = [];
    end

    %plot the data for each reach as a set of subplots, plotted as a single
    %column. To convert the single column of subplots to 2 columns use the 
    %function reshape_axes(hf) where hf is a handle to the figure to be 
    %modified, or simply reshape_axes with the plot to be modified as the 
    %currently selected figure.
    hf = figure('Name','Hypsometry','Units','Normalized','Resize','on','Tag','PlotFig');
    subplot(axes(hf));
    for i=1:nreach
        si = subplot(nreach,1,i);
        ptxt{3} = sprintf('%s for reach %d',vartxt,i);
        Var = Vr{i};
        Var(Var==0) = NaN;          %mask zero values
        if ~isempty(inp)
            Var(:,idx:end) = [];    %remove unwanted area above defined level
        end
        hyps_plot(si,Var,Xr{i},Z,ptxt,tlevels);
        si.CLim(2) = ceil(maxV);
        si.XLim = xlimits;        
    end
    sgtitle(sprintf('Reach %s for %s',vartxt,dst.Description))
    hf = gcf;
    hf.Position = [0.40,0.28,0.31,0.65];
end

%%
function get_x_sliderPlot(mobj,option)
    %create a figure with 2 tiles and a slider. plot the data in the left
    %tile and the values at a section in the right tile
    [cobj,dst,dname] = selectData(mobj,'Select Width dataset:','Width');
    if isempty(cobj) || isempty(dst), return; end

    if contains(option,'Width')
        option = 'Width';
    else
        option = 'CSA';
    end

    %initialise single slider plot with Var(X,Z) in left tile
    [~,t2,Var,Z,X,ptxt] = initialiseSliderPlot(cobj,dst,dname,option,1);
    mnmX = minmax(X);

    %plot the initial section at chainage 0
    [~,idx] = min(abs(X-mnmX(1)));
    xvar = Var(idx,:);       %extract selected variable at distance X
    plot(t2,xvar,Z,'Tag','x1-section')
    t2.XLabel.String = ptxt{1};
    t2.YLabel.String = 'Elevation (mAD)';
    t2.Title.String = sprintf('%s section at %.1f km',ptxt{2},mnmX(1)/1000);
    %add tide levels and mtl to a plot (y-axis must be elevations)
    if ~isempty(cobj.TidalProps)
        edb_plot_tidelevels(t2,cobj.TidalProps);
    end    
end

%%
function get_x1tox2_sliderPlot(mobj,option)
    %create a figure with 2 tiles and 2 slider2. plot the data in the left
    %tile and the integral between the selected section in the right tile
    [cobj,dst,dname] = selectData(mobj,'Select Width dataset:','Width');
    if isempty(cobj) || isempty(dst), return; end
    
    if contains(option,'Width')
        option = 'Width';
        vartxt = 'Surface area';
    else
        option = 'CSA';
        vartxt = 'Volume';
    end

    %initialise double slider plot with Var(X,Z) in left tile
    [t1,t2,Var,Z,X,ptxt] = initialiseSliderPlot(cobj,dst,dname,option,2);
    mnmX = minmax(X);

    %add slider position text
    hf = t2.Parent.Parent;                 %figure handle
    t1Pos = t1.Position;
    uicontrol('Style','text','Units','normalized',...
        'Position',[t1Pos(1)+t1Pos(3)/2, t1Pos(2)-0.06, 0.07, 0.04],...
        'String','0','Tag','stxt1','BackgroundColor',hf.Color);

    t2Pos = t2.Position;
    uicontrol('Style','text','Units','normalized',...
        'Position',[t2Pos(1)+t2Pos(3)/3, t2Pos(2)-0.06, 0.07, 0.04],...
        'String',num2str(mnmX(2)),'Tag','stxt2','BackgroundColor',hf.Color);

    %plot the initial section at chainage 0
    [~,idx1] = min(abs(X-mnmX(1)));
    [~,idx2] = min(abs(X-mnmX(2)));
    subvar = Var(idx1:idx2,:);       %extract selected variable at distance X
    subvar(isnan(subvar)) = 0;
    XX = X(idx1:idx2);
    for i=1:length(Z)
        xvar(i,1) = trapz(XX,subvar(:,i),1); %#ok<AGROW>
    end
    plot(t2,xvar,Z,'Tag','x1-section')
    t2.XLabel.String = ptxt{1};
    t2.YLabel.String = 'Elevation (mAD)';
    t2.Title.String = sprintf('%s over %.1f to %.1f km',vartxt,...
                                                mnmX(1)/1000,mnmX(2)/1000);
    %add tide levels and mtl to a plot (y-axis must be elevations)
    if ~isempty(cobj.TidalProps)
        edb_plot_tidelevels(t2,cobj.TidalProps);
    end  
end

%--------------------------------------------------------------------------
% utility functions for main functions above
%% ------------------------------------------------------------------------
function hyps_plot(ax,W,x,z,ptxt,tlevels)
    %genereate plot of the width as a function of z
    %create props to define labels for each variable to be plotted
    [X,Z] = meshgrid(x,z);
    contourf(ax,X,Z,W')
    colormap('parula')
    hc = colorbar(ax);
    if ~isempty(tlevels)
        edb_plot_tidelevels(ax,tlevels);
    end    
    hc.Label.String = ptxt{1};
    ax.XLabel.String = 'Distance to mouth (m)';
    ax.YLabel.String = 'Elevation (mAD)';
    ax.Title.String = ptxt{3};
end

%%
function setSlider(hf,minS,maxS,s0,var,idx)
    %set or update the settings held by the slider object (includes UserData)
    sname = sprintf('slider%d',idx);
    slider = findobj(hf,'Tag',sname);
    slider.Min = minS;
    slider.Max = maxS;
    slider.Value = s0;
    slider.UserData = var;
end

%%
function [hf,sp] = setLocationPlot(cobj,type)
    %create figure with option to include location plot if required
    answer = questdlg('Include location plot?','Hypsometry','Yes','No','No');
    if strcmp(answer,'Yes')
        %generate figure with plot of waterbody and hypsometry alongside
        hf = figure('Name','Hypsometry','Units','Normalized','Resize','on',...
                'Position',[0.28 0.50 0.38 0.30],'Tag','PlotFig');
        ax = edb_location_plot(cobj,hf,type);
        subplot(1,3,[1,2],ax);
        sp = subplot(1,3,3);
    else
        hf = figure('Name','Hypsometry','Tag','PlotFig');
        sp = axes(hf);    
    end
end

%%
function [t1,t2,Var,Z,X,ptxt] = initialiseSliderPlot(cobj,dst,dname,option,nslide)
    %extract selected dataset
    [Var,Z,X,ptxt] = getWidthCSASelection(cobj,dst,dname,option);
    mnmX = minmax(X); mnmZ = minmax(Z);

    %create two tile figure with single slider and plot source data
    hf = set_slider_figure('edb_plot_update',nslide);
    t1 = findobj(hf,'Tag','lefttile');
    hyps_plot(t1,Var,X,Z,ptxt,cobj.TidalProps)
    axis tight

    %plot location lines   
    hold(t1,'on')
    plot(t1,[1,1]*mnmX(1),mnmZ,'-g','LineWidth',1,'Tag','x1-distance')
    if nslide==2
        plot(t1,[1,1]*mnmX(2),mnmZ,'-r','LineWidth',1,'Tag','x2-distance')
    end
    hold(t1,'off')

    %set slider values. Pass plot data and axes to second tile as UserData
    t2 = findobj(hf,'Tag','righttile');
    var = struct('Var',Var,'X',X,'Z',Z,'t2',t2);    %,'tlevels',cobj.TidalProps
    setSlider(hf,mnmX(1),mnmX(2),mnmX(1),var,1);
    stxt1 = findobj(hf,'Tag','slabel1');
    stxt1.String = 'X-distance';
    if nslide==2
        setSlider(hf,mnmX(1),mnmX(2),mnmX(2),var,2);
        stxt1.String = 'X1-distance';
        stxt2 = findobj(hf,'Tag','slabel2');
        stxt2.String = 'X2-distance';    
    end
end

%%
function [Var,Z,X,ptxt] = getWidthCSASelection(cobj,dst,dname,option)
    %initialise variables and plotting text for selected variable
    [var,Z,X] = edb_derived_hypsprops(dst,dname,dst.VariableNames{1}); %get W and CSA

    if contains(option,'Width') && contains(option,'Increment')
        Var = diff(var.W,1,2);
        Z(1) = [];
        ptxt{1} = 'Width (m)'; ptxt{2} = 'Width'; 
    elseif contains(option,'Width')
        Var = var.W;
        ptxt{1} = 'Width (m)'; ptxt{2} = 'Width';
    elseif contains(option,'CSA') && contains(option,'Increment')
        Var = diff(var.A,1,2);
        Z(1) = [];
        ptxt{1} = 'CSA (m^2)'; ptxt{2} = 'CSA'; 
    elseif contains(option,'CSA')
        Var = var.A;
        ptxt{1} = 'CSA (m2)'; ptxt{2} = 'CSA'; 
    end
    Var(Var==0) = NaN;                %mask zero value
    ptxt{3} = sprintf('%s for %s',option,dst.Description);

    %tidal levels
    if ~isempty(cobj.TidalProps)
        %adds spring tide levels and mtl to a plot (y-axis must be elevations)
        tlevels = cobj.TidalProps; 
        varnames = tlevels.VariableNames;
        hwvar = find(contains(varnames,'HW'),1,'first');
        HWL = tlevels.(varnames{hwvar})+0.5;            %add 0.5 offset
    else
        HWL = max(Z);
    end

    %limit the maximum Z value used in the plot

    inp = inputdlg('Upper limit for plots?','Width Hypsometry',1,{num2str(HWL)});
    if ~isempty(inp)
        maxZ = str2double(inp{1});
        [~,idx] = min(abs(Z-maxZ));
        Z(idx:end) = [];
        Var(:,idx:end) = [];    %remove unwanted area above defined level
    end
end

%%
function [cobj,dst,dsetname] = selectData(mobj,promptxt,type)
    %select dataset and return parent object, dstable and dataset index
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},promptxt);
    if isempty(cobj), dst = []; dsetname = []; return; end
    datasets = fields(cobj.Data);
    datasets = datasets(contains(datasets,type));
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
    end
    dsetname = datasets{idd};
    dst = cobj.Data.(datasets{idd});
end

%%



