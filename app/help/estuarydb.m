%% EstuaryDB
% Combine estuary data from multiple sources for intercomparison and
% further anlysis

%% Licence
% The code is provided as Open Source code (issued under a GNU General 
% Public License).

%% Requirements
% EstuaryDB is written in Matlab(TM) and requires v2016b, or later. In addition, 
% EstuaryDB requires both the <matlab:doc('dstoolbox') dstoolbox> and the 
% <matlab:doc('muitoolbox') muitoolbox> and the estuary and grid libraries
% in the muiAppLib repository.

%% Background
% EstuaryDB is used to load tables of estuary properties, derived
% hypsometry data for surface area (whole estuary), or width (along channel
% sections), or derive such data from a bathymetry grid. A range of tools
% are then available to plot, tabulate and analyse these datasets.

%% EstuaryDB classes
% * *EstuaryDB* - defines the behaviour of the main UI.
% * *EDB_Parameters* - manages input of model parameters
% * *EDB_Probe* - handles additional analysis of the data
% * *EDB_ProbeUI* - user interface for additional analysis of the data

%% EstuaryDB functions
% * *edb_derived_props* - derive additional properties and add them to the
% gross properties table.
% * *edb_regression_analysis* - estimate the exponential convergence rate.
% * *edb_regression_plot* - generate a regression plot for Width , CSA, and
% Hydraulic depth along-channel properties.
% * *edb_surfacearea_table* - compile the surface area hyspometry dataset
% * *edb_s_hypsometry* - compute the surface area hypsometry data
% * *edb_user_plots* - suite of functions to plot the data
% * *edb_user_tools* - suite of functions to analyse the data
% * *edb_width_table* -  compile the width hyspometry dataset
% * *edb_w_hypsometry* - compute the width hypsometry data
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
%% Usage	
%  Quick Guide to setting up a new analysis:
% 
%  File>New 
%      To create a new project space.
% 	
%  Setup>Import Table Data
%      Load one or more data sets from text file, Excel file or mat file.
%  
%  Use 'Q-Plot' tab and 'Table' tab to view the imported data
% 	
%  File>Save as
%      Save project to a *.mat file.
% 	
%  Completed cases are listed based on the user descriptions on the Data tab.
% 
%  Analysis>Plot Menu
%      Select data and generate plots of results
%      Use Plot tab to generate customised analysis plot and see statistical output
%
%  Analysis>Statistics
%      Select data and various types of statistical analysis
%      Use Stats tab to view statistical output (not saved but viewable while 
%      Statistics UI remains open).

%% Manual
% The <matlab:estdb_open_manual manual> provides further details of setup and 
% configuration of the model. The files for the example use case can be found in
% the example folder <matlab:estdb_example_folder here>. 

%% See Also
% <matlab:doc('muitoolbox') muitoolbox>, <matlab:doc('dstoolbox') dstoolbox>.
	