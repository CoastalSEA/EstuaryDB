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

    % promptxt = 'Select observed data for empirical relationships:';
    % [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    % if isempty(cobj), return; end
    % datadst = cobj.Data.(datasets{idd});   %selected observed variable dataset
    % 
    % ok = 0;
    % while ok<1
    %     promptxt = 'Select hydraulic properties to use:';
    %     [hydobj,~,datasets,idl] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    %     if isempty(hydobj), return; end
    %     hydrodst = hydobj.Data.(datasets{idl});  %selected hydraulic variable dataset 
    %     if any(strcmp(hydrodst.VariableNames,'Hmlw')), ok = 1; end
    % end

        %Bespoke selection
        answer = questdlg('Select dataset','Empirical','UK','WS','UK');
        if strcmp(answer,'UK')
            datadst = mobj.Cases.DataSets.muiTableImport(1).Data.UKdata;
            hydrodst = mobj.Cases.DataSets.muiTableImport(1).Data.HydroProps;
            classdst = mobj.Cases.DataSets.muiTableImport(1).Data.UKclass;
        else
            datadst = mobj.Cases.DataSets.muiTableImport(2).Data.WSdata;
            hydrodst = mobj.Cases.DataSets.muiTableImport(2).Data.HydroProps;
            classdst = mobj.Cases.DataSets.muiTableImport(2).Data.WSclass;
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
            ide = [77,88,145];
        else
            ide = [];
        end
    
    %select variables to plot
    ok = 0;
    while ok<1
        %use observed values as the dependent variable     
        plotxt.promptxt = 'Dependent (y) variable:';
        [depvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt);
        if isempty(depvar), ok = 1; continue; end 
        plotxt.ylabel = plotxt.label;
        plotxt.varname = plotxt.name;
        %use either hydraulic or derived values as the indpendent variable
        plotxt.promptxt = 'Independent (x) variable:';
        [indvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt);        
        if isempty(indvar), ok = 1; continue; end   
        plotxt.xlabel = plotxt.label;
        %add cases description to title
        nrec = sum(~isnan(indvar));
        plotxt.title = sprintf('%s (N=%d)',datadst.Description,nrec);

        if ~isempty(ide)
            indvar(ide) = NaN;  %remove estuaries to be excluded
            depvar(ide) = NaN;
        end
        empirical_plot(indvar,depvar,plotxt)
    end
end

%%
function [var,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt)
    %select either a data variable or a derived variable
    promptxt = sprintf('Select data type for %s',plotxt.promptxt);
    answer = questdlg(promptxt,'Variable','Input','Derived','Quit','Input');
    if strcmp(answer,'Input')
        %select variable from input data set
        [var,plotxt] = setInputVariable(datadst,hydrodst,plotxt);        
    elseif strcmp(answer,'Derived')
        %select variable from derived data set or create new variable       
        [var,plotxt] = setDerivedVariable(datadst,hydrodst,classdst,plotxt);
    else
        var = []; plotxt = [];
    end
end

%%
function [var,plotxt] = setInputVariable(datadst,hydrodst,plotxt)
    %set the input variable based on user selection
    datadesc = datadst.VariableDescriptions;
    hydrodesc = hydrodst.VariableDescriptions;
    derdesc = {'Intertidal Area','Intertidal Volume'};
    vardesc =[datadesc,hydrodesc,derdesc];
    promptxt = sprintf('Select %s',plotxt.promptxt);
    idv = listdlg("ListString",vardesc,"PromptString",promptxt,...
                  'SelectionMode','single','ListSize',[200,350],...
                  'Name','EDBtools');
    if isempty(idv), var = []; plotxt = []; return; end  

    switch vardesc{idv}
        case 'Intertidal Area'
            var = datadst.Smhw-datadst.Smlw; 
            plotxt.label = 'Intertidal area (m^2)' ;
        case 'Intertidal Volume'
            var = datadst.Vmhw-datadst.Vmlw-datadst.Smlw.*datadst.TidalRange; 
            var(var<0) = NaN;
            plotxt.label = 'Intertidal volume (m^3)' ;
        case hydrodesc
            var = hydrodst.(hydrodst.VariableNames{idv-length(datadesc)}); 
            plotxt.label = hydrodst.VariableLabels{idv-length(datadesc)};        
        otherwise
            var = datadst.(datadst.VariableNames{idv}); 
            plotxt.label = datadst.VariableLabels{idv};  
    end
    varnames = [datadst.VariableNames,hydrodst.VariableNames,{'Sfl','Vfl'}];
    plotxt.name = varnames{idv};
end

%%
function [var,plotxt] = setDerivedVariable(datadst,hydrodst,classdst,plotxt)
    %set the derived variable based on user selection
    vardesc = {'Modified prism','Modified prism / Tidal range',...
               'Modified prism / Basin area',...
               'Modified Basin area',...
               'Estimated Flat area','Estimated Flat volume'};
    promptxt = sprintf('Select %s',plotxt.promptxt);
    idv = listdlg("ListString",vardesc,"PromptString",promptxt,...
                  'SelectionMode','single','ListSize',[200,350],...
                  'Name','EDBtools');
    if isempty(idv), var = []; plotxt = []; return; end 

    switch vardesc{idv}
        case 'Modified Basin area'  
            idh = selectDepth(hydrodst);
            if isempty(idh), var = []; return; end  
            var = modifiedArea(datadst,hydrodst,classdst,idh);
            plotxt.label = 'Modified Basin area (m^2)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);
        case 'Estimated Flat area'
            idh = selectDepth(hydrodst);
            if isempty(idh), var = []; return; end  
            Slw = modifiedArea(datadst,hydrodst,classdst,idh);
            var = datadst.Smhw-Slw;
            var(var<=0) = NaN;
            plotxt.label = 'Estimated Flat area (m^2)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);
        case'Estimated Flat volume'
            idh = selectDepth(hydrodst);
            if isempty(idh), var = []; return; end  
            Slw = modifiedArea(datadst,hydrodst,classdst,idh);
            var = datadst.Smhw-Slw;
            var(var<=0) = NaN;
            var = var.*datadst.TidalRange;
            plotxt.label = 'Estimated Flat volume (m^3)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);
        case 'Modified prism'     
            mprism = modifiedPrism(datadst,hydrodst,classdst);
            if isempty(mprism), var = []; return; end
            var = mprism;
            plotxt.label = 'Modified prism (m^3)';
        case 'Modified prism / Tidal range'
            mprism = modifiedPrism(datadst,hydrodst,classdst);
            if isempty(mprism), var = []; return; end
            var = mprism./datadst.TidalRange;
            plotxt.label = 'Modified prism / Tidal range (m^2)';            
        case 'Modified prism / Basin area'
            mprism = modifiedPrism(datadst,hydrodst,classdst);
            if isempty(mprism), var = []; return; end
            var = mprism./datadst.Smhw;
            plotxt.label = 'Modified prism / Basin area (m)';
        otherwise            
            var = hydrodst.(hydrodst.VariableNames{idv}); 
            plotxt.label = hydrodst.VariableLabels{idv};
    end 

    varnames = {'mPr','mPrTr','mPrSb','mSb','eSfl','eVfl'};
    plotxt.name = varnames{idv};
end

%%
function idh = selectDepth(hydrodst)
    %select the hydraulic depth to use
    hydrodesc = hydrodst.VariableDescriptions;
    idh = listdlg("ListString",hydrodesc(1:3),"PromptString",'Select hydraulic depth:',...
                  'SelectionMode','single','ListSize',[200,300],...
                  'Name','EDBtools');
end

%%
function plotxt = setVarName(plotxt,hydrodst,idh)
    %if varname already set add hydrualic depth used for independent
    %variable
    if isfield(plotxt,'varname')
        plotxt.varname =sprintf('%s (%s)',plotxt.varname,hydrodst.VariableNames{idh});
    end
end

%%
% function [depvar,plotxt] = getDependentVariable(hydrodst,datadst)
%     %select either a data variable or a derived variable
%     datdesc = datadst.VariableDescriptions;
%     hyddesc = hydrodst.VariableDescriptions;
%     derdesc = {'Intertidal Area','Intertidal Volume'};
%     depdesc =[datdesc,hyddesc,derdesc];
%         idd = listdlg("ListString",depdesc,"PromptString",'Select hydraulic variable:',...
%                       'SelectionMode','single','ListSize',[200,350],...
%                       'Name','EDBtools');
%         if isempty(idd), depvar = []; plotxt = []; return; end  
% 
%     % idd = 6;
% 
%     switch depdesc{idd}
%         case 'Intertidal Area'
%             depvar = datadst.Smhw-datadst.Smlw; 
%             plotxt.ylabel = 'Intertidal area (m^2)' ;
%         case 'Intertidal Volume'
%             depvar = datadst.Vmhw-datadst.Vmlw-datadst.Smlw.*datadst.TidalRange; 
%             depvar(depvar<0) = NaN;
%             plotxt.ylabel = 'Intertidal volume (m^3)' ;
%         case hyddesc
%             depvar = hydrodst.(hydrodst.VariableNames{idd-length(datdesc)}); 
%             plotxt.ylabel = hydrodst.VariableLabels{idd-length(datdesc)};
%         otherwise
%             depvar = datadst.(datadst.VariableNames{idd}); 
%             plotxt.ylabel = datadst.VariableLabels{idd};
%     end
%     depnames = [datadst.VariableNames,hydrodst.VariableNames,{'Sfl','Vfl'}];
%     plotxt.varname = depnames{idd};
%     plotxt.title = datadst.Description; 
% end
% 
% %%
% function [indvar,plotxt] = getIndependentVariable(hydrodst,datadst,classdst,plotxt)
%     %select either a hydraulic variable or a derived variable
%     hyddesc = hydrodst.VariableDescriptions;
%     derdesc = {'Modified prism','Modified prism/Tidal range',...
%                'Prism/Basin area','Modified prism/Basin area',...
%                'Basin area','Modified Basin area',...
%                'Estimated Flat area','Estimated Flat volume'};
%     inddesc =[hyddesc,derdesc];
% 
%         idh = listdlg("ListString",inddesc,"PromptString",'Select hydraulic variable:',...
%                       'SelectionMode','single','ListSize',[200,300],...
%                       'Name','EDBtools');
%         if isempty(idh), indvar = []; return; end  
% 
%     %idh = 6;
% 
%     switch inddesc{idh}
%         case 'Basin area'
%             indvar = datadst.Smhw;
%             plotxt.xlabel = 'Basin area (m^2)' ;
%             plotxt.varname =sprintf('%s',plotxt.varname);
%         case 'Modified Basin area'  
%             idh = listdlg("ListString",inddesc(1:3),"PromptString",'Select hydraulic depth:',...
%                   'SelectionMode','single','ListSize',[200,300],...
%                   'Name','EDBtools');
%             if isempty(idh), indvar = []; return; end  
%             indvar = modifiedArea(datadst,hydrodst,classdst,idh);
%             plotxt.xlabel = 'Modified Basin area (m^2)' ;
%             plotxt.varname =sprintf('%s (%s)',plotxt.varname,hydrodst.VariableNames{idh});
%         case 'Estimated Flat area'
%             idh = listdlg("ListString",inddesc(1:3),"PromptString",'Select hydraulic depth:',...
%                   'SelectionMode','single','ListSize',[200,300],...
%                   'Name','EDBtools');
%             if isempty(idh), indvar = []; return; end  
%             Slw = modifiedArea(datadst,hydrodst,classdst,idh);
%             indvar = datadst.Smhw-Slw;
%             indvar(indvar<=0) = NaN;
%             plotxt.xlabel = 'Estimated Flat area (m^2)' ;
%             plotxt.varname =sprintf('%s',plotxt.varname);
%         case'Estimated Flat volume'
%             idh = listdlg("ListString",inddesc(1:3),"PromptString",'Select hydraulic depth:',...
%                   'SelectionMode','single','ListSize',[200,300],...
%                   'Name','EDBtools');
%             if isempty(idh), indvar = []; return; end  
%             Slw = modifiedArea(datadst,hydrodst,classdst,idh);
%             indvar = datadst.Smhw-Slw;
%             indvar(indvar<=0) = NaN;
%             indvar = indvar.*datadst.TidalRange;
%             plotxt.xlabel = 'Estimated Flat volume (m^3)' ;
%             plotxt.varname =sprintf('%s',plotxt.varname);
%         case 'Modified prism'     
%             mprism = modifiedPrism(datadst,hydrodst,classdst);
%             if isempty(mprism), indvar = []; return; end
%             indvar = mprism;
%             plotxt.xlabel = 'Modified prism (m^3)';
%             plotxt.varname = sprintf('%s',plotxt.varname);
%         case 'Modified prism/Tidal range'
%             mprism = modifiedPrism(datadst,hydrodst,classdst);
%             if isempty(mprism), indvar = []; return; end
%             indvar = mprism./datadst.TidalRange;
%             plotxt.xlabel = 'Modified prism/Tidal range (m^2)';
%             plotxt.varname = sprintf('%s',plotxt.varname);
%         case 'Prism/Basin area'
%             mprism = modifiedPrism(datadst,hydrodst,classdst);
%             if isempty(mprism), indvar = []; return; end
%             indvar = hydrodst.TidalPrism./datadst.Smhw;
%             plotxt.xlabel = 'Prism/Basin area (m)';
%             plotxt.varname = sprintf('%s',plotxt.varname);
%         case 'Modified prism/Basin area'
%             mprism = modifiedPrism(datadst,hydrodst,classdst);
%             if isempty(mprism), indvar = []; return; end
%             indvar = mprism./datadst.Smhw;
%             plotxt.xlabel = 'Modified prism/Basin area (m)';
%             plotxt.varname = sprintf('%s',plotxt.varname);
%         otherwise            
%             indvar = hydrodst.(hydrodst.VariableNames{idh}); 
%             plotxt.xlabel = hydrodst.VariableLabels{idh};
%     end  
%     nrec = sum(~isnan(indvar));
%     plotxt.title = sprintf('%s (N=%d)',plotxt.title,nrec);
% end

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
     %fprintf('%s(%s) Linear: %s: Power: %s\n',vartxt.varname,vartxt.xlabel,txtl,txtp)

     %add 1:1 line
     hold on
     mx = minmax(x);
     my = minmax(y);
     mm = [min([mx,my]),max([mx,my])];
     %if mm(1)<100; mm(1) = 100; end
     plot(ax,mm,mm,'--k','DisplayName','1:1','ButtonDownFcn',@godisplay)
     plot(ax,xp,yp,'-.k','DisplayName','Power law fit','ButtonDownFcn',@godisplay)
     plot(ax,xl,yl,':k','DisplayName','Linear (0 intercept)','ButtonDownFcn',@godisplay)
     hold off
     
     xlabel(vartxt.xlabel)
     ylabel(vartxt.ylabel)
     grid on
     axis square
     %xlim(mm); ylim(mm);
     legend('Location','northwest')
     title(vartxt.title)
     subtitle(sprintf('Linear: %s\nPower: %s',txtl,txtp))
end

%% 
function mprism = modifiedPrism(datadst,hydrodst,classdst)
    %modify the prism to take account of the channel length
    Le = datadst.Lchannel;  
    La = convergenceLength(datadst,classdst);

    % figure('Tag','PlotFig')
    % plot(Le,La,'x')
    % xlabel('Le'); ylabel('La');

    DelA = 1./(1-exp(-Le./La));
    mprism = DelA.*hydrodst.Pr;
end

%%
function marea = modifiedArea(datadst,hydrodst,classdst,idh)
    %modify the Smhw to take account of the channel length or convergence
    g = 9.81;
    Tp = 12.4;   %tidal period (hr)
    Hsel = hydrodst.(hydrodst.VariableNames{idh});

    %determine the tidal wavelength for channels and inlets/basins
    nest = height(datadst);
    fact = ones(nest,1); 
    for i=1:nest
        if ~strcmp(classdst.GeomorType{i},'Tidal inlet') && ...
                               ~strcmp(classdst.GeomorType{i},'Tidal flat')
            fact(i) = 0.25;  %use labmda/4 for channels and lambda for inlets
        end
    end
    lambda = fact.*sqrt(g*Hsel).*Tp*3600;

    %options for definition of length to scale 
    L = convergenceLength(datadst,classdst);
    %L = datadst.Lchannel;                 %alternative in spreadsheet
    %L = datadst.Smhw.^0.59;               %as used in spreadsheet
    marea = (L./lambda).*datadst.Smhw; 
end

%%
function La = convergenceLength(datadst,classdst)
    %estimate of convergence length based on surface area of basin
    nest = height(datadst);
    fact = ones(nest,1);   exponent = fact;
    for i=1:nest
        if ~isnan(datadst.TidalRange(i))
            %original spreadsheet analysis used exponent of 0.59 and
            %fact=0.5 for WS and exponent of 0.5 and fact=1 for the UK in:         
            %using fact=1e-3 subsequently found to give a
            %more linear fit for WS. In addition tidal inlets have exponent
            %of 1 (space filling) whereas linear channels have exponent of 0.6
            % scale = 1;
            if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
                         strcmp(classdst.GeomorType{i},'Tidal flat')
                % fact(i) = scale*(1+datadst.Smlw(i)/datadst.Smhw(i))/datadst.Wmouth(i);     
                fact(i) = 1/datadst.Wmouth(i); 
                % fact(i) = 1e-3;
            else
                exponent(i) = 0.5;
                % fact(i) = scale*(1+datadst.Smlw(i)/datadst.Smhw(i)); 
            end
           
        end           
    end
    La = fact.*datadst.Smhw.^exponent;
end



    
    
    
    