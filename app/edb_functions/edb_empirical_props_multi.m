function edb_empirical_props_multi(mobj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_empirical_props_multi.m
% PURPOSE
%   Function to get regressions for empirical and measured relationships
% USAGE
%   edb_empirical_props_multi(mobj)
% INPUTS
%   mobj - handle to EstuaryDB App
% OUTPUT
%   generates regression outputs to the command window
% NOTES
%   called from edb_user_tools in EstuaryDB
%   NB: hydraulic properties have to be added to dataset
%
% Author: Ian Townend
% CoastalSEA (c) June 2025
%--------------------------------------------------------------------------
%
    dataset = {'UK','WS'};
    tableoutput = table();
    for j = 1:2
        %Bespoke selection
        answer = dataset{j};
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
    
        types = {'Input','Derived'; 'Input','Input';'Derived','Derived'};

        indices(:,:,1) = [6,1;7,2;10,4];
        indices(:,:,2) = [6,22;7,23;10,13];
        k = 1;
        plotxt.promptxt = '';
        for i=1:3
            [depvar,indvar,plotxt] = singleVariables(datadst,hydrodst,classdst,...
                                     plotxt,types(k,:),indices(i,:,k));
            %remove any estuaries to be excluded
            if ~isempty(ide)
                indvar(ide) = NaN;  %remove estuaries to be excluded
                depvar(ide) = NaN;
            end
            tabout = regressionOutput(indvar,depvar,plotxt);
            tableoutput = [tableoutput;tabout]; %#ok<AGROW>
        end
    end
    sname = inputdlg('Sheet name:','Properties',1);
    writetable(tableoutput,'EDB_empirical_regression.xlsx',...
                           'WriteRowNames',true,'Sheet',sname{1});    
end

%%
function [depvar,indvar,plotxt] = singleVariables(datadst,hydrodst,classdst,plotxt,type,idv)
    %use observed values as the dependent variable     
    plotxt.promptxt = 'Dependent (y) variable';
    [depvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt,type{1},idv(1));
    if isempty(depvar), indvar = []; return; end 
    plotxt.ylabel = plotxt.label;
    plotxt.varname = plotxt.name;

    %use either hydraulic or derived values as the indpendent variable
    plotxt.promptxt = 'Independent (x) variable';
    [indvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt,type{2},idv(2));        
    if isempty(indvar), return; end   
    plotxt.xlabel = plotxt.label;
    plotxt.varname = [plotxt.varname,'(',plotxt.name,')'];

    %add cases description to title
    nrec = sum(~isnan(depvar));
    plotxt.title = sprintf('%s (N=%d)',datadst.Description,nrec);
end


%%
function [var,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt,type,idv)
    %select either a data variable or a derived variable
    if strcmp(type,'Input')
        %select variable from input data set
        [var,plotxt] = setInputVariable(datadst,hydrodst,plotxt,idv);        
    elseif strcmp(type,'Derived')
        %select variable from derived data set or create new variable       
        [var,plotxt] = setDerivedVariable(datadst,hydrodst,classdst,plotxt,idv);
    else
        var = []; plotxt = [];
    end
end

%%
function [var,plotxt] = setInputVariable(datadst,hydrodst,plotxt,idv)
    %set the input variable based on user selection
    datadesc = datadst.VariableDescriptions;
    hydrodesc = hydrodst.VariableDescriptions;
    derdesc = {'Intertidal Area','Intertidal Volume','Intertidal Depth',...
               'Intertidal Box', 'Relative tidal flat area',...
               'Amplitude / depth ratio'};
    vardesc =[datadesc,hydrodesc,derdesc];

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
    varnames = [datadst.VariableNames,hydrodst.VariableNames,...
                {'Sfl','Vfl','Hfl','Vbox','Sfl/(Shw+Slw)','a/h'}];
    plotxt.name = varnames{idv};
end

%%
function [var,plotxt] = setDerivedVariable(datadst,hydrodst,classdst,plotxt,idv)
    %set the derived variable based on user selection
    vardesc = {'Modified prism','Modified prism / Tidal range',...
               'Modified prism / Basin area',...
               'Modified Basin area',...
               'Estimated Flat area','Estimated Flat volume',...
               'Power law hypsometry ratio',...
               'Convergence length'};

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
        case 'Power law hypsometry ratio'
            promptxt = {'Dronkers gamma:'};
            inp = inputdlg(promptxt,'Empirical',1,{'1.1'});  
            hm = datadst.Vmtl./datadst.Smtl;
            amp = datadst.TidalRange/2;
            r = zeros(size(hm));
            for i=1:length(hm)
                r(i,1) = hypsometry_exponent(hm(i),amp(i),str2double(inp{1}));
            end
            var = (r.*hm-amp);
            plotxt.label = 'd-a';
        case 'Convergence length'
            var = convergenceLength(datadst,classdst);
            plotxt.label = 'Convergence length';
        otherwise            
            var = hydrodst.(hydrodst.VariableNames{idv}); 
            plotxt.label = hydrodst.VariableLabels{idv};
    end 

    varnames = {'mPr','mPrTr','mPrSb','mSb','eSfl','eVfl','d-a','La'};
    plotxt.name = varnames{idv};
end

%%
function idh = selectDepth(hydrodst)
    %select the hydraulic depth to use
    % hydrodesc = hydrodst.VariableDescriptions;
    % idh = listdlg("ListString",hydrodesc(1:3),"PromptString",'Select hydraulic depth:',...
    %               'SelectionMode','single','ListSize',[200,100],...
    %               'Name','EDBtools');
    idh = 1;
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
function tabout = regressionOutput(x,y,vartxt)
    %write the results to screen
    [ap,bp,Rp,~,~,txtp] = regression_model(x,y,'power',100,false);
    [al,bl,Rl,~,~,txtl] = regression_model(x,y,'linear0',100,false);
    txtv = sprintf('%s - %s',vartxt.title,vartxt.varname);
    msg = sprintf('%s : Linear: %s | Power: %s\n',txtv,txtl,txtp);
    fprintf(msg)

    %write output as a table
    tabout = table(al,bl,Rl,ap,bp,Rp,'RowNames',{txtv});
end

%-calculation code---------------------------------------------------------
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
                fact(i) = (1+datadst.Smlw(i)/datadst.Smhw(i))/datadst.Wmouth(i); %/datadst.Lchannel(i); %
                %fact(i) = 1/datadst.Lchannel(i); %1/datadst.Wmouth(i); %  
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
