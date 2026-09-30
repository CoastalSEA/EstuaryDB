function [var,idh] = edb_modified_variable_functions(datadst,hydrodst,classdst,option)
%
%-------function help------------------------------------------------------
% NAME
%   edb_modified_variable_functions.m   
% PURPOSE
%   get the modified variable based on user selection
% USAGE
%   [var,idh] = edb_modified_variable_functions(datadst,hydrodst,classdst,option)
% INPUTS
%   datadst - dstable of gross properties data
%   hydrodst - dstable of hyrdo-properties derived from gross properties
%   classdst - dstable of estuary classification
%   option - selected variable function to be returned
% OUTPUT
%   var - selected input variable
%   idh - return the index of the depth selected when relevant
%         1=low; 2=mean; 3=high
% NOTES
%   called from edb_set_derived_variable
%   THIS IS RESEARCH CODE AND SHOULD NOT BE USED FOR GENERAL APPLICATIONS
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
    idh = [];
    switch option
        case 'Modified basin area'
            idh = selectDepth(hydrodst);
            if isempty(idh), var = []; return; end  
            var = modifiedArea(datadst,hydrodst,classdst,idh);   
        case 'Modified prism'
            [var,idh] = modifiedPrism(datadst,hydrodst,classdst);
        case 'Modified prism / Tidal range'
            [var,idh]  = modifiedPrism4area(datadst,hydrodst,classdst);  
        case 'Estimated central depth'
            var = centralDepth(datadst,hydrodst);
        case 'Width Convergence length'
            var = width_convergenceLength(datadst,hydrodst,classdst);
        case 'Area Convergence length'
            var = area_convergenceLength(datadst,hydrodst,classdst);
        otherwise
            warndlg('Unkonwn selection in edb_modified_variable_functions')
    end
end

%%
function marea = modifiedArea(datadst,hydrodst,classdst,idh)
    %modify the Smhw to take account of the channel convergence
    g = 9.81;
    Tp = 12.4;   %tidal period (hr)
    Hsel = hydrodst.(hydrodst.VariableNames{idh});
    Smhw = datadst.Smhw;
    %determine the tidal wavelength for channels and inlets/basins
    lambda = sqrt(g*Hsel).*Tp*3600;       %wavelength
    L = width_convergenceLength(datadst,hydrodst,classdst);

    k = L./lambda;
    nest = numel(k);
    for i=1:nest
        if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
                    strcmp(classdst.GeomorType{i},'Tidal flat')
            Lbasin = Smhw(i)^0.58;
            k(i) = Lbasin/lambda(i);
        end
    end

    %options for definition of length to scale     
    %L = datadst.Lchannel;                 %alternative in spreadsheet
    %L = datadst.Smhw.^0.59;               %as used in spreadsheet    
    % ah =  datadst.TidalRange./2./hydrodst.Hmtl;
    %L = datadst.Smhw.^0.5;

    marea = k.*datadst.Smhw; 
end

%%
function [mprism,idh] = modifiedPrism(datadst,hydrodst,classdst)
    %modify the prism by the convergence length correction using LA or LW
    Le = datadst.Lchannel;
    Pr = hydrodst.Pr;  
    Tp = 12.4;                       %tidal period (hrs)
    omega = 2*pi/Tp/3600;            %angular frequency (1/s)
    Smhw = datadst.Smhw;
    Smlw = datadst.Smlw;
    amp = datadst.TidalRange/2;
    Hmtl = hydrodst.Hmtl;
    lambda = sqrt(9.81*Hmtl).*Tp*3600;       %wavelength
    k = 2*pi./lambda;                                 %wave number-
   
    % option to use observed values of convergence length if available
    isobs = false;
    if any(contains(datadst.VariableNames,'LW')) || any(contains(datadst.VariableNames,'LA'))
        useObs = questdlg('Use observed values','Modify prism','Yes','No','Yes');
        if strcmp(useObs,'Yes')
            isobs = true;
            idx = contains(datadst.VariableNames,'LA');
            varname = datadst.VariableNames{idx}; 
            L = datadst.(varname);
            U = mouthVelocity(L,Le,classdst);
            mprism = omega/2./U.*L.*(1-exp(-Le./L)).*Pr; %modified prism;
            return;
        end
    end

    %otherwise estimate convergence length LA for volume and LW for area
    [L,idh] = area_convergenceLength(datadst,hydrodst,classdst);
    U = mouthVelocity(L,Le,classdst);
    mprism = omega/2./U.*L.*(1-exp(-Le./L)).*Pr;         %modified prism
end

%%
function U = mouthVelocity(L,Le,classdst)
    %sel=4 uses sqrt(Smhw) otherwise use a full fit option
    %full fit has functions of L, kL and U based on FA94.
    omega = 2*pi/12.4/3600;                     %angular frequency (1/s)
    U = ones(size(L));  
    nest = numel(L);
    for j=1:nest
        if strcmp(classdst.GeomorType{j},'Tidal inlet') || ...
                strcmp(classdst.GeomorType{j},'Tidal flat')
            U = 0.54;
        else    
            %U(j) = 0.0045*L(j)^0.53;
            U(j) = 0.005*(Le(j)/L(j))^0.5*L(j)^0.42;
        end
    end
end

    % %otherwise estimate convergence length LA for volume and LW for area
    % if strcmp(answer,'Volume')
    %     [L,sel] = area_convergenceLength(datadst,hydrodst,classdst);
    %     U = mouthVelocity(L,Le,Smhw,k,amp,Hmtl,classdst,sel);
    %     mprism = omega/2./U.*L.*(1-exp(-Le./L)).*Pr;         %modified prism
    % else
    %     [L,sel] = width_convergenceLength(datadst,hydrodst,classdst);
    %     dprime = channelDamping(L,Le,Smhw,k,classdst,sel);    
    %     %dprime = 1;
    %     fact = dprime./(1-exp(-Le./L.*dprime));
    %     mprism = Pr.*fact.*(1-exp(-Le./L));                  %modified prism
    % end
    % %----------------------------------------------------------------------
    % function dprime = channelDamping(L,Le,Smhw,k,classdst,sel)
    %     dprime = ones(size(L));   %one used for estuaries, La->inf
    %     nest = numel(L);
    %     for j=1:nest
    %         % if strcmp(classdst.GeomorType{j},'Tidal inlet') || ...
    %         %         strcmp(classdst.GeomorType{j},'Tidal flat')
    %         if Le(j)/sqrt(Smhw(j))<2.5              %aspect ratio for inlets
    %             if sel==5                           %using L=sqrt(Smhw)
    %                 dprime(j) = 0.0046*L(j)^0.52;                  
    %             else
    %                 %dprime(j) = 0.000055*L(j);
    %                 %dprime(j) = 1.65*(k(j)*L(j))^1.02;
    %                 dprime(j) = 0.17*L(j)^0.18;
    % 
    %                 Leff = 0.118*L(j);
    %                 dprime(j) = 4.1e-5*Leff^1.21;
    % 
    %             end
    %         else
    %              if sel==5                          %using L=sqrt(Smhw)
    %                 dprime(j) = 0.67*L(j).^0.02;
    %              else
    %                 %dprime  = 1; is the default value 
    %                 %dprime(j) = 0.22*L(j).^0.17;
    %                 %dprime(j) = 1.34*(k(j)*L(j))^0.18;                    
    %             end               
    %         end
    %     end
    % end
    % %----------------------------------------------------------------------
    % function U = mouthVelocity(L,Le,Smhw,k,a,H,classdst,sel)
    %     %sel=4 uses sqrt(Smhw) otherwise use a full fit option
    %     %full fit has functions of L, kL and U based on FA94.
    %     omega = 2*pi/12.4/3600;                     %angular frequency (1/s)
    %     U = ones(size(L));  
    %     nest = numel(L);
    %     for j=1:nest
    %         % if strcmp(classdst.GeomorType{j},'Tidal inlet') || ...
    %         %         strcmp(classdst.GeomorType{j},'Tidal flat')
    %         if Le(j)/sqrt(Smhw(j))<2.5  %aspect ratio for inlets
    %             if sel==5                           %using L=sqrt(Smhw)           
    %                 U(j) = 1351*L(j).^-0.8;  
    %             else
    %                 %U(j) = 17.87*L(j)^-0.38;
    %                 %U(j) = 0.34*(k(j)*L(j))^-0.33;
    %                 U(j) = 147*L(j)^-0.6; %for L estimate excluding Hmtl 
    %             end
    %         else    
    %             %U(k) = 0.0008*L(k)^0.75; %incl Hayle
    %             %U(j) = 0.0016*L(j)^0.66;
    %             %U(j) = 2.93*(k(j)*L(j))^0.86;
    %             %U(j) = a(j)*omega*L(j)/H(j);
    %             U(j) = 0.0096*L(j)^0.44;  %for L estimate excluding Hmtl 
    %         end
    %     end
    % end


%%
function [p2a,idh] = modifiedPrism4area(datadst,hydrodst,classdst)
        %get the modified prism/tidal range
        Smhw = datadst.Smhw;
        Smlw = datadst.Smlw;
        Pr = hydrodst.Pr;  
        [L,idh] = width_convergenceLength(datadst,hydrodst,classdst);
        G = channelDamping(L,Smhw,Smlw,classdst);    
        p2a = G.*Pr./datadst.TidalRange;      %modified prism/2a
end

%%
function G = channelDamping(L,Smhw,Smlw,classdst)
    ids = Smlw<=eps;                 %remove Smlw=0
    Smlw(ids) = Smhw(ids); 
    nest = numel(L);
    for j=1:nest
        if strcmp(classdst.GeomorType{j},'Tidal inlet') || ...
                strcmp(classdst.GeomorType{j},'Tidal flat')
            G = 0.92*(Smlw./Smhw).^-0.194;
        else
            G = 1.09*(Smlw./Smhw).^0.165;             
        end
    end
end
%%
function depth = centralDepth(datadst,hydrodst)
    %central depth using hypsommetry and Dronkers gamma d = rH
    hm = hydrodst.Hmtl;
    amp = datadst.TidalRange/2;
    % gamma = inputdlg({'Dronker''s gamma:'},'Gamma',1,{'1.1'});
    % if isempty(gamma), gamma = {'1.1'}; end
    % gamma = str2double(gamma{1});
    gamma = 1.1;
    r = zeros(size(hm));
    for i=1:numel(hm)
        r(i) = hypsometry_exponent(hm(i),amp(i),gamma);
    end
    depth = r.*hm;
end

%%
function L = convergenceLength(datadst,hydrodst,classdst)
    %options for estimating convergence lengths
    method = questdlg('Select convergence length option','Convergence length',...
                      'Area','Width','Depth','Width');
    switch method
        case 'Area'
            L = area_convergenceLength(datadst,hydrodst,classdst);
        case 'Width'
            L = width_convergenceLength(datadst,hydrodst,classdst);
        case 'Depth'
            L = depth_convergenceLength(datadst,hydrodst,classdst);
    end
end
%%
function [LA,sel] = area_convergenceLength(datadst,hydrodst,classdst)
    %options for estimating the area convergence length
    hm = hydrodst.Hmtl;              %hydraulic depth (m) 
    amp =  datadst.TidalRange/2;     %tidal amplitude (m)
    aonh = amp./hm;
    Le = datadst.Lchannel;           %estuary length (m)
    Smhw = datadst.Smhw;
    Smlw = datadst.Smlw;
    ids = Smlw<=eps;                 %remove Smlw=0
    Smlw(ids) = Smhw(ids); 
    rS = Smlw./Smhw; 
    Qr = datadst.Qmean;
    idq = isnan(Qr) | Qr<1;
    Qr(idq) = 1;  %has no influence because 1/Qr=1
    exponent = 0.5;

    list = {'Full-CC','Full-C.ai','Full-exclH','Rounded','Smhw'};
    sel = listdlg('PromptString','Select AREA convergence length method',...
                     'Name','Convergence length','ListString',list,...
                     'ListSize',[160,200],'SelectionMode','single');
    if isempty(sel), LA = []; return; end

    switch list{sel}
        case 'Full-CC'
            C = 15; a = 0.42;  b = 0.76; c = 0.53; d = 0.13;     %Claude code training course
        case 'Full-C.ai'
            C = 2.5; a = 0.54;  b = 1.17; c = 0.58; d = 0.14;    %Claude ai
        case 'Full-exclH'
             C = 32; a = 0.32; b = 0;  c = 0.24; d = 0.11;       %CC excluding a/Html
        case 'Rounded'
            C = 5; a = 0.5;  b = 1.0; c = 0.5; d = 0.1;          %rounded values
    end

    if strcmp(list{sel},'Smhw')
        LA = datadst.Smhw.^exponent;
    else
        LA = C*Smhw.^a.*aonh.^b.*rS.^c.*(1./Qr).^d;
    end
end

%%
function [LW,sel] = width_convergenceLength(datadst,hydrodst,classdst)
    %options for estimating the width convergence length
    hm = hydrodst.Hmtl;              %hydraulic depth (m) 
    amp =  datadst.TidalRange/2;     %tidal amplitude (m)
    aonh = amp./hm;
    Le = datadst.Lchannel;           %estuary length (m)
    Smhw = datadst.Smhw;
    Smlw = datadst.Smlw;
    ids = Smlw<=eps;                 %remove Smlw=0
    Smlw(ids) = Smhw(ids); 
    rS = Smlw./Smhw;    
    Qr = datadst.Qmean;
    idq = isnan(Qr) | Qr<1;          %remove Qr<1
    Qr(idq) = 1;     %has no influence because 1/Qr=1
    exponent = 0.5;

    list = {'Full-CC','Full-C.ai','Full-exclH','Rounded','Smhw'};
    sel = listdlg('PromptString','Select WIDTH convergence length method',...
                     'Name','Convergence length','ListString',list,...
                     'ListSize',[160,200],'SelectionMode','single');
    if isempty(sel), LW = []; return; end

    switch list{sel}
        case 'Full-CC'
            C = 12; a = 0.50;  b = 1.31; c = 0.86; d = 0.18;     %Claude code training course
        case 'Full-C.ai'
            C = 9.5; a = 0.50;  b = 1.13; c = 0.73; d = 0.21;    %Claude ai
        case 'Full-exclH'
            C = 67; a = 0.31; b = 0;  c = 0.42; d = 0.15;        %CC excluding a/Html
        case 'Rounded'
            C = 10; a = 0.5;  b = 1.0; c = 0.5; d = 0.2;         %rounded values
    end

    if strcmp(list{sel},'Smhw')
        LW = datadst.Smhw.^exponent;
    else
        LW = C*Smhw.^a.*aonh.^b.*rS.^c.*(1./Qr).^d;
    end


                % out = call_estimateLW(datadst,hydrodst);
                % if strcmp(out(1).closureMethod,'prism')
                %     LW = [out(:).Lw_prism]';
                % else
                %     LW = [out(:).Lw_regime]';
                % end
    % list = {'Smhw','Prism','Dronkers','CKFA'};
    % sel = listdlg('PromptString','Select WIDTH convergence length method',...
    %                  'Name','Convergence length','ListString',list,...
    %                  'ListSize',[160,200],'SelectionMode','single');
    % if isempty(sel), LW = []; return; end
    % 
    % hm = hydrodst.Hmtl;              %hydraulic depth (m) 
    % amp =  datadst.TidalRange/2;     %tidal amplitude (m)
    % Le = datadst.Lchannel;           %estuary length (m)
    % Tp = 12.4;                       %tidal period (hrs)
    % omega = 2*pi/Tp/3600;            %angular frequency (1/s)
    % k  = omega./sqrt(9.81*hm);       %wave number
    % 
    % switch list{sel}
    %     case 'Smhw'
    %         fact = 1.0*(1+datadst.Smlw./datadst.Smhw);
    %         exponent = 0.5;
    %         LW = fact.*datadst.Smhw.^exponent;
    %     case 'Prism'
    %         out = call_estimateLW(datadst,hydrodst);
    %         LW = [out(:).Lw_prism]';
    % 
    % 
    %         % 
    %         % rf = 8*0.003/3/pi();             %estimate Cd.U=0.003 - after Dronkers Eq.A3    
    %         % 
    %         % U = 1.0;
    %         % phi = 1./Le./k;
    %         % delta = -0.005;                  %damping length La = LW/delta
    %         % 
    %         % varnames = datadst.VariableNames;
    %         % if any(strcmp(varnames,'Wmouth'))
    %         %     Hm = datadst.Amtl./datadst.Wmouth;
    %         % elseif any(strcmp(varnames,'W0mtl_it'))
    %         %     Hm = datadst.Amtl./datadst.W0mtl_it;
    %         % end
    %         % 
    %         % K = U.*Hm./amp./omega./sin(phi).*(1-pi.*amp.*cos(phi)./4./hm);            
    %         % LoK = Le./K;    
    %         % alpha = 1./LoK;
    %         % figure('Tag','PlotFig'); plot(Le,alpha,'x'); xlabel('Le'); ylabel('alpha');
    %         % 
    %         % lambW = lambertw(-LoK.*exp(-LoK));
    %         % idx = alpha<1;
    %         % LW = inf(size(Le));
    %         % LW(idx) = (1-delta).*Le(idx)./(LoK(idx)+lambW(idx));
    %     case 'Dronkers'
    %         %use Dronkers method to estimate convergence length
    %         % gamma = inputdlg({'Dronker''s gamma:'},'Gamma',1,{'1.1'});
    %         % if isempty(gamma), gamma = {'1.1'}; end
    %         % gamma = str2double(gamma{1});
    %         gamma = 1.1;
    %         nest = numel(hm);
    %         Am = datadst.Amtl;   if iscell(Am), Am = ones(nest,1)*1000; end
    %         Qr = datadst.Qhigh;  if iscell(Qr), Qr = ones(nest,1)*100; end
    %         Lw = zeros(nest,1);
    %         for i = 1:nest
    %             if isnan(hm(i))
    %                 Lw(i) = NaN;
    %             else
    %                 outable = channel_convergence(hm(i),amp(i),12.4,gamma,Qr(i),Am(i),Le(i));
    %                 if strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
    %                         strcmp(classdst.GeomorType{i},'Tidal flat')
    %                     Lw(i) = outable.LwS;
    %                 else
    %                     Lw(i) = outable.Lw;
    %                 end
    %             end
    %         end
    %         LW = Lw; return;
    %     case 'CKFA'
    %         %approximate width or area convergence length for given depth                      %wave number
    %         eH = pi()*amp/4./hm;                            %amplitude-depth ratio
    %         LW = 1./k.*atan2(2*eH./(1+eH.^2),(1-eH.^2)./(1+eH.^2)); %Eq.15 in Channel Form Solver note
    %         eL = 1-exp(-Le./LW);                              %length correction
    %         %inclusion of length adjustment
    %         if any(eH.^2+eL.^2-1>0)    
    %             idl = eH.^2+eL.^2-1>0;
    %             LW(idl) = 2./k(idl).* ...
    %                  atan((eH(idl)+sqrt(eH(idl).^2+eL(idl).^2-1))./(eL(idl)+1));  %Eq.16 in Channel Form Solver note
    %         end 
    % end    
end

%%
function LH = depth_convergenceLength(datadst)
    %options for estimating the width convergence length
    Le = datadst.Lchannel;
    varnames = datadst.VariableNames;
    if any(strcmp(varnames,'Wmouth'))
        Hm = datadst.Amtl./datadst.Wmouth;
    elseif any(strcmp(varnames,'W0mtl_it'))
        Hm = datadst.Amtl./datadst.W0mtl_it;
    end

    %find river CSA to estimate Ur
    river = riverProperties(datadst);
    hrv = river.Hr;

    % method = questdlg('Select DEPTH convergence length method','Convergence length',...
    %           'Exponential','Linear','Exponential');

    method = 'Exponential';
    switch method
        case 'Exponential'
            LH = -Le./(log(hrv./Hm));
        case 'Linear'
            LH = 1;
    end
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
function idh = selectDepth(hydrodst)
    %select the hydraulic depth to use
    hydrodesc = hydrodst.VariableDescriptions;
    idh = listdlg("ListString",hydrodesc(1:3),"PromptString",'Select hydraulic depth:',...
                  'SelectionMode','single','ListSize',[200,100],...
                  'Name','EDBtools');
end

%%
function river = riverProperties(datadst)
    %river depth and width
    Le = datadst.Lchannel;
    amp = datadst.TidalRange/2;
    Qr = datadst.Qhigh;
    d50 = datadst.d50;      %sediment grain size (m)
    tau = datadst.taucr;    %critical shear stress (Pa)
    rhos = 2650;            %density of sediment (kg/m3)
    rhow = 1025;            %density of water (kg/m3)
    nest = numel(amp);
    hrv = zeros(size(amp)); Wrv = hrv; Sr = hrv;

    for i = 1:nest 
        if Qr(i)>0
            Sr(i)  = 2*amp(i)/Le(i);   %energy slope at tidal limit (-); **estimate**
            [hrv(i),Wrv(i),~] = river_regime(Qr(i),Sr(i),d50(i),tau(i),rhos,rhow);
        else
            hrv(i) = 0;             %minimum channel if no flow
            Wrv(i) = 0;
        end
    end
    Arv = hrv.*Wrv;
    river = struct('Hr',hrv,'Wr',Wrv,'Ar',Arv,'Sr',Sr);
end

%%
function out = call_estimateLW(data,hydro)
    %call function to estimate convergence using the CTS analytical solution
    %see method_summary_Lw_estimation.md for details
    method = questdlg('Select convergence closure method','Convergence',...
                      'regime','prism','prism');% 'regime' or 'prism' (required, no default)
    Le = data.Lchannel;     %estuary length, mouth to tidal limit (m)
    %width at the mouth, x=0 (m)
    varnames = data.VariableNames;
    if any(strcmp(varnames,'Wmouth'))
        Wm = data.Wmouth;
    elseif any(strcmp(varnames,'W0mtl_it'))
        Wm = data.W0mtl_it;
    end
    Am = data.Amtl;  %cross-sectional area at the mouth, x=0 (m^2)
    hm = hydro.Hmtl;   %hydraulic depth used in the prism/discharge matching
            % argument (m). NOTE: distinct from Hm = Am/Wm used in
            % the STC dynamics - do not confuse the two.
    a = data.TidalRange/2;     %tidal amplitude at the mouth (m)
    T = 44714; %tidal period (s). e.g. M2: T = 44714 s = 12.42*3600.
          % (SI seconds are required for omega = 2*pi/T to be
          % dimensionally consistent with the rest of the model.)
    Qr = data.Qhigh;  %river discharge (m^3/s). Qr == 0 is a valid, meaningful
          % input (see "River-regime closure" below).
    WrMin = 20; %floor value for Wr (m), user-overridable, default 10
    ArMin = 10;  %floor value for Ar (m^2), user-overridable, default 10
          % Optional physical parameters
    rS = data.Smhw./data.Smlw;   %storage width ratio, default 1
    idr = rS>5; rS(idr) = 5;
    cd = 0.0025;   %drag/friction coefficient, default 0.0025
    g = 9.81;     %acceleration due to gravity (m/s^2), default 9.81
    isrun = 1; %logical, default true (see "Sensitivity
                % diagnostics" below; meaning depends on closureMethod)
    river = riverProperties(data);
    Sr =  river.Sr;  %river energy slope, for record/flagging only (-),
          % optional, default NaN (not used in any calculation)
    Wr = river.Wr;  %river-regime width at x=Le (m). Pass [] or NaN if not
          % available, or if Qr == 0.
    Ar = river.Ar;  %river-regime cross-sectional area at x=Le (m^2). Pass
          % [] or NaN if not available, or if Qr == 0.
    % Required/optional when closureMethod = 'prism'
    Shw =data.Smhw;   %S_HW  - basin planform area at high water (m^2)
    P = data.Vmhw-data.Vmlw;%P_target - given/measured tidal prism (m^3): the target that
                      % LA is solved to reproduce (see NOTES). Named P_target
                      % (not P) to keep it visually and semantically distinct
                      % from out.P, the pre-existing Lambert-W-reduction
                      % intermediate used only by closureMethod='regime'.
    hF = 'linear';    %hypsometryForm - 'linear' or 'FA1996', default 'FA1996'

    nest = numel(Le);
    for i=1:nest
            inp(i) = struct('Le', Le(i), 'Wm', Wm(i), 'Am', Am(i), 'hm', hm(i),...
                     'a', a(i),'Wr', Wr(i), 'Ar', Ar(i), 'Qr', Qr(i),'Sr',Sr(i), ...
                      'rS', rS(i),'S_HW',Shw(i),'P_target',P(i),'T', T, ...
                     'cd', cd, 'g', g,'WrMin',WrMin,'ArMin',ArMin,...
                     'closureMethod',method,'runSensitivity',isrun,...
                     'hypsometryForm',hF);
            out(i) = estimateLw(inp(i));
    end
end
