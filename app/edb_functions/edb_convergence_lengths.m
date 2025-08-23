function [La,Lw] = edb_convergence_lengths(dst,Le,param,idx)
    


%REWORK DERIVATION TO JUST CONSIDER La AND Lw 
%CAN THIS BE DONW WITHOUT SOIL PROPERTIES?



% INPUTS
%   inp - struc with the following fields:
%         amp - tidal amplitude (m)
%         omega - angular frequency, 2pi/Tp (1/s)
%         Le - estuary length (m)
%         rhow - density of water (kg/m^3)
%         gamma - Dronkers tidal asymetry coefficient (-)
%         d50 - median sediment grain size diameter (m)
%      	  rhoc - suspended sediment concentration (kg/m^3)
%         ws - sediment fall velocity (m/s)
%         taucr - critical threshold bed shear stress (Pa)
%         me - erosion rate coeficient (kg/N/s)
%         g - acceleration due to gravity (m/s2)
%   if waves are included:
%         Uw - wind speed (m/s)
%         zw - elevation of wind speed (m) - default is 10mz

inp = form_solver_parameters(dst,Le,param,idx);
%intial guess of hydraulic depth, hm
hme = inp.amp*2;        %av. for UK=1.6x and WS=3x 
% Version based on mk2 solver
    %inp.isDronk = true; %hard coded options for gamma of Le/lambda
    inp.gamma = inp.Le/(sqrt(inp.g*hme)*12.4*3600); inp.isDronk = false;


    
    fhm = @(X) fun_hm(inp,X);
    %unconstrained optimisation
    options = optimset('MaxIter',1000,'TolFun',1e-9,'TolX',1e-6);
    [hm,~,ok] = fminsearch(fhm,hme,options);    %find minimum of fhL
    if ok<1, La = NaN; Lw = NaN; return; end 

    inp.gamma = inp.Le/(sqrt(inp.g*hm)*12.4*3600);

    r = hypsometry_exponent(inp.amp,hm,inp.gamma,inp.isDronk);
    Lw = widthConvergence(inp,hm,r);
    La = areaConvergence(inp,hm,Lw,r);
end

%%
function fy = fun_hm(inp,hme)
    % Find the hydraulic depth based on a balance of erosion and deposition 
    % with Uc determined from the hydraulics and Lw from equating
    % hydraulic and geometric prism estimates
    r = hypsometry_exponent(inp.amp,hme,inp.gamma,inp.isDronk);
    Lw = widthConvergence(inp,hme,r);
    La = areaConvergence(inp,hme,Lw,r);

    U_fun = @(h,L) inp.amp*inp.omega*L/h;              %U=a.w.La/hm
    Cd_fun = @(h) frictionCoeff(inp,h);                %Cd
    Tau_fun = @(h,L) inp.rhow*Cd_fun(h)*U_fun(h,L)^2;  %tau = rho.Cd.U^2
    tau = Tau_fun(hme,La);

    if inp.Uw>0                                  %winds included
        Wm = inp.Wrv*exp(inp.Le*inp.cLw/Lw);
        Fch = sqrt(2)*inp.Cwe*Wm;  %Cwe=0.6 for Lw/2 -> 0.6Wm, 
        [Hs, Tp, ~] = tma_spectrum(inp.Uw,inp.zw,Fch,hme,hme);
        Hrms = Hs/sqrt(2);
        [La,~] = waveConvergence(inp,hme,La,Lw,Uc);
        Uc  = inp.amp*inp.omega*La/hme;          %tidal velocity amplitude
        %shear stress under combined + aligned waves and current
        tauall = tau_bed(hme,inp.d50,inp.visc,inp.rhow,Uc,Hrms,Tp,0);
        tau = tauall.taur;
    end

    %estimate of erosion
    if tau>inp.taucr
        ero = (tau-2*inp.taucr)*(pi/2-asin(sqrt(inp.taucr/tau)));
        ero = inp.me/pi*(ero+sqrt(inp.taucr*(tau-inp.taucr)));
    else
        ero = 0;
    end
    %estimate of deposition
    sed = inp.rhoc*inp.ws;

    fy = abs(ero-sed);                     %balance of erosion and depostion
end

%%
function Lw = widthConvergence(inp,hm,r)
    %approximate width or area convergence length for given depth 
    k  = inp.omega/sqrt(inp.g*hm);                  %wave number
    beta = ((r*hm-inp.amp)/(r*hm))^(r-1);           %stream width ratio
    eH = pi()*inp.amp*beta/4/hm;                    %amplitude-depth ratio

    Lw = 1/k*atan2(2*eH/(1+eH^2),(1-eH^2)/(1+eH^2));%width covergence length
    eL = 1-exp(-inp.Le/Lw);                         %length correction
    %inclusion of length adjustment
    if eH^2+eL^2-1>0      
        fact1 = sqrt(eH^4+eH^2*eL^2-eH^2);        
        fact2 = eH^2+eL^2;
        term1 = -(eL*(1+fact1)/fact2-1)/eH;
        term2 = (eL+fact1)/fact2;
        LwA = 1/k*atan2(term1,term2);

        term3 = -(eL*(1-fact1)/fact2-1)/eH;
        term4 = -(-eL+fact1)/fact2;
        LwB = 1/k*atan2(term3,term4);

        Lw = max(LwA,LwB);
    end   

    % Lw = 2/k*atan(eH);                              %width covergence length
    %for the cases examined this is the same as:
    % Lw = 1/k*atan2(2*eH/(1+eH^2),(1-eH^2)/(1+eH^2));
    %which simiplifies to Lw = 1/k*atan(2*eH/(1-eH^2)) for eH<1
    % if eH<1
    %     Lw = 1/k*atan(2*eH/(1-eH^2));      %width overgence length
    % else
    %     Lw = 2/k*atan(eH);                 %width covergence length     
    %inclusion of length adjustment ie only assume La=Lw
    % eL = 1-exp(-inp.Le/Lw);
    % if eH^2+eL^2-1>0       
    %     Lw = 2/k*atan((eH+sqrt(eH^2+eL^2-1))/(eL+1));
    % end

    Lw(Lw<0) = 0;
end

%%
function La = areaConvergence(inp,hm,Lw,r)
    %approximate area convergence length for given depth and width
    %convergence 
    %k = inp.omega/sqrt(inp.g*hm);                   %wave number  
    k = @ (LA) waveNumber(inp,hm,LA,r);                    %wave number
    fLa = @(LA) Lw*cos(mod(k(LA)*LA,pi/2))-LA;
    %unconstrained optimisation
    options = optimset('MaxIter',1000,'TolFun',1e-9,'TolX',1e-6);
    [La,~,ok] = fzero(fLa,Lw,options);    %find minimum of fhL
    if ok<1, La = Lw; end 
end

%%
function Cd = frictionCoeff(inp,h)
    %drag coefficient for water depth,h, using, d50, taucr, visc, rhow
    if h<=0, Cd=0; return; end
    %smooth turbulent current 
    a    = 0.0001615; b=6; c=-0.08;
    fact = inp.taucr/inp.rhow/a.*(h/inp.visc).^2;
    A    = b*c/2*(fact).^(c/2);
    LW   = lambertw(A);
    ucs  = sqrt(((inp.visc./h).^2).*exp(log(fact)-2*LW/c));
    cds  = a*exp(b*(ucs.*h/inp.visc).^c);
    %rough turbulent current
    zo  = inp.d50/12;
    cdr  = (0.4./(log(h/zo)-1)).^2;
    ucr = sqrt(inp.taucr/inp.rhow./cdr);
    if ucr<ucs, Cd = cdr; else, Cd = cds; end
end

%%
function [r,gma] = hypsometry_exponent(amp,Hm,gamma,isDronk)
    %get function to set the hypsometry exponent and central depth
    %using hydraulic depth and tidal amplitude for reaches
    if isDronk  %uses Dronkers gamma
        func = @(r) abs(((r*Hm+amp)/(r*Hm-amp))^(3-r)-gamma);
    else        %uses length-wave length ratio
        func = @(r) abs(((r*Hm-amp)/(r*Hm+amp))^(r-1)-gamma);
    end
    options = optimset('TolFun',1e-9,'TolX',1e-9);
    r = fminbnd(func,1,3,options);
    gma = ((r*Hm+amp)/(r*Hm-amp))^(3-r);
end
%--------------------------------------------------------------------------
% Version based on mkX solver
% 
%     %intial guess of hydraulic depth, hm, and convergence length, La
%     hme = inp.amp*2;        %av. for UK=1.6x and WS=3x 
%     Lae = inp.Le/2;
%     fhm = @(X) fun_hm(inp,X);
%     %unconstrained optimisation
%     options = optimset('MaxIter',1000,'TolFun',1e-9,'TolX',1e-6);
%     %[hm,~,ok] = fminsearch(fhm,hme,options);    %find minimum of fhL
%     [Xout,~,ok] = fminsearch(fhm,[hme,Lae],options);    %find minimum of fhL
%     if ok<1, La = NaN; Lw = NaN; return; end 
%     hm = Xout(1); La = Xout(2);
% 
%     if La>0
%         r = hypsometry_exponent(inp.amp,inp.gamma,hm);
%         Lw = widthConvergence(inp,hm,La,r);
%     else
%         La = NaN;
%         Lw = NaN;
%     end
% end
% 
% %%
% function fy = fun_hm(inp,X)
%     % Find the hydraulic depth hm=X(1) and convergence length La=X(2) 
%     % based on a balance of erosion and deposition with Uc determined 
%     % from the hydraulics
%     hme = X(1); La = X(2);
% 
%     U_fun = @(h,L) inp.amp*inp.omega*L/h;
%     Cd_fun = @(h) frictionCoeff(inp,h);
%     Tau_fun = @(h,L) inp.rhow*Cd_fun(h)*U_fun(h,L)^2;
%     tau = Tau_fun(hme,La);
% 
%     % if inp.Uw>0                            %winds included
%     %     r = hypsometry_exponent(inp,hme);
%     %     Lw = widthConvergence(inp,hme,La,r);
%     %     L = area_convergence(inp,hme);
%     %     Wm = inp.Wrv*exp(inp.Le*inp.cLw/L.La0);
%     %     Fch = sqrt(2)*inp.Cwe*Wm;  %use Lw/2 -> 0.6Wm
%     %     [Hs, Tp, ~] = tma_spectrum(inp.Uw,inp.zw,Fch,hme,hme);
%     %     Hrms = Hs/sqrt(2);
%     %     Uc0  = U_fun(hme,La);   %tidal velocity amplitude
%     %     [La,~] = waveConvergence(inp,hme,La,L.La0,Uc0);       
%     %     Uc  = U_fun(hme,La);   %tidal velocity amplitude
%     %     %shear stress under combined + aligned waves and current
%     %     tauall = tau_bed(hme,inp.d50,inp.visc,inp.rhow,Uc,Hrms,Tp,0);
%     %     tau = tauall.taur;
%     % end
% 
%     if tau>inp.taucr
%         ero = (tau-2*inp.taucr)*(pi/2-asin(sqrt(inp.taucr/tau)));
%         ero = inp.me/pi*(ero+sqrt(inp.taucr*(tau-inp.taucr)));
%     else
%         ero = 0;
%     end
%     %estimate of deposition
%     sed = inp.rhoc*inp.ws;
% 
%     fy = abs(ero-sed);                     %balance of erosion and depostion
% end


% 
% 
%%
% function Lw = widthConvergence(inp,hm,r)
%     %approximate width or area convergence length for given depth 
%     k  = inp.omega/sqrt(inp.g*hm);                  %wave number
%     beta = ((r*hm-inp.amp)/(r*hm))^(r-1);           %stream width ratio
%     eH = pi()*inp.amp*beta/4/hm;                    %amplitude-depth ratio
% 
%     Lw = 1/k*atan2(2*eH/(1+eH^2),(1-eH^2)/(1+eH^2));%width covergence length
%     eL = 1-exp(-inp.Le/Lw);                         %length correction
%     %inclusion of length adjustment
%     if eH^2+eL^2-1>0      
%         fact1 = sqrt(eH^4+eH^2*eL^2-eH^2);        
%         fact2 = eH^2+eL^2;
%         term1 = -(eL*(1+fact1)/fact2-1)/eH;
%         term2 = (eL+fact1)/fact2;
%         LwA = 1/k*atan2(term1,term2);
% 
%         term3 = -(eL*(1-fact1)/fact2-1)/eH;
%         term4 = -(-eL+fact1)/fact2;
%         LwB = 1/k*atan2(term3,term4);
% 
%         Lw = max(LwA,LwB);
%     end   
% 
%     % Lw = 2/k*atan(eH);                              %width covergence length
%     %for the cases examined this is the same as:
%     % Lw = 1/k*atan2(2*eH/(1+eH^2),(1-eH^2)/(1+eH^2));
%     %which simiplifies to Lw = 1/k*atan(2*eH/(1-eH^2)) for eH<1
%     % if eH<1
%     %     Lw = 1/k*atan(2*eH/(1-eH^2));      %width overgence length
%     % else
%     %     Lw = 2/k*atan(eH);                 %width covergence length     
%     %inclusion of length adjustment ie only assume La=Lw
%     % eL = 1-exp(-inp.Le/Lw);
%     % if eH^2+eL^2-1>0       
%     %     Lw = 2/k*atan((eH+sqrt(eH^2+eL^2-1))/(eL+1));
%     % end
% 
%     Lw(Lw<0) = 0;
% end

%%
% function fy = fun_Lw_eq14(inp,hm,Lw,La,r)
%     %find width convergence length for given hm, La and r
%     k = waveNumber(inp,hm,La,r);                    %wave number
%     beta = ((r*hm-inp.amp)/(r*hm))^(r-1);           %stream width ratio
%     eH = pi()*inp.amp*beta/4/hm;                    %amplitude-depth ratio
%     eL = (1-exp(-inp.Le/Lw));                       %length correction
%     fy = Lw*eL-La*((1-eH*sin(k*La))/cos(k*La));     %eq.14
% end

% % %%
% function r = hypsometry_exponent(amp,gamma,Hm)
%     %get function to set the hypsometry exponent and central depth
%     %using hydraulic depth and tidal amplitude for reaches
%     func = @(r) abs(((r*Hm+amp)/(r*Hm-amp))^(3-r)-gamma);
%     options = optimset('TolX',1e-6);
%     r = fminbnd(func,1,3,options);
% end

%%
function k = waveNumber(inp,hm,La,r)
    %compute the wave number based on Eq.23 in F&A'94
    Cr = (8/3/pi/inp.g)*(inp.amp*inp.omega^2);      %constants
    beta = ((r*hm-inp.amp)/(r*hm))^(r-1);           %stream width ratio
    Cd = frictionCoeff(inp,hm);                     %friction coefficient
    k = Cr*beta*Cd*La^2/hm^3;                       %wave number
end


%%
function params = form_solver_parameters(dst,Le,param,idx)
    %intialise the properties required for the tidal_form_solver function
    %minimum parameter set for solution

    %default model constants
    g = 9.81;
    rhow = 1025;
    rhos = 2650;
    visc = 1.36e-6; 
    tp = 12.4*3600;
    omega = 2*pi()/tp;  %angular frequency (1/s)
    me = 0.002;    %mass erosion coefficient

    %model default values (* - not used in edb version)   
    amp = dst.TidalRange(idx)/2;

    %default values
    d50 = 0.0002;
    rhoc = 40;
    taucr = 0.175;     
    varnames = dst.VariableNames;
    if any(strcmp(varnames,'d50')) && ~isempty(dst.d50(idx))
        d50 = dst.d50;
    end
    %
    if any(strcmp(varnames,'rhoc')) && ~isempty(dst.rhoc(idx))
        rhoc = dst.rhoc;
    end
    %
    if any(strcmp(varnames,'taucr')) && ~isempty(dst.taucr(idx))
        taucr = dst.taucr;
    end

    % calc fall velocity.  Mud Manual, eqn 5.7 including floculation
    ws = settling_velocity(d50,g,rhow,rhos,visc,rhoc);    

    params = struct('amp',amp,...                %tidal amplitude at mouth (m)
                    'tp',tp,'omega',omega,...        %tidal period (s)
                    'Le',Le(idx),...                      %channel length (m)
                    'Uw',param.Uw,'zw',10,...          %wind speed at 10m (m/s)
                    'g',g,'rhow',rhow,'rhos',rhos,'rhoc',rhoc,...
                    'visc',visc,...
                    'taucr',taucr,'d50',d50,'ws',ws,...%see above  
                    'me',me,...                        %erosion rate (kg/N/s)
                    'gamma',param.gamma);  
end