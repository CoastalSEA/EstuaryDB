function edb_hypsometry_plots(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_user_plots.m
% PURPOSE
%   user functions to do provide additional bespoke plot options using the 
%   data loaded in EstuaryDB
% USAGE
%   edb_user_plots(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   user defined plot or other output
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_user_tools.m, edb_regression_plot
%   code for scatter and type_plot based on tableviewer_user_plot.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%
listxt = {'Convergence plot','Reach Width plot','Reach CSA plot'};
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
        end
    end
end

%%
% Default functions can be found in muitoolbox/psfunctions folder
% function: scatter_plot(mobj)
% function: type_plot(mobj)

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
    %plot of width or CSA for system as whole and by reach
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

    Vr = cellfun(@squeeze,table2cell(dst.DataTable(1,2:end)),'UniformOutput',false);    
    Xr = dst.UserData.Xr;
    nreach = length(Vr);

    if strcmp(option,'Reach CSA plot')
        Vall = getCSA(X,Z,Vall);
        for i=1:nreach
            Vr{i} = getCSA(Xr{i},Z,Vr{i});
        end
        Vall = getCSA(X,Z,Vall);
        plottxt{1} = 'CSA (m^2)'; vartxt = 'CSA';
    else
        plottxt{1} = 'Width (m)'; vartxt = 'Width';
    end
    maxV = max(Vall,[],'all');    

    %tidal levels
    if isfield(cobj.HydroProps,'TidalLevels')
        %adds spring tide levels and mtl to a plot (y-axis must be elevations)
        tlevels = cobj.HydroProps.TidalLevels; 
    else
        tlevels = [];
    end

    %create plots
    hf = figure('Name','Hypsometry','Resize','on','Tag','PlotFig');
    ax = axes(hf);
    plottxt{2} = sprintf('%s for all reaches',vartxt);
    hyps_plot(ax,Vall,X,Z,plottxt,tlevels);
    axis tight
    xlimits = ax.XLim;

    hf = figure('Name','Hypsometry','Units','Normalized','Resize','on','Tag','PlotFig');
    subplot(axes(hf));
    for i=1:nreach
        si = subplot(nreach,1,i);
        plottxt{2} = sprintf('%s for reach %d',vartxt,i);
        hyps_plot(si,Vr{i},Xr{i},Z,plottxt,tlevels);
        si.CLim(2) = ceil(maxV);
        si.XLim = xlimits;
        sgtitle('Reach contribution to widths')
    end
    hf = gcf;
    hf.Position = [0.40,0.28,0.31,0.65];
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
        delZ = abs(Z(2)-Z(1));
        A = zeros(size(W));
        for i =1:length(X)
            A(i,:) = cumsum(W(i,:))*delZ;  %hypsometry cross-sectiional area
        end
end

%% additional functions here or external-----------------------------------

%     %multiple selection returning 2 variables each with 3 selections for
%     %upper, central and lower values of a variable
%     [select,set] = multivar_selection(mobj,varnames,promptxt,1,... %muitoolbox function
%                        'XYZnset',3,...                             %minimum number of buttons to use for selection
%                        'XYZmxvar',[1,1,1],...                      %maximum number of dimensions per selection button, set to 0 to ignore subselection
%                        'XYZpanel',[0.05,0.2,0.9,0.3],...           %position for XYZ button panel [left,bottom,width,height]
%                        'XYZlabels',{'Upper','Central','Lower'});   %default button labels 


% function [select,set,dst] = xy_select(mobj)
%     %code to select a X and Y vectors and check they are same length
%     varnames = {'Var'};
%     promptxt = {'Select variables:'};
%     %multiple selection returning 1 variable set with 2 selections for
%     %X and Y values to use
%     ok = 0;
%     while ok<1   %need to ensure same number of rows in each variable
%         [select,set] = multivar_selection(mobj,varnames,promptxt,0,... %muitoolbox function
%                        'XYZnset',2,...                             %minimum number of buttons to use for selection
%                        'XYZmxvar',[1,1,1],...                      %maximum number of dimensions per selection button, set to 0 to ignore subselection
%                        'XYZpanel',[0.05,0.2,0.9,0.3],...           %position for XYZ button panel [left,bottom,width,height]
%                        'XYZlabels',{'X','Y'});                     %default button labels
%         if length(select.Var(1).data)==length(select.Var(2).data)            
%             ok = 1;          %same number of rows in each variable
%         end
%     end
%     %retrieve the dstable used for the X variable
%     cobj = getCase(mobj.Cases,set.Var(1).caserec);
%     dst = cobj.Data.(select.Var(1).dset);
% end








