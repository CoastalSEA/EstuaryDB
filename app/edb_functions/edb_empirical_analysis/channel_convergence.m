function outable = channel_convergence(hm,amp,Tp,gamma,Qr,A0,Le)
%
%-------function help------------------------------------------------------
% NAME
%   channel_convergence.m 
% PURPOSE
%   find the channel e-folding length using method of Dronkers 2017. Note that
%   this assumes that depth, h, is constant and so La=Lw.
% USAGE
%   La = area_convergence(hm,amp,Tp,gamma,Qr,A0)
% INPUTS     
%   hm - hydraulic depth (m)
%   amp - tidal amplitude (m)
%   Tp - tidal period (hr)
%   gamma - Dronkers tidal asymetry coefficient (-)
%   Qr - river discharge (m3/s)
%   A0 - CSA at channel mouth (m2)
%   Le - estuary length (m)
% OUTPUTS
%   outable - table with the following fields
%       Lw - convergence length for full solution (m)
%       LwS - convergence length for short basins (m)
%       U1 - maximum tidal velocity (equiv. velocity amplitude for Q1 the 
%            semidiurnal discharge component)
%       U1_hw - Velocity amplitude at high water
%       U1_lw - Velocity amplitude at low water
%       phi_hw - Phase between HW and HWS
%       phi_lw - Phase between LW and LWS
%       hrv - River depth
%       Wrv - River width    
% NOTES
%   Based on method in Dronkers J, 2017, Convergence of estuarine channels. 
%   Continental Shelf Research, 144, pp. 120-133, 10.1016/j.csr.2017.06.012.
% SEE ALSO
%   tidal_fom_solver_mkX.m
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%
    omega = 2*pi/Tp/3600;  %angular frequency (1/s)
    if Qr==0 || isnan(Qr), Qr = 1;end  %set minimum values for Qr=0
    beta = 1.0;  %channel width is set equal to B = βb-, where b− is the total 
                 %wetted surface width at low water and β is a tuning parameter
                 %see Fig.2 in paper.
    nC = 6;      %scaling coefficient for n=2 sediment transport exponent
                 %varies with n and nC=5 for n=4

    r = hypsometry_exponent(hm,amp,gamma);              %hypsomety exponent, r
    Sratio = ((r*hm-amp)/(r*hm+amp))^(r-1);             %ratio of Slw/Shw 
    if ~isreal(Sratio); Sratio = 1; end

    %find river CSA to estimate Ur    
    if Qr>0
        Sr  = 2*amp/Le;   %energy slope at tidal limit (-); **estimate**
        d50 = 0.0002;     %sediment grain size (m) 
        tau = 0.2;        %critical shear stress (Pa)
        rhos = 2650;      %density of sediment (kg/m3)
        rhow = 1025;      %density of water (kg/m3)
        [hrv,Wrv,~] = river_regime(Qr,Sr,d50,tau,rhos,rhow);
    else
        hrv = 1; Wrv = 1;         %minimum channel if no flow
    end
    % Arv = hrv*Wrv;

    rf = 8*0.003/3/pi();                                %estimate Cd.U=0.003 - after Eq.A3    
    %Cd = frictionCoeff(inp,hm);                         %drag coefficient
    %rf = 8*Cd/3/pi();                                   %estimate for U1~1m/s

    Dplus = hm+amp;                                     %HW depth in channel
    Dsplus = Dplus*beta*Sratio;                         %HW width adjusted depth
    Dminus = hm-amp;                                    %LW depth in channel
    Dsminus = Dminus*beta;                              %LW width adjusted depth
            
    Lw0 = estimateConvergence(hm,amp,omega);            %initial guess of Lw
   
    %set up solution using X=Lw as the unknown
    kc_fun = @(X,D,Ds) omega*rf*X(1)/9.81/D/Ds;         %Eq.A7
    p_fun = @(X,Ds) (omega*X/sqrt(9.81*Ds))^2-0.25;     %Eq.A7 combines ko and p
    Ur_fun = Qr/(A0*exp(-0.5));  %river velocity using effective CSA at x=La/2

    %wave number at high and low water, using Eq.A6 and A7
    kl_fun = @(X,D,Ds) sqrt(0.5*(p_fun(X,Ds)+sqrt(p_fun(X,Ds)^2+(kc_fun(X,D,Ds)*X)^2)));
    mul_fun = @(X,D,Ds) -0.5+sqrt(0.5*(-p_fun(X,Ds)+sqrt(p_fun(X,Ds)^2+(kc_fun(X,D,Ds)*X)^2)));

    kplus = @(X) 1/X*kl_fun(X,Dplus,Dsplus);            %wave number at high water
    kminus = @(X) 1/X*kl_fun(X,Dminus,Dsminus);         %wave number at low water

    phi_fun = @(X,D,Ds) atan(kl_fun(X,D,Ds)/(1+mul_fun(X,D,Ds)));   %phase angle
    U1hw_fun = @(X) amp*omega*sin(phi_fun(X,Dplus,Dsplus))/kplus(X)/Dsplus;
    U1lw_fun = @(X) amp*omega*sin(phi_fun(X,Dminus,Dsminus))/kminus(X)/Dsminus;
    U1_fun = @(X) (U1hw_fun(X)+U1lw_fun(X))/2;

    options = optimset('MaxIter',1000,'TolFun',1e-9,'TolX',1e-6);
    L_fun = @(X) X-nC*Ur_fun/U1_fun(X)*(1/(kminus(X)-kplus(X)));  %Eq.19 re-arranged in terms of k    
    if isnan(L_fun(Lw0))
        Lw0 = Lw0*2;
        Lw = fzero(L_fun,Lw0,options);
    elseif isinf(L_fun(Lw0))
        Lw = Lw0;
    else
        Lw = fzero(L_fun,Lw0,options);
    end
    
    U1 = U1_fun(Lw);

    %short basins estimate
    L_short = @(X)  beta/2*hm/amp*U1_fun(X)/omega*(1+Sratio);
    LwS = L_short(Lw);
    U1_hw = U1hw_fun(Lw);
    U1_lw = U1lw_fun(Lw);
    phi_hw = phi_fun(Lw,Dplus,Dsplus);
    phi_lw = phi_fun(Lw,Dminus,Dsminus);

    %assign output to table
    outable = table(Lw,LwS,U1,U1_hw,U1_lw,phi_hw,phi_lw,hrv,Wrv);
    outable.Properties.VariableDescriptions = {'Convergence length - full solution',...
                                          'Convergence length- short basin',...
                                          'Velocity amplitude (mean)',...
                                          'Velocity amplitude at high water',...
                                          'Velocity amplitude at low water',...
                                          'Phase between HW and HWS',...
                                          'Phase between LW and LWS',...
                                          'River depth',...
                                          'River width'};
end
%%
function r = hypsometry_exponent(hm,amp,gamma)
    %get fucntion to set the hypsometry exponent and central depth
    %using hydraulic depth and tidal amplitude for reaches
    func = @(r) abs(((r*hm+amp)/(r*hm-amp))^(3-r)-gamma);
    options = optimset('TolX',1e-6);
    r = fminbnd(func,1,3,options);
end

%%
function L = estimateConvergence(hm,amp,omega)
    %approximate width or area convergence length for given depth 
    k  = omega/sqrt(9.81*hm);                       %wave number
    eH = pi()*amp/4/hm;                             %amplitude-depth ratio
    L = 1/k*atan2(2*eH/(1+eH^2),(1-eH^2)/(1+eH^2)); %Eq.15 in Channel Form Solver note
end