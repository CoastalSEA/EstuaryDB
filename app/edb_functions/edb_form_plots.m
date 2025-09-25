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
          'Cumulative Surface area','Cumulative Width','Cumulative CSA',...
          'Reach Width','Reach CSA',...
          'Reach Cumulative Width','Reach Cumulative CSA',...
          'Width @ X','CSA @ X','Surface area from width','Volume from CSA'};
    ok = 1;
    while ok>0
        selection = listdlg("ListString",listxt,"PromptString",...
                            'Select option:','SelectionMode','single',...
                            'ListSize',[160,220],'Name','EDBtools');
        if isempty(selection), ok = 0; continue; end

        switch listxt{selection}
            case 'Convergence plot'
                get_ConvergencePlot(mobj); %calls edb_convergence_plot
            case {'Surface area','Cumulative Surface area'}
                get_surfaceArea(mobj,listxt{selection});
            case {'Width','CSA','Cumulative Width','Cumulative CSA'}
                get_Width(mobj,listxt{selection});
            case {'Reach Width','Reach CSA','Reach Cumulative Width','Reach Cumulative CSA'}
                get_reachPlot(mobj,listxt{selection});
            case {'Width @ X','CSA @ X'}
                get_x_sliderPlot(mobj,listxt{selection})
            case {'Surface area from width','Volume from CSA'}
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
function [Z,var,tlevels,ptxt] = get_surfaceArea(mobj,option)
    %plot of bounding polygon and hypsomtery for surface area
    [cobj,dst,dname] = selectData(mobj,'Select Surface area dataset:','Surface');
    if isempty(cobj) || isempty(dst), return; end
    [var,Z] = edb_derived_hypsprops(dst,dname,dst.VariableNames{1}); %get S and V

    %create figure with option to include location plot if required
    answer = questdlg('Include location plot?','Hypsometry','Yes','No','No');
    if strcmp(answer,'Yes')
        %generate figure with plot of waterbody and hypsometry alongside
        hf = figure('Name','Hypsometry','Units','Normalized','Resize','on',...
                'Position',[0.28 0.50 0.38 0.30],'Tag','PlotFig');
        ax = edb_location_plot(cobj,hf,'Polygon');
        subplot(1,3,[1,2],ax);
        s2 = subplot(1,3,3);
    else
        hf = figure('Name','Hypsometry','Tag','PlotFig');
        s2 = axes(hf);    
    end

    if strcmp(option,'Cumulative Surface area')
        Svar = var.S;
        Vvar = var.V;
        xlabtxt = 'Cumulative Surface area';
    else
        Svar = diff(var.S);
        Vvar = diff(var.V);
        Z(1) = [];
        xlabtxt = 'Surface area';
    end
    
    plot(s2,Svar,Z,'DisplayName','Surface area');

    addvol = questdlg('Include volume?','Hypsometry','Yes','No','No');
    if strcmp(addvol,'Yes')
        hold(s2,'on')
        plot(s2,Vvar,Z,'DisplayName','Volume');    
        hold(s2,'off')
        xlabtxt = sprintf('%s and Volume',xlabtxt);
    end

    %add tide levels and mtl to a plot (y-axis must be elevations)
    if ~isempty(cobj.TidalProps)
        tlevels = cobj.TidalProps;  
        edb_plot_tidelevels(s2,tlevels);
    else
        tlevels = [];
    end 

    if strcmp(answer,'No')
        ylabel('Elevation (mAD)') %avoids duplication on composite plot
    end
    xlabel(xlabtxt);      
    legend('Location','southeast')    
    ptxt = dst.Description;
    sgtitle(sprintf('Surface area hypsometry for %s',ptxt))
end


%%
function [Z,var,tlevels,ptxt] = get_Width(mobj,option)
    %plot of bounding polygon and hypsomtery for surface area
    [cobj,dst,dname] = selectData(mobj,'Select Width dataset:','Width');
    if isempty(cobj) || isempty(dst), return; end
    [var,Z,X] = edb_derived_hypsprops(dst,dname,dst.VariableNames{1}); %get W and CSA

    %create figure with option to include location plot if required
    answer = questdlg('Include location plot?','Hypsometry','Yes','No','No');
    if strcmp(answer,'Yes')
        %generate figure with plot of waterbody and hypsometry alongside
        hf = figure('Name','Hypsometry','Units','Normalized','Resize','on',...
                'Position',[0.28 0.50 0.38 0.30],'Tag','PlotFig');
        ax = edb_location_plot(cobj,hf,'Sections');
        subplot(1,3,[1,2],ax);
        s2 = subplot(1,3,3);
    else
        hf = figure('Name','Hypsometry','Tag','PlotFig');
        s2 = axes(hf);    
    end

    if strcmp(option,'Cumulative Width')
        Var = var.W;
        ptxt{1} = 'Width (m)'; vartxt = 'Cumulative Width';
    elseif strcmp(option,'Width')
        Var = diff(var.W,1,2);
        Z(1) = [];
        ptxt{1} = 'Width (m)'; vartxt = 'Width';
    elseif strcmp(option,'Cumulative CSA')
        Var = var.A;
        ptxt{1} = 'CSA (m2)'; vartxt = 'Cumulative CSA';
    elseif strcmp(option,'CSA')
        Var = diff(var.A,1,2);
        Z(1) = [];
        ptxt{1} = 'CSA (m^2)'; vartxt = 'CSA';
    end
    Var(Var==0) = NaN;                %mask zero values

    %add tide levels and mtl to a plot (y-axis must be elevations)
    tlevels = [];
    if ~isempty(cobj.TidalProps)
        tlevels = cobj.TidalProps;  
        edb_plot_tidelevels(s2,tlevels);
    end 

    ptxt{2} = sprintf('%s hypsometry for %s',vartxt,dst.Description);
    hyps_plot(s2,Var,X,Z,ptxt,tlevels)
    axis tight
end

%%
function hyps_plot(ax,W,x,z,ptxt,tlevels)
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
    hc.Label.String = ptxt{1};
    xlabel('Distance to mouth (m)')
    ylabel('Elevation (mAD)')
    title(ptxt{2})
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
            ptxt{1} = 'CSA (m^2)'; vartxt = 'CSA';
        else
            ptxt{1} = 'Width (m)'; vartxt = 'Width';
        end
        maxV = cellfun(@(x) max(x,[],'all'),Vr,'UniformOutput',false); 
        maxV = max([maxV{:}]);

        if contains(option,'Cumulative')
            vartxt = sprintf('Cumulative %s',vartxt);
        else
            for i=1:nreach
                Vr{i} = diff(Vr{i},1,2);
            end
            Z(1) = [];       
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

    hf = figure('Name','Hypsometry','Units','Normalized','Resize','on','Tag','PlotFig');
    subplot(axes(hf));
    for i=1:nreach
        si = subplot(nreach,1,i);
        ptxt{2} = sprintf('%s for reach %d',vartxt,i);
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

    [cobj,dst,dname] = selectData(mobj,'Select Width dataset:','Width');
    if isempty(cobj) || isempty(dst), return; end
    [var,Z,X] = edb_derived_hypsprops(dst,dname,dst.VariableNames{1}); %get W and CSA
    hf = sliderPlot(1);
end

%%
function get_x1tox2_sliderPlot(mobj,option)

    [cobj,dst,dname] = selectData(mobj,'Select Width dataset:','Width');
    if isempty(cobj) || isempty(dst), return; end
    [var,Z,X] = edb_derived_hypsprops(dst,dname,dst.VariableNames{1}); %get W and CSA
    hf = sliderPlot(2);
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






