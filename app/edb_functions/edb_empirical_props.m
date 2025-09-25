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
            % remove badly defined estuaries 
            ide = [77,88,145];
            % remove cases with a/h<1 (if required)
            % idx = find(datadst.TidalRange./2./hydrodst.Hmtl>1);
            % ide = sort([ide,idx']);
        else
            ide = [];
        end

    answer = questdlg('Single or complex variable','Empirical','Single','Complex','Single');
    %select variables to plot
    plotxt.promptxt = '';
    ok = 0;
    while ok<1
        if strcmp(answer,'Single')
            %use observed values as the dependent variable and either 
            %hydraulic or derived values as the indpendent variable
            [depvar,indvar,plotxt] = singleVariables(datadst,hydrodst,classdst,plotxt);
            if isempty(indvar), ok = 1; continue; end
        else
            %use more than one variable to define dependent and/or
            %independent variables e.g. as ratios.
            [depvar,indvar,plotxt] = complexVariables(datadst,hydrodst,classdst,plotxt);
            if isempty(indvar), ok = 1; continue; end
        end

        %define point lables use estuary id
        labels = classdst.id;
        if isnumeric(labels)
            labels = num2str(labels);        %id used for point labels
        end
        
        %remove any estuaries to be excluded
        if ~isempty(ide)
            indvar(ide) = NaN;  %remove estuaries to be excluded
            depvar(ide) = NaN;
        end

        %generate plot
        empirical_plot(indvar,depvar,labels,plotxt)
        regressionOutput(indvar,depvar,plotxt);
    end
end

%%
function [depvar,indvar,plotxt] = singleVariables(datadst,hydrodst,classdst,plotxt)
    %use observed values as the dependent variable     
    plotxt.promptxt = 'Dependent (y) variable';
    [depvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt);
    if isempty(depvar), indvar = []; return; end 
    plotxt.ylabel = plotxt.label;
    plotxt.varname = plotxt.name;

    %use either hydraulic or derived values as the indpendent variable
    plotxt.promptxt = 'Independent (x) variable';
    [indvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt);        
    if isempty(indvar), return; end   
    plotxt.xlabel = plotxt.label;
    plotxt.varname = [plotxt.varname,' (',plotxt.name,')'];

    %add cases description to title
    nrec = sum(~isnan(depvar));
    plotxt.title = sprintf('%s (N=%d)',datadst.Description,nrec);
end

%%
function [depvar,indvar,plotxt] = complexVariables(datadst,hydrodst,classdst,plotxt)
    %use more than one variable to define dependent and/or independent
    %variables e.g. as ratios.
    depvar = []; indvar = [];
    promptxt = @(X) sprintf('%s\n(Quit for 1)',X);
    plotxt.promptxt = promptxt('Nominator for Dependent (y) variable');
    [varn,plotxtn] = getVariable(datadst,hydrodst,classdst,plotxt);
    if isempty(plotxtn), return; end  %user selected Quit

    plotxt.promptxt = promptxt('Denominator for Dependent (y) variable');
    [vard,plotxtd] = getVariable(datadst,hydrodst,classdst,plotxt);

    if isempty(varn) && isempty(vard)
        return;
    elseif isempty(varn)
        depvar = 1./vard;
        plotxt.ylabel = ['1 / ',plotxtd.label];
        plotxt.varname = ['1 / ',plotxtd.name];
    elseif isempty(vard)
        depvar = varn;
        plotxt.ylabel = plotxtn.label;
        plotxt.varname = plotxtn.name;
    else
        depvar = varn./vard;
        plotxt.ylabel = [plotxtn.label,' / ',plotxtd.label];
        plotxt.varname = [plotxtn.name,'/',plotxtd.name];
    end
    
    %now get independent variable
    plotxt.promptxt = promptxt('Nominator for Independent (x) variable');
    [varn,plotxtn] = getVariable(datadst,hydrodst,classdst,plotxt);

    plotxt.promptxt = promptxt('Denominator for Independent (x) variable');
    [vard,plotxtd] = getVariable(datadst,hydrodst,classdst,plotxt);

    if isempty(varn) && isempty(vard)
                return;
    elseif isempty(varn)
        indvar = 1./vard;
        plotxt.xlabel = ['1 / ',plotxtd.label];
        plotxt.varname = [plotxt.varname,' (1/',plotxtd.name,')'];
    elseif isempty(vard)
        indvar = varn;
        plotxt.xlabel = plotxtn.label;
        plotxt.varname = [plotxt.varname,' (',plotxtn.name,')'];
    else
        indvar = varn./vard;
        plotxt.xlabel = [plotxtn.label,' / ',plotxtd.label];
        plotxt.varname = [plotxt.varname,' (',plotxtn.name,'/',plotxtd.name,')'];
    end
    %add cases description to title
    nrec = sum(~isnan(depvar));
    plotxt.title = sprintf('%s (N=%d)',datadst.Description,nrec);
end

%%
function [var,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt)
    %select either a data variable or a derived variable
    promptxt = sprintf('Select %s:',plotxt.promptxt);
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
    derdesc = {'Sfl','Intertidal Area';...
               'Vfl','Intertidal Volume';...
               'Hfl','Intertidal Depth';...
               'Vbox','Intertidal Box';...
               'Sfl/(Shw+Slw)','Relative tidal flat area';...
               'a/h','Amplitude / depth ratio'}';
    vardesc =[datadesc,hydrodesc,derdesc(2,:)];
    promptxt = sprintf('Select %s',plotxt.promptxt);
    idv = listdlg("ListString",vardesc,"PromptString",promptxt,...
                  'SelectionMode','single','ListSize',[200,420],...
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
        case 'Intertidal Depth'
            Sfl = datadst.Smhw-datadst.Smlw; 
            Vfl = datadst.Vmhw-datadst.Vmlw-datadst.Smlw.*datadst.TidalRange; 
            Vfl(Vfl<0) = NaN;
            var = Vfl./Sfl;
            plotxt.label = 'Intertidal depth (m)' ;
        case 'Intertidal Box'
            var = datadst.Smhw.*datadst.TidalRange;
            plotxt.label = 'Intertidal box - 2a.Sfl (m)' ;
        case 'Relative tidal flat area'
            var = (datadst.Smhw-datadst.Smlw)./(datadst.Smhw+datadst.Smlw);
            plotxt.label = 'Relative tidal flat area (-)' ;
        case 'Amplitude / depth ratio'
            var = datadst.TidalRange./2./hydrodst.Hmtl;
            plotxt.label = 'Amplitude / Depth ratio' ;
        case hydrodesc
            var = hydrodst.(hydrodst.VariableNames{idv-length(datadesc)}); 
            plotxt.label = hydrodst.VariableLabels{idv-length(datadesc)};        
        otherwise
            var = datadst.(datadst.VariableNames{idv}); 
            plotxt.label = datadst.VariableLabels{idv};  
    end
    varnames = [datadst.VariableNames,hydrodst.VariableNames,derdesc(1,:)];                
    plotxt.name = varnames{idv};
end

%%
function [var,plotxt] = setDerivedVariable(datadst,hydrodst,classdst,plotxt)
    %set the derived variable based on user selection
    vardesc = {'mPr','Modified prism';...
               'mPrTr','Modified prism / Tidal range';...
               'mPrSb','Modified prism / Basin area';...
               'mSb','Modified Basin area';...
               'eSfl','Estimated Flat area';...
               'eVfl','Estimated Flat volume';...
               'eH','Estimated depth';...
               'eVlw','Estimated Channel volume';...
               'eVlw','Estimated Channel volume (Dronkers)';...
               'La','Convergence length'};
    % varnames = {'mPr','mPrTr','mPrSb','mSb','eSfl','eVfl','eH','eVlw','d-a','La'};
    promptxt = sprintf('Select %s',plotxt.promptxt);
    idv = listdlg("ListString",vardesc(:,2),"PromptString",promptxt,...
                  'SelectionMode','single','ListSize',[200,160],...
                  'Name','EDBtools');
    if isempty(idv), var = []; plotxt = []; return; end 
    plotxt.name = vardesc{idv,1};

    switch vardesc{idv,2}
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
        case 'Estimated depth'
            promptxt = {'Depth scaling coefficient'};
            inp = inputdlg(promptxt,'Depth',1,{'1'});
            if isempty(inp), return; end
            Dfact = str2double(inp{1});
            var = Dfact*datadst.TidalRange;
            plotxt.label = 'Estimated depth (m)';  
        case 'Estimated Channel volume'
            answer = questdlg('Option','Vlw','mPr','Slw','mPr-aSlw','mPr');
            switch answer
                case 'mPr'
                    var = modifiedPrism(datadst,hydrodst,classdst);                     
                case 'Slw'
                    idh = selectDepth(hydrodst);
                    if isempty(idh), var = []; return; end  
                    Slw = modifiedArea(datadst,hydrodst,classdst,idh);
                    La = convergenceLength(datadst,classdst);
                    % Le = datadst.Lchannel; 
                    var = Slw.^2./12./La;
                case 'mPr-aSlw'
                    idh = selectDepth(hydrodst);
                    if isempty(idh), var = []; return; end  
                    Slw = modifiedArea(datadst,hydrodst,classdst,idh);
                    mprism = modifiedPrism(datadst,hydrodst,classdst);
                    Smt = mprism./datadst.TidalRange;
                    if isempty(mprism), var = []; return; end
                    a = datadst.TidalRange/2;
                    var = mprism-a.*(Slw+Smt)/2;
                    var(var<=0) = NaN;
            end
            plotxt.name =sprintf('%s-%s',plotxt.name,answer);
            plotxt.label = 'Estimated Channel volume (m^3)';
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
        case 'Estimated Channel volume (Dronkers)'
            promptxt = {'Dronkers gamma:'};
            inp = inputdlg(promptxt,'Empirical',1,{'1.1'});  
            hm = datadst.Vmtl./datadst.Smtl;
            amp = datadst.TidalRange/2;
            r = zeros(size(hm));
            for i=1:length(hm)
                r(i,1) = hypsometry_exponent(hm(i),amp(i),str2double(inp{1}));
            end
            var = datadst.Vmtl./(r.*hm).*(r.*hm-amp).^r;
            var(var<0) = NaN;
            %plotxt.label = 'Vlw';
            plotxt.name =sprintf('%s-%s',plotxt.name,'gamma');
            plotxt.label = 'Estimated Channel volume (m^3)';
        case 'Convergence length'
            var = convergenceLength(datadst,classdst);
            plotxt.label = 'Convergence length';
        otherwise            
            var = hydrodst.(hydrodst.VariableNames{idv}); 
            plotxt.label = hydrodst.VariableLabels{idv};
    end   
    
end

%%
function idh = selectDepth(hydrodst)
    %select the hydraulic depth to use
    hydrodesc = hydrodst.VariableDescriptions;
    idh = listdlg("ListString",hydrodesc(1:3),"PromptString",'Select hydraulic depth:',...
                  'SelectionMode','single','ListSize',[200,100],...
                  'Name','EDBtools');
end

%%
function plotxt = setVarName(plotxt,hydrodst,idh)
    %if varname already set add hydraulic depth used for independent
    %variable
    if isfield(plotxt,'varname')
        plotxt.name =sprintf('%s (%s)',plotxt.name,hydrodst.VariableNames{idh});
    end
end

%%
function empirical_plot(x,y,Lid,vartxt)
    %plot selected empirical relationship    
    promptxt = 'Change axis scale (Log-y for exponential):';
    answer = questdlg(promptxt,'Log-axes','Linear','Log-Log','Log-y','Log-Log');
    labels = questdlg('Include labels?','Point labels','Yes','No','No');
   % labels = 'No';

    hf = figure('Resize','on','Tag','PlotFig');
    ax = axes(hf);
    hold on
    if strcmp(labels,'Yes')
        plot(ax,x,y,'o','Color',"#0072BD",'MarkerSize',11,...
                   'DisplayName',vartxt.varname,'ButtonDownFcn',@godisplay); 
        text(ax,x,y,Lid,'FontSize',6,'HorizontalAlignment','center','Clipping','on');   
    else
        plot(ax,x,y,'x','DisplayName',vartxt.varname,'ButtonDownFcn',@godisplay)
    end
    
    %data range
    mx = minmax(x);
    my = minmax(y);
    mm = [min([mx,my]),max([mx,my])];

    %adjust axes based on user selection
    if strcmp(answer,'Log-Log')
        ax.XScale = 'log';
        ax.YScale = 'log';
        [~,~,~,xp,yp,txtp] = regression_model(x,y,'power',100,false);
    elseif strcmp(answer,'Log-y')
        ax.YScale = 'log';
        [~,~,~,xp,yp,txtp] = regression_model(x,y,'exponential',100,false);
    else
        [~,~,~,xp,yp,txtp] = regression_model(x,y,'power',100,false);
    end
    [~,~,~,xl,yl,txtl] = regression_model(x,y,'linear0',100,false);
    %fprintf('%s(%s) Linear: %s: Power: %s\n',vartxt.varname,vartxt.xlabel,txtl,txtp)

    %add 1:1 line    
    
    %if mm(1)<100; mm(1) = 100; end
    if ~strcmp(answer,'Log-y')
        plot(ax,mm,mm,'--k','DisplayName','1:1','ButtonDownFcn',@godisplay)
    end
    plot(ax,xp,yp,'-.k','DisplayName','Power law fit','ButtonDownFcn',@godisplay)
    plot(ax,xl,yl,':k','DisplayName','Linear (0 intercept)','ButtonDownFcn',@godisplay)

    hold off

    xlabel(vartxt.xlabel)
    ylabel(vartxt.ylabel)
    grid on
    if strcmp(answer,'Log-Log')
        axis equal
        xlim(mm); ylim(mm);
    end

    legend('Location','northwest')
    title(vartxt.title)
    subtitle(sprintf('Linear: %s\nPower: %s',txtl,txtp))
end

%% 
function mprism = modifiedPrism(datadst,hydrodst,classdst)
    %modify the prism to take account of the channel length
    g = 9.81;
    Tp = 12.4;   %tidal period (hr)
    Le = datadst.Lchannel; 
    % LL = modifiedArea(datadst,hydrodst,classdst,2)./datadst.Smhw;
    % for i=1:length(Le)
    %     if strcmp(classdst.GeomorType(i),'Tidal inlet') ||  ...
    %                             strcmp(classdst.GeomorType{i},'Tidal flat')
    %         %Le(i) = datadst.Smhw(i)/Le(i);
    %         %Le(i) = datadst.Smhw(i)/datadst.Wmouth(i);
    %         %Le(i) = datadst.Smhw(i);
    %         Le(i) = Le(i)/10;
    %     end
    % end
    La = convergenceLength(datadst,classdst);

    % figure('Tag','PlotFig')
    % plot(Le,La,'x')
    % hold on
    % mm = [0,max(La)];
    % plot(mm,mm,'--k')
    % plot(mm,mm/3,':k')
    % xlabel('Le'); ylabel('La');

    %bespoke for Smt and Vmt - additional adjustment
    % omega = 2*pi/12.4/3600;
    % k = omega./sqrt(9.81*hydrodst.Hmlw);   %wave number
    % scale = abs(1./cos(k.*La));            %scaling for Smt

    %ah =  datadst.TidalRange./2./hydrodst.Hmtl;
    %ah=1;
    % k = 2*pi./sqrt(g*hydrodst.Hmtl)./Tp/3600;                          %wavenumber
    % ah = abs(cos(k.*La));
    %ah(ah<0)=NaN;

    for i=1:length(Le)
        r(i,1) = hypsometry_exponent(hydrodst.Hmtl(i),datadst.TidalRange(i)./2,2);
    end
    dinlet = r.*hydrodst.Hmtl;       
    nest = height(datadst);
    ad = ones(nest,1); 
    for i=1:nest
        if strcmp(classdst.GeomorType(i),'Tidal inlet') ||  ...
                                strcmp(classdst.GeomorType{i},'Tidal flat')
            ad(i) = datadst.TidalRange(i)/2/dinlet(i)/2;
        end
    end

    DelA = (1-exp(-Le./La));
    mprism = hydrodst.Pr./DelA.*ad;

    % figure('Tag','PlotFig')
    % plot(hydrodst.Pr,mprism,'x')
    % hold on
    % mm = [0,max(mprism)];
    % plot(mm,mm,'--k')
    % xlabel('Actual'); ylabel('Modified');    
    % 
    % hf = figure('Tag','PlotFig');
    % ax = axes(hf);
    % plot(hydrodst.Pr,ad,'x')
    % ax.XScale = 'log';
    % xlabel('Prism'); ylabel('2a/d');  
end

%%
function marea = modifiedArea(datadst,hydrodst,classdst,idh)
    %modify the Smhw to take account of the channel length or convergence
    g = 9.81;
    Tp = 12.4;   %tidal period (hr)
    Hsel = hydrodst.(hydrodst.VariableNames{idh});

    %determine the tidal wavelength for channels and inlets/basins
    lambda = sqrt(g*Hsel).*Tp*3600;       %wavelength
    k = 4./lambda;                     
    nest = height(datadst);
    for i=1:nest
        if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
                    strcmp(classdst.GeomorType{i},'Tidal flat')
            k(i) = k(i)/4;
        end
    end

    %options for definition of length to scale     
    %L = datadst.Lchannel;                 %alternative in spreadsheet
    %L = datadst.Smhw.^0.59;               %as used in spreadsheet
    L = convergenceLength(datadst,classdst);
    % ah =  datadst.TidalRange./2./hydrodst.Hmtl;
    %L = datadst.Smhw.^0.5;
    marea = k.*L.*datadst.Smhw; 
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
            %of 1 (space filling) whereas linear channels have exponent of 0.5
            if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
                    strcmp(classdst.GeomorType{i},'Tidal flat')
                fact(i) = (1+datadst.Smlw(i)/datadst.Smhw(i))/datadst.Wmouth(i);  %  /datadst.Lchannel(i);    %
                %fact(i) =1/datadst.Wmouth(i); % 1/datadst.Lchannel(i); 
                % fact(i) = 1e-3;
            else
                exponent(i) = 0.5;
                fact(i) = (1+datadst.Smlw(i)/datadst.Smhw(i));
            end
        end           
    end
    % fact = (1+datadst.Smlw./datadst.Smhw);
    % fact = 1;
    % exponent = 0.5;
    La = fact.*datadst.Smhw.^exponent;
end

%%
function r = hypsometry_exponent(hm,amp,gamma)
    %get fucntion to set the hypsometry exponent and central depth
    %using hydraulic depth and tidal amplitude for reaches
    if isnan(hm), r = NaN; return; end
    func = @(r) abs(((r.*hm+amp)/(r.*hm-amp))^(3-r)-gamma);
    options = optimset('TolX',1e-6);
    r = fminbnd(func,1,3,options);
end

%%
function regressionOutput(x,y,vartxt)
    %write the results to screen
    [~,~,~,~,~,txtp] = regression_model(x,y,'power',100,false);
    [~,~,~,~,~,txtl] = regression_model(x,y,'linear0',100,false);
    txtv = sprintf('%s - %s',vartxt.title,vartxt.varname);
    msg = sprintf('%s : Linear: %s | Power: %s\n',txtv,txtl,txtp);
    fprintf(msg)
end

    
    
    
    