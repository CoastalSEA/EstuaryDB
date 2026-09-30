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

    %ASSUME that hydro dataset is in the same muiTableImport
    %object as a struct of datasets        
    promptxt = 'Select observed data for empirical relationships:';
    [cobj,~,datasets,idd] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);
    if isempty(idd), return; end        
    datadst = cobj.Data.(datasets{idd});   %selected observed variable dataset


    answer = questdlg(sprintf('Empirical properties requires tabular datasets for gross properties,\nclassification and derived hydraulic properties'),...
                       'Select data','Continue','Quit','Continue');
    if strcmp(answer,'Quit'), return;  end

    fnames = fieldnames(cobj.Data);
    promptxt = 'Select hydraulic properties to use:';
    hsel = listdlg("PromptString",promptxt,"ListSize",[200,160],...
                         "SelectionMode","single","ListString",fnames);
    if isempty(hsel), return; end
    hydrodst = cobj.Data.(fnames{hsel});  %selected hydraulic variable dataset 
    
    promptxt = 'Select classifiction properties to use:';
    [ccobj,~,cnames,idc] = selectCaseDataset(mobj.Cases,[],{'muiTableImport'},promptxt);            
    if isempty(idc), return; end
    classdst = ccobj.Data.(cnames{idc});  %selected classification variable dataset 

    %option to remove selected estuaries from the dataset
    answer = questdlg('Mask dataset','Mask','Yes','No','Yes');
    if strcmp(answer,'Yes')
        estdesc = datadst.RowNames;
        ide = listdlg("ListString",estdesc,"PromptString",'Select estuaries to omit:',...
                      'SelectionMode','multiple','ListSize',[160,200],...
                      'Name','EDBtools');
    else
        ide = [];
    end
    % end

    % answer = questdlg('Single or complex variable','Empirical','Single','Complex','Single');
    % %select variables to plot
    % plotxt.promptxt = '';
    ok = 0;
    while ok<1

        [depvar,indvar,plotxt] = edb_get_variables(datadst,hydrodst,classdst);
                                                         
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
        edb_empirical_plot(indvar,depvar,labels,plotxt)

        answer = questdlg('Select another dataset?','Empirical','Select','Quit','Select');
        if  strcmp(answer,'Quit'), ok = 1; continue; end   
    end
end

%% 
function mprism = modifiedPrism(datadst,hydrodst,classdst,isvol)
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
    options = {'Smhw','Prism'};
    LA = convergenceLength(datadst,hydrodst,classdst,options{2});
    Lw = LA;
    DelA = (1-exp(-Le./LA));
    DelW = (1-exp(-Le./Lw));
    omega = 2*pi/Tp/3600;
    %k = omega./sqrt(g*hydrodst.Hmlw);   %wave number @LW
    k = omega./sqrt(g*hydrodst.Hmtl);    %wave number @MT
    eh =  datadst.TidalRange./2./hydrodst.Hmtl;

    % figure('Tag','PlotFig')
    % plot(Le,La,'x')
    % hold on
    % mm = [0,max(La)];
    % plot(mm,mm,'--k')
    % plot(mm,mm/3,':k')
    % xlabel('Le'); ylabel('La');


    nest = height(datadst);
    %La = inf(nest,1); 
    La = Le;
    phi = k.*LA;
    for i=1:nest
        if contains(classdst.Description,'WS') && ...
                strcmp(classdst.GeomorType(i),'Tidal inlet') %||  ...
                               %strcmp(classdst.GeomorType{i},'Tidal flat')
            La(i) = LA(i)/2;   %(datadst.Smhw(i)-datadst.Smlw(i))/Le(i)
            %phi(i) =k(i)*La(i); 
        end
    end



    if isvol
        U = 1; %assume U = 1m/s
        denom = U*(4-pi.*eh.*sin(phi));
        nom = 2*omega*LA.*DelA;
        fact = nom./denom;
    else
        X = (1-exp(Le./La-Le./Lw))./(1-Lw./La)./DelW;
        fact = abs(1./cos(phi)./X);               %scaling for Smt
    end

    mprism = fact.*hydrodst.Pr;
    

    % for i=1:length(Le)
    %     r(i,1) = hypsometry_exponent(hydrodst.Hmtl(i),datadst.TidalRange(i)./2,2);
    % end
    % dinlet = r.*hydrodst.Hmtl;       
    % nest = height(datadst);
    % ad = ones(nest,1); 
    % for i=1:nest
    %     if strcmp(classdst.GeomorType(i),'Tidal inlet') ||  ...
    %                             strcmp(classdst.GeomorType{i},'Tidal flat')
    %         % ad(i) = datadst.TidalRange(i)/2/dinlet(i)/2;  %a/2d
    %         % ad(i) = datadst.TidalRange(i)/dinlet(i);      %2a/d
    %     end
    % end

    
    

    
    %check plots
    % figure('Tag','PlotFig')
    % plot(hydrodst.Pr,mprism,'x')
    % hold on
    % mm = [0,max(mprism)];
    % plot(mm,mm,'--k')
    % xlabel('Actual prism'); ylabel('Modified prism');    

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
    % ah =  datadst.TidalRange./2./hydrodst.Hmtl;
    %L = datadst.Smhw.^0.5;

    L = convergenceLength(datadst,hydrodst,classdst);
    marea = k.*L.*datadst.Smhw; 
end

%%
function Lconv = convergenceLength(datadst,hydrodst,classdst,option)
    %estimate of convergence length based on surface area of basin
    % nest = height(datadst); fact = ones(nest,1);   Lw = zeros(nest,1);

    switch option
        case 'Smhw'
            fact = 1.0*(1+datadst.Smlw./datadst.Smhw);
            exponent = 0.5;
            Lconv = fact.*datadst.Smhw.^exponent;
        case 'Prism'
            hm = hydrodst.Hmtl;              %hydraulic depth (m) 
            amp =  datadst.TidalRange/2;     %tidal amplitude (m)
            Le = datadst.Lchannel;           %estuary length (m)
            Tp = 12.4;                       %tidal period (hrs)
            omega = 2*pi/Tp/3600;            %angular frequency (1/s)
            k  = omega./sqrt(9.81*hm);       %wave number
            rf = 8*0.003/3/pi();             %estimate Cd.U=0.003 - after Dronkers Eq.A3    

            U = 1.0;
            varnames = datadst.VariableNames;
            if any(strcmp(varnames,'Wmouth'))
                Hm = datadst.Amtl./datadst.Wmouth;
            elseif any(strcmp(varnames,'W0mtl_it'))
                Hm = datadst.Amtl./datadst.W0mtl_it;
            end
            phi = 1./Le./k;
            delta = -0.005;               %damping length La = LW/delta
    
            K = U.*Hm./amp./omega./sin(phi).*(1-pi.*amp.*cos(phi)./4./hm);            
            LoK = Le./K;    
            alpha = 1./LoK;
            figure('Tag','PlotFig'); plot(Le,alpha,'x'); xlabel('Le'); ylabel('alpha');
            
            lambW = lambertw(-LoK.*exp(-LoK));
            idx = alpha<1;
            Lconv = inf(size(Le));
            Lconv(idx) = (1-delta).*Le(idx)./(LoK(idx)+lambW(idx));
    end

    %use dronkers method to estimate convergence length
    % gamma = 1.1; 
    % hm = hydrodst.Hmtl;
    % amp = datadst.TidalRange/2;
    % Am = datadst.Amtl;   if iscell(Am), Am = ones(nest,1)*1000; end
    % Qr = datadst.Qhigh; if iscell(Qr), Qr = ones(nest,1)*100; end
    % for i = 1:nest
    %     if isnan(hm(i))
    %         Lw(i) = NaN;
    %     else
    %         [Lwf,U,Lws] = channel_convergence(hm(i),amp(i),12.4,gamma,Qr(i),Am(i));
    %         if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
    %                 strcmp(classdst.GeomorType{i},'Tidal flat')
    %             Lw(i) = Lws;
    %         else
    %             Lw(i) = Lwf;
    %         end
    %     end
    % end
    % La = Lw; return;

    % for i=1:nest
    %     if ~isnan(datadst.TidalRange(i))
    %         %original spreadsheet analysis used exponent of 0.59 and
    %         %fact=0.5 for WS and exponent of 0.5 and fact=1 for the UK in:         
    %         %using fact=1e-3 subsequently found to give a
    %         %more linear fit for WS. In addition tidal inlets have exponent
    %         %of 1 (space filling) whereas linear channels have exponent of 0.5
    %         if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
    %                 strcmp(classdst.GeomorType{i},'Tidal flat')
    %             fact(i) = (1+datadst.Smlw(i)/datadst.Smhw(i))/datadst.Wmouth(i);  %  /datadst.Lchannel(i);    %
    %             %fact(i) =1/datadst.Wmouth(i); % 1/datadst.Lchannel(i); 
    %             % fact(i) = 1e-3;
    %         else
    %             exponent(i) = 0.5;
    %             fact(i) = (1+datadst.Smlw(i)/datadst.Smhw(i));
    %         end
    %     end           
    % % end
    % fact = 1.0*(1+datadst.Smlw./datadst.Smhw);
    % % fact = 1;
    % exponent = 0.5;
    % La = fact.*datadst.Smhw.^exponent;
end



    
    
    
    