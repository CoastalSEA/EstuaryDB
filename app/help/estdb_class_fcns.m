%% EstuaryDB Classes and Functions
% The EstuaryDB App is built using the <matlab:doc('muitoolbox') muitoolbox>
% and a number of model specific classes.

%% EstuaryDB classes
% * *EstuaryDB* - defines the behaviour of the main UI.
% * *EDB_Parameters* - manages input of model parameters
% * *EDB_Probe* - handles additional analysis of the data
% * *EDB_ProbeUI* - user interface for additional analysis of the data

%% EstuaryDB functions
% Functions to analyse the gross properties (volume, area, width, etc) of inlets or channels 
%%
% * *curvespace* - evenly spaced points along an existing curve in 2D or 3D
% (from Matlab(TM) Forum; Yo Fukushima, 
%   https://www.mathworks.com/matlabcentral/fileexchange/7233-curvspace).
% * *edb_derived_props* - derive additional properties and add them to the
% gross properties table.
% * *edb_plot_tidelevels* - add the high, mean and low water tide levels to
% a plot.
% * *edb_props_table.m* - use surface area hypsometry or width hypsometry to compute the gross
% properties of an inlet or estuary.
% * *edb_regression_analysis* - estimate the exponential convergence rate.
% * *edb_regression_plot* - generate a regression plot for Width , CSA, and
% Hydraulic depth along-channel properties.
% * *edb_surfacearea_table* - compile the surface area hyspometry dataset.
% * *edb_s_hypsometry* - compute the surface area hypsometry data.
% * *edb_user_plots* - suite of functions to plot the data.
% * *edb_user_tools* - suite of functions to analyse the data.
% * *edb_width_table* - compile the width hyspometry dataset.
% * *edb_w_hypsometry* - compute the width hypsometry data.
% * *geyer_mccready_plot* - generate a plot to compare the fluvial/tidal
% properties of estuaries and hence the degree of mixing.

%% EstuaryDB format files
% * *edb_bathy_format* - defines format for import of xyz bathymetry data.
% * *edb_image_format* - defines format for import of images (eg tiff or jpg).
% * *edb_s_hyps_format* - defines format for import of surface area
% hypsometry data ([z,S]).
% * *edb_w_hyps_format* - defines format for import of along-channel width
% hypsometry data ([x,z,W]).

%% Additional functions
% * *..\muiAppLib\muiAppEstuaryFcns* - library of functions for commonly used
% methods such as sea level rise, simple tide simulation, etc.
% *  *..\muiAppLib\muiAppGridFcns* - library of functions for a range of grid
% manipulation methods.
% * Matlab(TM) *Mapping toolbox* or *m_map1.4*
% (https://www-old.eoas.ubc.ca/~rich/map.html) are used  to read shapefiles
% * As a faster alternative to Matlab(TM) _inpolygon_, the _InsidePoly_
% functions can be used (https://uk.mathworks.com/matlabcentral/fileexchange/27840-2d-polygon-interior-detection).

%% Grid Classes
% Classes used to manipulate cartesian grids can be found in the
% _muiAppGridFcns_ folder and include the following:
%%
% * *GD_GridProps*: class inherits <matlab:doc('muipropertyui') muiPropertyUI> 
% abstract class, providing an interface to define the extent and intervals
% of a cartesian grid. 
% * *GDinterface*: an abstract class to support classes that need additional
% functionality to handle grids. The class inherits *GDinterface*, which
% in turn inherits <matlab:doc('muidataset') muiDataSet> 
% to provide an extensive set of methods to handle datasets
% of various types (eg from models or imported files). 
% * *GD_ImportData*: class inherits <matlab:doc('gdinterface') GDinterface> abstract class (see above)
% to load xyz data from a file.

%% Grid Functions
% Functions used to manipulate cartesian grids can be found in the
% _muiAppGridFcns_ folder and include the following:
%%
% * *gd_ax_dir*
% - check direction of grid axes and reverse if descending, OR
% find grid orientation using ishead and direction of x-axis, OR
% check a grid axis direction by prompting user.
% * *gd_centreline.m*
% - create a centreline of a channel using function _a_star_ to trace the
% shortest path between start and end points whilst finding the deepest
% points (i.e. a thalweg).
% * *gd_colormap*
% - check if Mapping toolbox is installed to use land/sea colormap, or call
% _cmap_selection_ if not available (see <matlab:doc('psfunctions') Plotting and statistical functions> 
% in the <matlab:doc('muitoolbox') muitoolbox>).
% * *gd_convergencelength* 
% - least squares fit using fminsearch to % find the convergence length of 
% a channel from a distance-width xy data set.
% * *gd_digitisepoints*
% - creates figure to interactively digitise points on a grid and add
% elevations if required.
% * *gd_dimensions*
% - get the grid dimsnions for a grid struct (as used in GDinterface).
% * *gd_getpoint.m*
% - interactively select a point on a plot and return the point
% coordinates.
% * *gd_grid_line*
% - create a grid from scattered data points input as xyz tuples.
% * *gd_plotgrid*
% - create pcolor plot of gridded surface.
% * *gd_plotsections*
% - display grid and allow user to interactively define start and
% end points of a section line to be plotted in a figure.
% * *gd_pnt2vec.m*
% - convert an array of structs with x,y (and z) fields to a [Nx2] or [Nx3] 
% array of points, or a single stuct with vectors for the x, y (and z)
% fields.
% * *gd_readshapefile.m*
% - read the x and y coordinates from a shape file. Lines are concatenated
% and separated by NaNs in single x and y vectors. Suitable for reading
% boundaries or sections into a single array.
% * *gd_selectpoints*
% - accept figure to interactively create a specified number of x,y points
% on a grid.
% * *gd_setpoint*
% - interactively select a single point on a plot and return the point
% coordinates. Includes an option to enter an additional value at the
% selected point (e.g. for elevation).
% * *gd_setpoints.m*
% - interactively create a set of points on a plot and return the point
% coordinates. Includes an option to enter an additional value at the
% selected points (e.g. elevation).
% * *gd_startendpoints*
% - accept figure to interactively select start and end points on a grid.
% * *gd_subdomain*
% - accept figure to interactively select a subdomain of a grid.
% * *gd_subgrid*
% - extract a subdomain from a grid and return the extracted
% grid and the source grid indices of the bounding rectangle.
% * *gd_xy2sn*
% - map grid from cartesian to curvilinear coordinates with option to return 
% the elevations on the source cartesian grid, or as a curvilinear grid.
% * *gd_sn2xy*
% - map grid from curvilinear to cartesian coordinates.

%% 
% *Additional utility functions*
%%
% * *gd_lineongrid_plot*
% - plots a defined line onto a countour or surface plot of a grid (e.g a
%   channel centre-line).
% * *gd_user_function*
% - function for user to define bespoke use of grids and grid tools.

%%
% *Functions from Matlab(TM) Exchange Forum*
%%
% * *a_star*
% - implements the A* search algorithm to find the shortest path given
% constraints (inaccessible cells) and a cost function (e.g. water depths).
% Author: Alex Ranaldi, 2022, https://github.com/alexranaldi/A_STAR
% * *InterX* 
% - intersection of two curves. MATLAB Central File Exchange, 
% Author: NS, 2010, https://www.mathworks.com/matlabcentral/fileexchange/22441-curve-intersections.
% * *xy2sn* 
% - Bart Vermeulen,2022, Cartesian to Curvilinear 
%   coordinate forward and backward transformation. 
%   https://www.mathworks.com/matlabcentral/fileexchange/55039-cartesian-to-curvilinear-coordinate-forward-and-backward-transformation 
% * *sn2xy* 
% - as above.

%% Point and Line Classes
% Classess used to manipulate points and lines can be found in the
% _muiAppGridFcns_ folder and include the following:
%%
% * *PL_Sections*: provides methods to manipulate points, lines and sections 
% using datasets in classes that inherit <matlab:doc('gdinterface') GDinterface>.
% * *PL_Boundary*: Class to extract contours and generate model boundaries
% * *PL_CentreLine*: Class to extract valley/channel centre-line
% *PL_PlotSections*: display grid and allow user to interactively define start and
% end points of a section line to be plotted in a figure.
% * *PL_SectionLines*: Class to create a set of cross-sections lines based on 
% the points in a centre-line and any enclosing boundary.

%% Point and Line Functions
% Functions used to manipulate points and lines can be found in the
% _muiAppGridFcns_ folder and include the following:
%%
% * *gd_boundary.m* - UI to interactively generate a contour line (e.g. to define a boundary).
% * *gd_centreline* - create a centreline of a channel to trace the
% shortest path between start and end points whilst finding the deepest
% points (i.e. a thalweg).
% * *gd_cplines2plines.m*
% - convert cell array of plines to an array of points that define plines.
% * *gd_curvelineprops* - for each point from idL to the end use the centre-line coordinates and 
% direction to find the lengths and directions along the centre-line.
% * *gd_findline.m* - find which _pline_ a given _point_ lies on when there are multiple lines
% separated by NaN values in a _plines_ struct array.
% * *gd_getcontour.m* - extract a contour at a defined level.
% * *gd_getpline.m* - interactively select a line on a plot and return the line point coordinates.
% * *gd_getpoint.m* - interactively select a single point in a UI figure and return the point
% coordinates.
% * *gd_lines2points.m* - convert _lines_  as x,y vectors in various formats (see *gd_points2lines*) to a 
% _points_ array of structs for each _point_ with x, y (and z) fields.
% * *gd_linetopology* - interactively define line connectivity.
% * *gd_orderplines.m* - amend the order of the _plines_ in an array of _plines_.
% * *gd_plines2cplines.m*
% - convert an array of _plines_ to a cell array of _plines_.
% * *gd_plotgrid* - create pcolor plot of gridded surface (from Grid Tools).
% * *gd_plotsections* - display grid and allow user to interactively define start and
% end points of a section line to be plotted in a figure (from Grid Tools).
% * *gd_points2lines.m* - convert a _points_ or plines array of structs with x, y (and z) fields 
% to a [Nx2] or [Nx3] array, or a single stuct, or matrix with column vectors
%  in the x, y (and z) fields.
% * *gd_sectionlines.m* - extract the section lines that are normal to the channel centre line
% and extend to the bounding shoreline.
% * *gd_selectpoints.m* - UI to interactively create a specified number of x,y point on a grid.
% * *gd_setpoint.m* - interactively create a single point in a UI figure and return the point
% coordinates. Includes an option to enter an additional value at the
% selected point (e.g. elevation).
% * *gd_setpoints.m*
% - interactively create a set of points in a UI figure and return the point
% coordinates. Includes an option to enter an additional value at the
% selected points (e.g. elevation).
% * *gd_smoothlines.m* - smooth one or more line segments using either moving average, or the
% Savitzky-Golay method.

%%
% Further details can be found in <matlab:doc('grid_class_fcns') Grid classes and functions>
% 

%% See Also 
% The EstuaryDB <matlab:estdb_open_manual manual>, which provides further details 
% of setup and configuration of the model.
