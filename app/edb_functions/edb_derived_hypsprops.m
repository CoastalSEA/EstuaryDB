function [var,Z,X] = edb_derived_hypsprops(dst,dsetname)
%
%-------function help------------------------------------------------------
% NAME
%   edb_derived_hypsprops.m
% PURPOSE
%   Use hypsooetry of surface area or width to get the vertically
%   integrated hypsoometry of volume or cross-sectional area
% USAGE
%   [var,Z,X] = edb_derived_hypsprops(dst,dsetname);
% INPUTS
%   dst - dstable of hypsometry properties in EDBimport class instance
%   dsetname - name of properties dataset to use
% OUTPUTS
%   var - struct with defined and derived hypsometry properties (eg S and V) 
%   Z - elevation relative to datum (mAD)
%   X - distance along the channel (m) - used for width/CSA only
% NOTES
%   the thederived property, Var, depends on the dataset selected. If 
%   dsetname is 'SurfaceArea, Var = volume (m3), whereas if dsetname 
%   is Width, Var = Cross-sectional area (m2)
% SEE ALSO
%   edb_w_hyps_format, edb_w_hypsometry, edb_s_hyps_format, edb_s_hypsometry
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2025
%--------------------------------------------------------------------------
%  
    var = []; Z = []; X = [];
    if contains(dsetname,'SurfaceArea')        
        var.S = dst.Sa;
        Z = dst.Dimensions.Z;
        delZ = abs(Z(2)-Z(1));
        var.V = cumsum(var.S)*delZ;      %hypsometry volume
    elseif contains(dsetname,'Width')
        var.W = dst.W;
        Z = dst.Dimensions.Z;
        X = dst.Dimension.X;
        delZ = abs(Z(2)-Z(1));
        for i =1:length(X)
            var.A = cumsum(var.W(i,:))*delZ;  %hypsometry cross-sectiional area
        end
    else
        warndlg('Unknown data type in ''edb_derived_hypsprops''')
    end
end