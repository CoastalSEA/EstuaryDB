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
%   NB: hydraulic properties have to be added to dataset
%
% Author: Ian Townend
% CoastalSEA (c) June 2025
%--------------------------------------------------------------------------
%
    promptxt = 'Select observed data for empirical relationships:';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    if isempty(cobj), return; end
    datadst = cobj.Data.(datasets{idd});   %selected observed variable dataset
    
    ok = 0;
    while ok<1
        promptxt = 'Select hydraulic properties to use:';
        [cobj,~,datasets,idl] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
        if isempty(cobj), return; end
        hydrodst = cobj.Data.(datasets{idl});  %selected hydraulic variable dataset 
        if any(strcmp(hydrodst.VariableNames,'Hmlw')), ok = 1; end
    end

    %option to remove selected estuaries from the dataset
    % answer = questdlg('Mask dataset','Mask','Yes','No','Yes');
    % if strcmp(answer,'Yes')
    %     estdesc = datadst.RowNames;
    %     ide = listdlg("ListString",estdesc,"PromptString",'Select estuaries to omit:',...
    %                   'SelectionMode','multiple','ListSize',[160,200],...
    %                   'Name','EDBtools');
    % end
    if strcmp(datadst.Description,'UK dataset')  %bespoke for UK dataset****
        ide = [77,88];
    else
        ide = [];
    end
    %select variables to plot
    vardesc = datadst.VariableDescriptions;
    ok = 0;
    while ok<1
        %use observed values as the dependent variable         
        [depvar,plotxt] = getDependentVariable(datadst);
        if isempty(depvar), ok = 1; continue; end 
        %use either hydraulic or derived values as the indpendent variable  
        [indvar,plotxt] = getIndependentVariable(hydrodst,datadst,plotxt);        
        if isempty(indvar), ok = 1; continue; end          
        
        if ~isempty(ide)
            indvar(ide) = NaN;  %remove estuaries to be excluded
            depvar(ide) = NaN;
        end
        empirical_plot(indvar,depvar,plotxt)
    end
end

%%
function [depvar,plotxt] = getDependentVariable(datadst)
    %select either a data variable or a derived variable
    datdesc = datadst.VariableDescriptions;
    derdesc = {'Intertidal Area','Intertidal Volume'};
    depdesc =[datdesc,derdesc];
    idd = listdlg("ListString",depdesc,"PromptString",'Select hydraulic variable:',...
                  'SelectionMode','single','ListSize',[200,300],...
                  'Name','EDBtools');
    if isempty(idd), depvar = []; plotxt = []; return; end  

    switch depdesc{idd}
        case 'Intertidal Area'
            depvar = datadst.Smhw-datadst.Smlw; 
            plotxt.ylabel = 'Intertidal area (m^2)' ;
        case 'Intertidal Volume'
            depvar = datadst.Vmhw-datadst.Vmlw-datadst.Smlw.*datadst.TidalRange; 
            depvar(depvar<0) = NaN;
            plotxt.ylabel = 'Intertidal volume (m^3)' ;
        otherwise
            depvar = datadst.(datadst.VariableNames{idd}); 
            plotxt.ylabel = datadst.VariableLabels{idd};
    end
    depnames = [datadst.VariableNames,{'Sfl','Vfl'}];
    plotxt.varname = depnames{idd};
    plotxt.title = datadst.Description; 
end

%%
function [indvar,plotxt] = getIndependentVariable(hydrodst,datadst,plotxt)
    %select either a hydraulic variable or a derived variable
    hyddesc = hydrodst.VariableDescriptions;
    derdesc = {'Modified prism','Modified prism/Tidal range','Modified basin area'};
    inddesc =[hyddesc,derdesc];
    
    idh = listdlg("ListString",inddesc,"PromptString",'Select hydraulic variable:',...
                  'SelectionMode','single','ListSize',[200,300],...
                  'Name','EDBtools');
    if isempty(idh), indvar = []; return; end  
    
    switch inddesc{idh}
        case 'Modified basin area'  
            idh = listdlg("ListString",inddesc(1:3),"PromptString",'Select hydraulic depth:',...
                  'SelectionMode','single','ListSize',[200,300],...
                  'Name','EDBtools');
            if isempty(idh), indvar = []; return; end  
            
            Hsel = hydrodst.(hydrodst.VariableNames{idh});
            lamda = sqrt(9.81*Hsel).*12.4*3600;
            indvar = datadst.Lchannel*1000./lamda.*datadst.Smhw; 
            plotxt.xlabel = 'Modified basin area (m^2)' ;
            plotxt.varname =sprintf('%s (%s)',plotxt.varname,hydrodst.VariableNames{idh});
        case 'Modified prism'     
            [indvar,exponent] = modifiedPrism(datadst,hydrodst);
            plotxt.xlabel = 'Modified prism (m^3)';
            plotxt.varname = sprintf('%s (n=%.2f)',plotxt.varname,exponent);
        case 'Modified prism/Tidal range'
            [mprism,exponent] = modifiedPrism(datadst,hydrodst);
            indvar = mprism./datadst.TidalRange;
            plotxt.xlabel = 'Modified prism/Tidal range (m^2)';
            plotxt.varname = sprintf('%s (n=%.2f)',plotxt.varname,exponent);
        otherwise            
            indvar = hydrodst.(hydrodst.VariableNames{idh}); 
            plotxt.xlabel = hydrodst.VariableLabels{idh};
    end  
    plotxt.title = sprintf('%s (N=%d)',plotxt.title,length(indvar));
end

%%
function empirical_plot(x,y,vartxt)
    %plot selected empirical relationship
     hf = figure('Resize','on','Tag','PlotFig'); 
     ax = axes(hf);
     plot(ax,x,y,'x','DisplayName',vartxt.varname,'ButtonDownFcn',@godisplay)
     ax.XScale = 'log';
     ax.YScale = 'log';
     
     [~,~,~,xp,yp,txtp] = regression_model(x,y,'power',100,false);
     [~,~,~,xl,yl,txtl] = regression_model(x,y,'linear0',100,false);
     
     %add 1:1 line
     hold on
     mx = minmax(x);
     my = minmax(y);
     mm = [min([mx,my]),max([mx,my])];
     if mm(1)<100; mm(1) = 100; end
     plot(ax,mm,mm,'--k','DisplayName','1:1','ButtonDownFcn',@godisplay)
     plot(ax,xp,yp,'-.k','DisplayName','Power law fit','ButtonDownFcn',@godisplay)
     plot(ax,xl,yl,':k','DisplayName','Linear (0 intercept)','ButtonDownFcn',@godisplay)
     hold off
     
     xlabel(vartxt.xlabel)
     ylabel(vartxt.ylabel)
     grid on
     daspect([1 1 1 ]) 
     legend('Location','northwest')
     title(vartxt.title)
     subtitle(sprintf('Linear: %s; Power: %s',txtl,txtp))
end

%% 
function [mprism,exponent] = modifiedPrism(datadst,hydrodst)
    %modify the prism to take account of the channel length
    inp = inputdlg('Convergence exponent, n','Convergence',1,{'0.6'});
    exponent = str2double(inp{1});
    La = 0.35*datadst.Smhw.^exponent.*(1+datadst.Smlw./datadst.Smhw);
    Del = 1-exp(-datadst.Lchannel*1000./La/2);
    mprism = hydrodst.Pr./Del;
end
   %h1.Annotation.LegendInformation.IconDisplayStyle = 'off';  
    
    
    
    