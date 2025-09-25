function ax = edb_location_plot(obj,hf,type)
%
%-------function help------------------------------------------------------
% NAME
%   edb_location_plot.m
% PURPOSE
%   Add the location map to a figure
% USAGE
%   edb_location_plot(obj,hf)
% INPUTS
%   obj - instance of EDBimport class containing Width and tidal level data
%   hf - figure or panel handle
%   type - type of plot: Grid, Polygon or Sections
% OUTPUT
%   ax - handle to axes for:
%   bathymetry with bounding polygon or sections, or image added to tile
% NOTES
%    
% SEE ALSO
%   EstuaryDB, edb_convergence_analysis
%
% Author: Ian Townend
% CoastalSEA (c) Sept 2025
%--------------------------------------------------------------------------
%     
    if any(contains(fieldnames(obj.Data),'Grid','IgnoreCase',true)) ||...
        any(contains(fieldnames(obj.Data),'GeoImage','IgnoreCase',true)) 
        %bathymetry exists so plot alone, or with polygon or sections
        switch type
            case 'Grid'
                ax = PL_Sections.getGrid(obj,hf); %returns empty plot if no Grid
            case 'Polygon'
                %plot bathymetry and bounding polygon    
                ax = PL_Sections.getGrid(obj,hf); %returns empty plot if no Grid
                if ~isempty(obj.WaterBody) 
                    shp = obj.WaterBody;  %current saved waterbody polygon
                    hold on
                    if ~isempty(shp), plot(ax,shp.x,shp.y,'r'); end
                    hold off
                end
            case 'Sections'
                pobj = obj.Sections;
                ax = viewPlanSections(pobj,obj,'Layout of Sections',hf); 
            otherwise
                warndlg('Plot type for Geo data location plot not found')
        end
    elseif any(contains(fieldnames(obj.Data),'image','IgnoreCase',true))
        %image exists so add to figure
        dsetnames = fieldnames(obj.Data);
        idn = contains(dsetnames,'image','IgnoreCase',true);
        ax = axes(hf);
        estmap =  obj.Data.(dsetnames{idn}).DataTable{1,1};
        image(ax,estmap{1})
        axis image off           % equal aspect ratio, no ticks
        set(ax,'LooseInset',get(ax,'TightInset'))
    end
end


