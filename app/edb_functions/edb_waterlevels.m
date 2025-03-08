function [wl,selection] = edb_waterlevels(obj,mnmx,dz)
%
%-------function help------------------------------------------------------
% NAME
%   edb_waterlevels.m
% PURPOSE
%   select tidal range and return HW,MT,LW for selected range
% USAGE
%   [wl,selection] = edb_waterlevels(obj,mnmx,dz)
% INPUTS
%   obj - instance of EDBimport class with tidal level data
% OUTPUTS
%   wl - water levels for selected tidal range
%   selection - range selected (spintg, mean, neap)
% NOTES
%   accesses data held in the class HyrdoProps property
% SEE ALSO
%   used in edb_props_table.m and edb_convergence_data
%
% Author: Ian Townend
% CoastalSEA (c) Mar 2025
%--------------------------------------------------------------------------
%

    %see if tidal data is available
    if isfield(obj.HydroProps,'TidalLevels')
        tlevels = obj.HydroProps.TidalLevels.DataTable;
        selection = questdlg('Select tidal range to use','Properties',...
                          'Spring','Mean','Neap','Spring');
        if strcmp(selection,'Spring')
            tides = tlevels{1,[2,5,8]};           
        elseif strcmp(selection,'Mean')
            tides = tlevels{1,[3,5,7]};
        else                %Neaps
            tides = tlevels{1,[4,5,6]};
        end  
        tides = cellstr(num2str(tides'));
        defaultvals = [tides(:)',mnmx(:)',{dz}];
    else
        selection = 'User';
        defaultvals = [{'1'},{'0'},{'-1'},mnmx(:)',{dz}];
    end
    wl = getWaterLevels(defaultvals);

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