function [var,Z,X] = edb_derived_hypsprops(dst,dsetname,invar)
%
%-------function help------------------------------------------------------
% NAME
%   edb_derived_hypsprops.m
% PURPOSE
%   Use hypsometry of surface area or width to get the vertically
%   integrated hypsometry of volume or cross-sectional area
% USAGE
%   [var,Z,X] = edb_derived_hypsprops(dst,dsetname,invar);
% INPUTS
%   dst - dstable of hypsometry properties in EDBimport class instance
%   dsetname - name of properties dataset to use
%   invar - variable name to use (optional - used in edb_hypsometry_plots
%   for reach widths)
% OUTPUTS
%   var - struct with defined and derived hypsometry properties (eg S and V) 
%   Z - elevation relative to datum (mAD)
%   X - distance along the channel (m) - used for width/CSA ONLY
% NOTES
%   the derived property, Var, depends on the dataset selected. If 
%   dsetname is 'SurfaceArea, Var = volume (m3), whereas if dsetname 
%   is Width, Var = Cross-sectional area (m2)
%   For widths this function only works for the All reach data set.
% SEE ALSO
%   edb_w_hyps_format, edb_w_hypsometry, edb_s_hyps_format, edb_s_hypsometry
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2025
%--------------------------------------------------------------------------
% 
    if nargin<3
        if contains(dsetname,'SurfaceArea')
            invar = 'Sa';
        else
           invar = 'W';
        end
    end

    var = []; Z = []; X = [];
    if contains(dsetname,'SurfaceArea')        
        var.S = dst.(invar);
        Z = dst.Dimensions.Z;
        delZ = abs(Z(2)-Z(1));
        var.V = cumsum(var.S)*delZ;      %hypsometry volume
    elseif contains(dsetname,'Width')
        var.W = squeeze(dst.(invar));
        Z = dst.Dimensions.Z;
        X = dst.Dimensions.X;
        delZ = abs(Z(2)-Z(1));
        for i =1:length(X)
            var.A(i,:) = cumsum(var.W(i,:))*delZ;  %hypsometry cross-sectiional area
        end
    else
        warndlg('Unknown data type in ''edb_derived_hypsprops''')
    end
end