function edb_hypsometry_models(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_hypsometry_models.m
% PURPOSE
%   functions to fit non-linear functions to the surface area or width
%   hypsometry datasets. NB requires the Statistics and Machine Learning Toolbox
% USAGE
%   edb_hypsometry_models(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   plots of the hyspomtery and fitted models
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_form_plots
%
% Author: Ian Townend
% CoastalSEA (c) Sept 2025
%--------------------------------------------------------------------------
%
    if ~license('test','Statistics_Toolbox')
        warndlg('Statistics and Machine Learning Toolbox needed for Hypsometry models');
        return;
    end

    answer = questdlg('Data type','Hypsometry','Surface area','Width','Surface area');

    if strcmp(answer,'Surface area')
        model_surfaceArea(mobj);
    else
        model_Width(mobj);
    end
end

%%
function model_surfaceArea(mobj)
    %fit models to selected surface area dataset
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
    [var,z] = edb_derived_hypsprops(dst,datasets{idd},'Sa'); %get S and V

    %plot labels
    ptxt = struct('var1','S','vardesc1','Surface area (m^2)','var2','V',...
                  'vardesc2','Volume (m^3)','xlabel','Surface area & Volume',...
                  'title',sprintf('Hypsometry for %s',dst.Description));

    %add spring tide levels and mtl to a plot (y-axis must be elevations)
    tlevels = [];
    if ~isempty(cobj.TidalProps)        
        tlevels = cobj.TidalProps;   
    end

    [hf,ax] = plotHypsometry(z,var,ptxt,tlevels);
        
end

%%
function model_Width(mobj)
    %fit models to selected width dataset
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
    [var,z,x] = edb_derived_hypsprops(dst,datasets{idd},'W'); %get W and A

    %select cross-section to use
    inp = listdlg("PromptString",'Select section to use','Name','Width',...
                  'SelectionMode','single','ListString',string(x));
    if isempty(inp), inp = 1; end
    var.W = var.W(inp,:);
    var.A = var.A(inp,:);

    %plot labels
    ptxt = struct('var1','W','vardesc1','Width (m)','var2','A',...
                  'vardesc2','Cross-sectional area (m^2)','xlabel',...
                  'Width & CSA','title',...
                  sprintf('Hypsometry for %s (section at %d from mouth)',...
                  dst.Description,x(inp)));

    %add spring tide levels and mtl to a plot (y-axis must be elevations)
    tlevels = [];
    if ~isempty(cobj.TidalProps)        
        tlevels = cobj.TidalProps;   
    end

    [hf,ax] = plotHypsometry(z,var,ptxt,tlevels);

end

%%
function [hf,ax] = plotHypsometry(z,var,ptxt,tlevels)
    %gereate figure with source data
    hf = figure('Name','Hypsometry','Tag','PlotFig');
    ax = axes(hf);
    plot(ax,var.(ptxt.var1),z,'DisplayName',ptxt.vardesc1)

    hold on
    plot(ax,var.(ptxt.var2),z,'DisplayName',ptxt.vardesc2)
    if ~isempty(tlevels)
        edb_plot_tidelevels(ax,tlevels,false); %exclude labels from legend
    end 
    hold off
    xlabel(ptxt.xlabel)
    ylabel('Elevation (mAD)')
    legend('Location','southeast')  
    title(ptxt.title)
end
