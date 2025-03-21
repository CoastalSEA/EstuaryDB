function [obj,isok] = edb_grossprops_table(obj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_grossprops_table.m
% PURPOSE
%   use surface area hypsometry or width hypsometry to compute the gross
%   properties of an inlet or estuary
% USAGE
%   obj = edb_grossprops_table(obj);
% INPUTS
%   obj - handle to class instance for EDBimport
% OUTPUT
%   obj - handle to updated class instance for EDBimport
%   isok - logical true if output added, false if user cancelled
% NOTES
%   gross morphological properties include volumes, surface areas (and when
%   using widths can include width and CSA at the mouth).
% SEE ALSO
%     called from EDBimport class.
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2025
%--------------------------------------------------------------------------
%
    datasetname = getEDBdataset(obj,{'Width','SurfaceArea'});
    if isempty(datasetname), isok = 0; return; end
    dst = obj.Data.(datasetname);
    [var,z,x] = edb_derived_hypsprops(dst,datasetname);
    mnmx = cellstr(num2str(minmax(z)'));
    dz = num2str(abs(z(2)-z(1)));

    %see if tidal data is available
    [wl,selection] = edb_waterlevels(obj,mnmx,dz);

    if contains(datasetname,'SurfaceArea')
        grossprops = grossProperties(var.S,var.V,z,wl);   
    else
        delx = abs(x(2)-x(1));
        S = sum(var.W,1)*delx;
        V = sum(var.A,1)*delx;
        grossprops = grossProperties(S,V,z,wl);
        grossprops = addMouthProps(var,grossprops,z,wl);
    end

    user_notes = inputdlg('Case description','GrossProps',1,{selection});
    propnames = fieldnames(grossprops);
    gdsp = setDSproperties();
    grossprops.Source = {datasetname};
    grossprops.Notes = user_notes;
    %assign output to table
    C = [{'Source'},propnames(:)',{'Notes'}];
    grossprops = orderfields(grossprops,C);
    grossprops = struct2table(grossprops);  
    gdst = dstable(grossprops,'RowNames',1,'DSproperties',gdsp);
    gdst.Source = 'Hypsometry data for dataset defined by source column';
    gdst.MetaData = 'Gross properties computed using tidal range as defined in table';  
    gdst.Description = dst.Description;
    if ~isempty(obj.GrossProps)        %table exits
        gdst.RowNames = height(obj.GrossProps)+1;
        gdst = vertcat(obj.GrossProps,gdst);
    end
    obj.GrossProps = gdst;
    isok = 1;
end

%%
    function grossprops = grossProperties(zsurf,zvol,zcentre,wl)
    %compute the gross properties of the selected bathymetry
    histint = wl.int+eps;
    am = (wl.HW-wl.LW)/2;               %tidal amplitude(m)
    z0 = wl.MT;                         %mean tide level(m)
    idh = find(zcentre<=(wl.HW+histint/2) & zcentre>=(wl.HW-histint/2),1,'first');
    idl = find(zcentre<=(wl.LW+histint/2) & zcentre>=(wl.LW-histint/2),1,'first');
    ido = find(zcentre<=(z0+histint/2) & zcentre>=(z0-histint/2),1,'first');
    
    r = struct('HWL',wl.HW,'MTL',wl.MT,'LWL',wl.LW,...
               'Shw',0,'Smt',0,'Slw',0,'Vhw',0,'Vmt',0,'Vlw',0,'Pr',0,...
               'gam',0,'Vs',0,'Vc',0,'VsoVc',0,'SflShw',0,'a',0,'hyd',0,...
               'aoh',0,'Wmt',0,'Amt',0,'PoA',0); %NB W0 and A0 not assigned
    r.Shw = zsurf(idh);                 %surface area at high water
    r.Vhw = zvol(idh);                  %volume at high water
    r.a   = am;                         %tidal amplitude

    if ~isempty(ido)
        r.Smt = zsurf(ido);             %surface area at mean tide
        r.Vmt = zvol(ido);              %volume at mean tide
        r.hyd = zvol(ido)./zsurf(ido);  %hydraulic depth at mtl
        r.aoh = am./r.hyd;              %tidal amplitude/hydraulic depth   
    end

    if ~isempty(idl)
        r.Slw = zsurf(idl);             %surface area at low water
        r.Vlw = zvol(idl);              %volume at low water
        r.Pr  = r.Vhw-r.Vlw;            %volume of tidal prism
        beta = 1;                       %assume Schw/Sclw = 1
        r.gam = (r.Slw./r.Shw).^3.*(r.Vhw./r.Vlw).^2.*beta;  %Dronkers gamma (~1)  
        r.Vs  = (r.Vhw-r.Vlw)-2.*am.*r.Slw;  %storage volume over intertidal
        r.Vc  = r.Vlw+2.*am.*r.Slw;          %channel volume
        r.VsoVc = r.Vs./r.Vc;           %ratio fo storage to channel volumes
        r.SflShw = (r.Shw-r.Slw)/r.Shw; %ratio of intertidal area to basin area
    else
        r.Pr  = r.Vhw;                  %volume of tidal prism
        r.Vs  = r.Vhw;                  %storage volume over intertidal
        r.SflShw = 1;                   %ratio of intertidal area to basin area
    end
    grossprops = r;                     %assign structure to output
end

%%
function gp = addMouthProps(var,gp,z,wl)
    %for width hypsometry, add width and CSA at mouth
    W0 = var.W(1,:);  %assume first section defines the mouth
    A0 = var.A(1,:);
    gp.Wmt = interp1(z,W0,wl.MT);
    gp.Amt = interp1(z,A0,wl.MT);
    gp.PoA = gp.Pr/gp.Amt;
    % figure; plot(W0,z,A0,z);
end

%%
function dsp = setDSproperties()
    %define the metadata properties for the demo data set
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %struct entries are cell arrays and can be column or row vectors
        vars = {'Source','Source','-','Source','derived';...%NB this duplicates class property Source. Can only access using DataTable
                'HWL','High water level','mAD','Tidal level (mAD)','derived';...
                'MTL','Mean tide level','mAD','Tidal level (mAD)','derived';...
                'LWL','Low water level','mAD','Tidal level (mAD)','derived';...
                'Shw','HW Surface Area','m2','Surface area (m^2)','derived';...
                'Smt','MT Surface Area','m2','Surface area (m^2)','derived';...
                'Slw','LW Surface Area','m2','Surface area (m^2)','derived';...
                'Vhw','HW Volume','m3','Volume (m^3)','derived';...
                'Vmt','MT Volume','m3','Volume (m^3)','derived';...
                'Vlw','LW Volume','m3','Volume (m^3)','derived';...
                'Pr','Tidal Prism','m3','Volume (m^3)','derived';...
                'Gamma','Gamma','-','Gamma','derived';...
                'Vs','Storage Volume','m3','Volume (m^3)','derived';...
                'Vc','Channel Volume','m3','Volume (m^3)','derived';...
                'VsoVc','Storage to Channel Volume ratio','-','Storage to Channel Volume ratio (-)','derived';...
                'SflShw','Intertidal to Basin Area ratio','-','Intertidal to Basin Area ratio (-)','derived';...
                'amp','Tidal amplitude at mouth','m','Tidal amplitude (m)','derived';...
                'hyd','MT Hydraulic depth','m','Hydraulic depth (m)','derived';...
                'aoh','Amplitude to Depth ratio','-','Amplitude to Depth ratio (-)','derived';...
                'Wmt','MT Width at mouth','m','Width (m)','derived';...
                'Amt','MT CSA at mouth','m2','CSA (m^2)','derived';...
                'PoA','Prism over MT CSA','m','Prism to Area ratio','derived';...
                'Notes','Notes','-','Notes','derived'};
        dsp.Variables = struct('Name',vars(:,1)','Description',vars(:,2)',...
                               'Unit',vars(:,3)','Label',vars(:,4)',...
                               'QCflag',vars(:,5)');
        dsp.Row = struct(...
                    'Name',{''},...
                    'Description',{''},...
                    'Unit',{''},...
                    'Label',{''},...
                    'Format',{''});
        dsp.Dimensions = struct('Name',{''},'Description',{''},...
                    'Unit',{''},'Label',{''},'Format',{''});
end