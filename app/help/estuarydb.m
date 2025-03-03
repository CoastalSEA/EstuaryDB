%% EstuaryDB
% Combine estuary data from multiple sources for intercomparison and
% further anlysis

%% Licence
% The code is provided as Open Source code (issued under a GNU General 
% Public License).

%% Requirements
% EstuaryDB is written in Matlab(TM) and requires v2020b, or later. In addition, 
% EstuaryDB requires both the <matlab:doc('dstoolbox') dstoolbox> and the 
% <matlab:doc('muitoolbox') muitoolbox> and the estuary and grid libraries
% in the muiAppLib repository (all available at https://github.com/CoastalSEA/EstuaryDB).

%% Background
% EstuaryDB is used to load tables of estuary properties, derived
% hypsometry data for surface area (whole estuary), or width (along channel
% sections), or derive such data from a bathymetry grid. A range of tools
% are then available to plot, tabulate and analyse these datasets.

%% EstuaryDB classes and functions
% The main classes and functions used in EstuaryDB are summarised 
% <matlab:doc('estdb_class_fcns') here>, with further details given in the 
% documenstion for grids, points and lines in the
% <matlab:doc('grid_class_fcns') Grid> and <matlab:doc('points_lines_classes_functions') Points and Lines>
% documentation, which use class  <matlab:doc('gdinterface') GDinterface> 
% and  <matlab:doc('plinterface') PLintereface> interfaces respectively.

%% Usage	
%  Quick Guide to setting up a new analysis:
% 
%  File>New 
%      To create a new project space.
%  Setup>Import Table Data
%      Load one or more data sets from text file, Excel file or mat file.
%  File>Save as
%      Save project to a *.mat file.
%
%  Use 'Q-Plot' tab and 'Table' tab to view the imported data
% 	
%  Completed cases are listed based on the user descriptions on the Data tab.
% 
%  Analysis>Plot Menu
%      Select data and generate plots of results
%      Use Plot tab to generate customised analysis plot and see statistical output
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
	