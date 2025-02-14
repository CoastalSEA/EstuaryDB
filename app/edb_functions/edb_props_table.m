function obj = edb_props_table(obj)
%
%-------function help------------------------------------------------------
% NAME
%   edb_props_table.m
% PURPOSE
%   use surface area hypsometry or width hypsometry to compute the gross
%   properties of an inlet or estuary
% USAGE
%   obj = edb_props_table(obj);
% INPUTS
%   obj - handle to class instance for EDBimport
% OUTPUT
%   obj - handle to updated class instance for EDBimport
% NOTES
%   gross morphological properties include volume, surface area (and when
%   using widths, CSA at the mouth).
% SEE ALSO
%     called from EDBimport class.
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2025
%--------------------------------------------------------------------------
%
    datasetname = getEDBdataset(obj,{'Width','SurfaceArea'});
    if isempty(datasetname), return; end
    dst = obj.Data.(datasetname);
    [var,Z] = edb_derived_hypsprops(dst,datasetname);
    mnmx = cellstr(num2str(minmax(Z)'));
    dz = num2str(abs(Z(2)-Z(1)));

    %see if tidal data is available
    if isfield(obj.HydroProps,'TidalLevels')
        tlevels = obj.HydroProps.TidalLevels.DataTable;
        answer = questdlg('Select tidal range to use','Properties',...
                          'Spring','Mean','Neap','Spring');
        if strcmp(answer,'Spring')
            tides = tlevels{1,[2,5,8]};           
        elseif strcmp(answer,'Mean')
            tides = tlevels{1,[3,5,7]};
        else                %Neaps
            tides = tlevels{1,[4,5,6]};
        end  
        tides = cellstr(num2str(tides'));
        defaultvals = [tides(:)',mnmx(:)',{dz}];
    else
        defaultvals = [{'1'},{'0'},{'-1'},mnmx(:)',{dz}];
    end
    wl = getWaterLevels(defaultvals);

    if contains(datasetname,'SurfaceArea')
        grossprops = grossProperties(var.S,var.V,Z,wl);
        propnames = fieldnames(grossprops);

        gdsp = setDSproperties();      
    else
        grossprops = grossProperties(var.W,var.A,Z,wl);
        gdsp = setDSproperties();
    end
    grossprops.Source = {datasetname};
    grossprops.Range = {answer};
    %assign output to table
    C = [{'Source'},{'Range'},propnames(:)'];
    grossprops = orderfields(grossprops,C);
    grossprops = struct2table(grossprops);  
    gdst = dstable(grossprops,'RowNames',1,'DSproperties',gdsp);
%     gdst.Source = sprintf('%s hypsometry',datasetname);
%     gdst.MetaData = sprintf('Gross properties computed using %s water levels',answer);  
    gdst.Description = dst.Description;
    if ~isempty(obj.MorphProps)        %table exits
        gdst.RowNames = height(obj.MorphProps)+1;
        gdst = vertcat(obj.MorphProps,gdst);
    end
    obj.MorphProps = gdst;
end

%%
    function grossprops = grossProperties(zsurf,zvol,zcentre,wl)
    %compute the gross properties of the selected bathymetry
    histint = wl.int+eps;
    am = (wl.HW-wl.LW)/2;             %tidal amplitude(m)
    z0 = wl.MT;                       %mean tide level(m)
    %lowlim = inp.zm; uplim = inp.zhw;%define range to be entire model domain
    idh = find(zcentre<(wl.HW+histint/2) & zcentre>=(wl.HW-histint/2),1,'first');
    idl = find(zcentre<=(wl.LW+histint/2) & zcentre>=(wl.LW-histint/2),1,'first');
    ido = find(zcentre<=(z0+histint/2) & zcentre>=(z0-histint/2),1,'first');

    r.Shw = zsurf(idh);               %surface area at high water
    r.Smt = zsurf(ido);               %surface area at mean tide
    r.Slw = zsurf(idl);               %surface area at low water
    r.Vhw = zvol(idh);                %volume at high water
    r.Vmt = zvol(ido);                %volume at mean tide
    r.Vlw = zvol(idl);                %volume at low water
    r.Pr  = r.Vhw-r.Vlw;              %volume of tidal prism
    beta = 1;                         %assume Schw/Sclw = 1
    r.Gamma = (r.Slw/r.Shw)^3*(r.Vhw/r.Vlw)^2*beta;  %Dronkers gamma (~1)
    r.Vs  = (r.Vhw-r.Vlw)-2*am*r.Slw; %storage volume over intertidal
    r.Vc  = r.Vlw+2*am*r.Slw;         %channel volume    
    r.amp   = am;                       %tidal amplitude
    r.hyd = zvol(ido)/zsurf(ido);     %hydraulic depth at mtl
    r.aoh = am/r.hyd;                 %tidal amplitude/hydraulic depth 
    r.VsoVc = r.Vs/r.Vc;              %ratio fo storage to channel volumes
    r.SflShw = (r.Shw-r.Slw)/r.Shw;   %ratio of intertidal area to basin area
%     x0 = min(grid.x);
%     [r.W0,r.A0] = getCSAat_z0_X(grid,z0,x0); %width and csa at mouth
%     r.PoA = r.Pr/r.A0;                %Prism to CSA ratio
    grossprops = r;                   %assign structure to output
end

%%
function wl = getWaterLevels(defaultvals)
    %prompt user for levels to used to compute volumes and areas at high
    %and low water
    prmptxt = {'High water level:','Mean tide level:','Low water level:',...
                'Minimum level:','Maximum level:','Vertical interval:'};
    dlgtitle = 'Water levels';
    answer = inputdlg(prmptxt,dlgtitle,1,defaultvals);
    if isempty(answer)
        wl = [];  
        return;
    end
    wl.HW = str2double(answer{1});
    wl.MT = str2double(answer{2});
    wl.LW = str2double(answer{3});
    wl.mx = str2double(answer{4});
    wl.mn = str2double(answer{5});
    wl.int = str2double(answer{6});
end

%%
function dsp = setDSproperties()
    %define the metadata properties for the demo data set
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %struct entries are cell arrays and can be column or row vectors
        dsp.Variables = struct(...
            'Name',{'Source','Range','Shw','Smt','Slw','Vhw','Vmt','Vlw','Pr',...
                    'Gamma','Vs','Vc','amp','hyd','aoh',...
                    'VsoVc','SflShw'},...
            'Description',{'Source','Tidal range','HW Surface Area','MT Surface Area',...
                    'LW Surface Area','HW Volume','MT Volume','LW Volume',...
                    'Tidal Prism','Gamma','Storage Volume','Channel Volume',...                    
                    'Tidal amplitude at mouth','Hydraulic depth to MTL',...
                    'Amplitude to Depth ratio',...
                    'Storage to Channel Volume ratio',...
                    'Intertidal to Basin Area ratio'},...
            'Unit',{'-','m','m2','m2','m2','m3','m3','m3','m3','-','m3','m3',...
                    'm','m','-','-','-'},...
            'Label',{'Source','Tidal range (m)','Surface area (m^2)','Surface area (m^2)',...
                    'Surface area (m^2)','Volume (m^3)','Volume (m^3)',...
                    'Volume (m^3)','Prism (m^3)'...
                    'Gamma','Volume (m^3)','Volume (m^3)',...
                    'Tidal amplitude (m)','Hydraulic depth (m)',...
                    'Amplitude to Depth ratio (-)',...
                    'Storage to Channel Volume ratio (-)',...
                    'Intertidal to Basin Area ratio (-)'},...
            'QCflag',repmat({'model'},[1,17]));
        dsp.Row = struct(...
                    'Name',{''},...
                    'Description',{''},...
                    'Unit',{''},...
                    'Label',{''},...
                    'Format',{''});
        dsp.Dimensions = struct('Name',{''},'Description',{''},...
                    'Unit',{''},'Label',{''},'Format',{''});
end