function dst = edb_convergence_data(obj,dataset)
%
%-------function help------------------------------------------------------
% NAME
%   edb_convergence_data.m
% PURPOSE
%   interpolate width hypsometry to return along-channel width and CSA 
%   variation at selected water levels
% USAGE
%   dst = edb_convergence_data(cobj,dataset)
% INPUTS
%   obj - instance of EDBimport class containing Width and tidal level data
%   dataset - the selected Width data set
% OUTPUTS
%   dst - dstable with the variables to examine along channel convergence:
%         'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'
% NOTES
%   accesses data held in the class HyrdoProps property
% SEE ALSO
%   used in edb_props_table.m and edb_convergence_data
%
% Author: Ian Townend
% CoastalSEA (c) Mar 2025
%--------------------------------------------------------------------------
%
    srcdst = obj.Data.(dataset); %dstable of along channel width hypsometry data
%     z = srcdst.Dimensions.Z;
%     x = srcdst.Dimensions.X;
%     W = squeeze(srcdst.W);
     [var,z,x] = edb_derived_hypsprops(srcdst,dataset);
    mnmx = cellstr(num2str(minmax(z)'));
    dz = num2str(abs(z(2)-z(1)));
    [wl,selection] = edb_waterlevels(obj,mnmx,dz); %tidal level data    

    %interpolate the width data for the selected elevations
    [X,Z] = meshgrid(x,z);
    wlvar = {'LW','MT','HW'};
    for i=1:3
        zq = ones(size(x'))*wl.(wlvar{i});
        wx(i,:) = interp2(X,Z,var.W',x',zq,'makima');
        ax(i,:) = interp2(X,Z,var.A',x',zq,'makima');
        hx(i,:) = ax(i,:)./wx(i,:);
    end
    var = [num2cell(hx,2)',num2cell(wx,2)',num2cell(ax,2)'];

    dsp = setDSproperties();
    estuaryname = srcdst.Description;
    dst = dstable(var{:},'RowNames',{estuaryname},'DSproperties',dsp);
    dst.Dimensions.X = srcdst.Dimensions.X;
    dst.Description = estuaryname;
end
%%
%--------------------------------------------------------------------------
% setDSproperties
%--------------------------------------------------------------------------
function dsp = setDSproperties()
    %define the variables and metadata properties for the dataset
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]);  
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique
    %struct entries are cell arrays and can be column or row vectors
    dsp.Variables = struct(...                      
        'Name',{'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW'},...
        'Description',{'Depth at Low Water','Depth at Mean Tide','Depth at High Water',...
                       'Width at Low Water','Width at Mean Tide','Width at High Water',...
                       'CSA at Low Water','CSA at Mean Tide','CSA at High Water'},...
        'Unit',{'m','m','m','m','m','m','m^2','m^2','m^2'},...
        'Label',{'Hydraulic depth (m)','Hydraulic depth (m)','Hydraulic depth (m)',...
                 'Width (m)','Width (m)','Width (m)',...
                 'Cross-sectional area (m^2)','Cross-sectional area (m^2)','Cross-sectional area (m^2)'},...
        'QCflag',repmat({'data'},1,9)); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{'Estuary'},...
        'Unit',{'-'},...
        'Label',{'Estuary'},...
        'Format',{''});                    
    dsp.Dimensions = struct(...    
        'Name',{'X'},...
        'Description',{'Distance'},...
        'Unit',{'m'},...
        'Label',{'Distance to mouth (m)'},...
        'Format',{''});   
end