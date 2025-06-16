function edb_empirical_props(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_empirical_props.m
% PURPOSE
%   Function to plot empirical and measured relationships
% USAGE
%   edb_empirical_props(mobj)
% INPUTS
%   mobj - handle to EstuaryDB App
% OUTPUT
%   generates a range of plots
% NOTES
%   called from edb_user_tools in EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) June 2025
%--------------------------------------------------------------------------
%
    promptxt = 'Select observed data for empirical relationships:';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    if isempty(cobj), return; end
    datadst = cobj.Data.(datasets{idd});  %selected dataset
    
    idl = listdlg('PromptString','Select hydraulic properties to use:',...
                          'SelectionMode','single','ListString',datasets);
    if isempty(idl), return; end 
    hydrodst = cobj.Data.(datasets{idl});  %selected dataset
    
    empirical_plot(hydrodst.Pr,datadst.Vmtl,'Test')
end
%%
function empirical_plot(x,y,vartxt)
    %plot selected empirical relationship
     hf = figure('Resize','on','Tag','PlotFig'); 
     ax = axes(hf);
     plot(ax,x,y,'x','DisplayName',vartxt,'ButtonDownFcn',@godisplay)
     ax.XScale = 'log';
     ax.YScale = 'log';
     
     %add 1:1 line
     hold on
     mx = minmax(x);
     my = minmax(y);
     mm = [min([mx,my]),max([mx,my])];
     plot(ax,mm,mm,'--k','DisplayName','1:1','ButtonDownFcn',@godisplay)
     hold off
     
     %h1.Annotation.LegendInformation.IconDisplayStyle = 'off'; 
end
%%
function get_regression()
    %get the regression coefficients for empirical plot
    
end
    
    
    
    
    
    