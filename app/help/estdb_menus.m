%% Menu Options
% Summary of the options available for each drop down menu.

%% File
% * *New*: clears any existing model (prompting to save if not already saved) and a popup dialog box prompts for Project name and Date (default is current date). 
% * *Open*: existing Asmita models are saved as *.mat files. User selects a model from dialog box.
% * *Save*: save a file that has already been saved.
% * *Save as*: save a file with a new or different name.
% * *Exit*: exit the program. The close window button has the same effect.

%% Clear
% * *Refresh*: updates Cases tab.
% * *Clear all > Project*: deletes the current project, including all Setup data and all Cases.
% * *Clear all > Figures*: deletes all results plot figures (useful if a large number of plots have been produced).
% * *Clear all > Cases*: deletes all Cases listed on the Cases tab but does not affect the model setup.

%% Project
% * *Project Info*: edit the Project name and Date
% * *Cases > Edit Description*: user selects a Case to edit the Case description.
% * *Cases > Edit DS properties*: initialises the  UI for editing Data Set properties (DSproperties).
% * *Cases > Edit Data Set*: initialises the Edit Data UI for editing data sets.
% * *Cases > Modify Variable Type*: select a variable and modify the data type of that variable. Used mainly to make data categorical or ordinal.
% * *Cases > Save Data Set*: user selects a data set to be saved from a list of Cases and the is then prompted to name the file. The data are written to an Excel spreadsheet. 
% * *Cases > Delete Case*: user selects Case(s) to be deleted from a list of Cases and these are deleted (model setup is not changed).
% * *Cases > Reload Case*: user selects a Case to reload as the current parameter settings.
% * *Cases > View Case Settings*: user selects a Case to display a table listing the parameters used for the selected Case. 
% * *Export/Import > Export Case*: user selects a Case class instance to export as a mat file.
% * *Export/Import > Import Case*: user selects an exported Case class instance (mat file) to be loaded.
%%
% *NB*: to export the data from a Case for use in another application 
% (eg text file, Excel, etc), use the *Project>Cases>Edit Data Set* option 
% to make a selection and then use the ‘Copy to Clipboard’ button to paste 
% the selection to the clipboard.

%% Setup > Import Table Data
% *Load to Table* - load tabular scalar data from a text file, Excel spreadsheet, 
% or a mat file containing a table or a dstable.
%%
% *Add to Table*
%%
% * *Rows* - add rows to an existing table (must be same variables)
% * *Variables* - add one or more variables to an existing table (must be the same
% number of rows)
% * *Dataset* - add another tabular dataset to the same case record.
%%
% *Delete from Table*
%%
% * *Rows* - delete rows from an existing table
% * *Variables* - delete one or more variables from an existing table
% * *Dataset* - delete a dataset from a case record.

%% Setup > Import Spatial Data
% * *Load or Add Dataset* - load various forms of spatial data, such as
% bathymetry, surface area hypsometry, along-channel width hypsometry and
% images. The format to be loaded is defined in a format file (for further 
% details see documentation <matlab:doc('estdb_class_fcns') here>.)
% and the file name is used to either create an estuary Case, or add the data as
% a new dataset to an existing Case. If the dataset already exists the user
% is prompted to either overwrite the existing dataset, or add another dataset 
% of the same type.
% * *Load archive file* - load an estuary Case from an archived ASCII file. 
% The archive file is created using Tools >Archive and the format of the 
% file is detailed in Appendix F – Archive File Format on the <matlab:estdb_open_manual manual>.
% * *Add/Edit Summary* - add or edit a short description of the estuary
% * *Add/Edit Location* - add or edit the coordinates of the estuary and 
% the grid projection used for the coordinate system.
% * *Delete Dataset* - select an estuary case and the Dataset(s) to be
% deleted (NB: this only deletes Datasets and not the Case, which can be
% deleted using Project>Cases>Delete Case).

%% Setup > Estuary Properties
% Property tables for tides, river discharge and classification can be loaded, 
% edited and deleted using:
%%
% * *Tidal Levels* - a table of the elevations that define, for example, spring
% and neap tides.
% * *River Discharege* - a table of river discharges that define, for
% example, the annual and seasonal discharges into the estuary.
% * *Classification* - a table of classifications that define, for example, 
% the estuary type, tidal type and geomorphic type.

%% Setup > Grid Parameters
% * *Grid Parameters*: dialogue to set dimensions of default grid.
%% Setup > Grid Tools
% * *Translate Grid*: interactively translate grid x-y coordinates;
% * *Rotate Grid*: interactively flip or rotate grid;   
% * *Re-Grid*: regrid a gridded dataset to match another grid or to user
% specified dimensions;
% * *Sub-Grid*: interactively define a subgrid and save grid as a new Case;               
% * *Combine Grids*: superimpose one grid on another based on maximum
% or minimum set of values;
% * *Add Surface*: add horizontal surface to an extisting
% grid;
% * *Infill Surface*: spatial interpolation to infill
% areas with no data;
% * *To curvilinear*: map grid from cartesian to curvilinear coordinates; 
% * *From curvilinear*: map grid from curvilinear to cartesian
% coordinates;
% * *Display Dimensions*: display a table with the dimensions
% of a selected grid;
% * *Difference Plot*: generate a plot of the difference
% between two grids;
% * *Plot Sections*: interactively define sections and plot
% them on a figure;
% * *Grid Image*: save grid as an image struct with fields
% 'XData','YData','CData','CMap','CLim' (includes option to resize large grids; > 1Mb);
% * *Digitise Line*: interactively digitise a line (with
% option to add z values) using selected grid as base map;
% * *Export xyz Grid*: select a Case and export grid as xyz
% tuples;
% * *User Functions*: calss gd_user function.m, an empty function file
% for user to define bespoke use of grids and grid tools.


%% Setup > Sections
% A set of tools to create sections along one or more estuary reaches,
% define the connectivity, extract the sections for use in computing the
% width hypsometry (Setup > Add Hypsometry from Grid > Width). The steps
% for defining the boundary, centre-lines and section lines have sub-menus
% to enable:
%%
% * *Generate* - use the built in tools to aid the creation of the lines.
% This option can be used to modify existing linework, or create new
% linework. The Sections > Boundary tool also has an option to copy the Waterbody linework as an input. 
% * *Load* - load a shapefile with the lines to be used.
% * *Edit* - interactively digitise or edit the linework.
% * *Delete* - delete the saved lines for the selected Case.
% * *Export* - export the saved lines for the selected Case to an ASCII 
% text file (.txt), a Matlab data file (.mat), or a shape file (.shp). 
% Text files include a header with details of the source and line type. 
% The same information is included in the saved metadata struct for the other file formats.

%%
% The Point and Line tools have a menu that is accessed by right clicking
% the mouse in the figure but outside the plot axes. This provides access to
% a set of context sensitive menus. They all include the Figure option,
% which provides access to the following options:
%%
% * Figure > Redraw: update the line work of points and lines in the plot;
% * Figure > Undo: revert to the previously save linework. If Save has not
% been used in the ssession, this will revert to any imported line work;
% * Figure > Distance: display the distance between two points;
% * Figure > Save: save the current points and lines;
% * Figure > Save & Exit: save the current data and exit;
% * Figure > Quit: exit without saving. If new points and lines have been
% created the user is prompted to confirm that these do no need to be
% saved.

%%
% When using the *Edit* option there are menus options for points and lines
% as follows:
%%
% * Point > Add: add one or more points;
% * Point > Edit: edit the position of any existing points;
% * Point > Delete: delete existing points;
%%
% * Line > Add: add one or more lines (each line is terminated with a NaN
% point);
% * Line > Edit: edit the points in a line; 
% * Line > Extend: add points to the end of a line;
% * Line > Insert: insert points within a line;
% * Line > Join: join two lines together;
% * Line > Split: divide a line into two;
% * Line > Delete > Points: delete one or more points in a line.
% * Line > Delete > Lines: delete one or more lines.
%%
% For details of the conventions used for points and lines see the
% <matlab:doc('points_lines_classes_functions') Point & Line>
% documentation.

%%
% Bespoke tools are provided to create the different line types as follows:
%%
% * *Boundary* - Load or create a polygon, or set of lines, that define the
% estuary shoreline. This is used to determine the extent of the section lines.
% Consequently it does not have to be an exact, or detailed, representation of the actual
% shoreline but should be positioned at an elevation that captures the 
% desired range for the hypsometry. For example to examine future change
% this might be close to the contour for Highest Tide + 1m to account for
% surge or sea level rise. Bespoke menus for the Boundary tool include the 
% Line and Figure menus detailed above and:
%%
% * Boundary > Resample: define the sampling interval along the line and
% resample the linework at the required intervals;
% * Boundary > Smooth: use either a moving average of sgolay method to
% smooth the lines;
% * Boundary > Reset: clear the existing lines and generate a new contour
% using NaN or an elevation.

%%
% * *Channel Network* - Individual reaches are captured by defining the end
% points and using a function to trace the deepest channel between the two
% points. When selected the user is prompted to define the maximum
% accessible water level, the depth exponent (value between 5 and 10 usually 
% works well, whereas smaller values tend to follow the shore in meandering channels), 
% and the sampling interval for the linework that is generated.  
% The menu options provided include Line and Figure as detailed
% above and the Centreline menu:
%%
% * Centreline > Set: define start and end points and generate a
% centre-line that attempts to find the shortest distance between the end
% points constrained to also find the deepest part of the channel.
% * Centreline > Resample: define the sampling interval along the line and
% resample the linework at the required intervals;
% * Centreline > Smooth: use either a moving average of sgolay method to
% smooth the lines;
% * Centreline > Reset: clear the existing lines..

%%
% * *Section Lines* - The Boundary and Centre-line need to be defined
% before calling this option.

%%
% In addition to the Figure menu there is a Sections menu, with the
% following options:
%%
% * Sections > Set: uses the points on the centre-line to define a set of
% cross-sections. The user is prompted to input the length of the line either
% side of the centre-line and the sections are then generated;
% * Sections > Clip: clip the cross-section lines to the defined boundary;
% * Sections > Add: add one or more points to the centre-line (either by 
% inserting points, or as an extension of a line). This adds sections at 
% the new centre-line points;
% * Sections > Edit: adjust the end points of existing sections;
% * Sections > Delete: remove one or more sections;
% * Sections > Reset: revert to the initial centre-line defined sections;
% * Sections > Label: add numbered labels to the sections.
%%
% NOTE: _Clip_ shortens the lines based on the intersection with the
% boundary. If the section does not cross the boundary within the specified
% section length, the section is excluded. Re-running _Clip_ after some
% editing of the sections can result in more lines being omitted (because
% the the lines do not cross). It is therefore better to do the edits, and
% then _Set_ the lines before applying the _Clip_ tool.

%%
% Using the 3 sets of lines, the cross-sections can be extracted and the
% channel connectivity can be defined:
%%
% * *Sections* - extract the depths along a set of cross-sections. Section
% lines need to have been defined before using this option.
% * *Channel Links* - define the connections between the different reaches 
% of the channel network. The Centreline needs to be defined before using
% this option.

%%
% There are then options to view the various types of line work:
%%
% * *View Sections > Layout* - creates a plot of the boundary, centre-line 
% and section lines;
% * *View Sections > Sections* - creates a composite plot of all the
% sections (the individual sections can be queried by clicking the mouse on a
% section line).
% * *View Sections > Network* - creates a graph plot of the network with
% the nodes labelled with the index of the point in the centre-line line set and
% the distance from the first point in parenthesis, with the line number
% defined on the edges between the nodes.

%% Setup > Waterbody
% Similar to the boundary tool used for creating Sections, the Waterbody
% tools allows a bounding polygon to be defined for use when computing the
% surface area hypsometry (Setup > Add Hypsometry from Grid > Surface
% area).
%%
% * *Generate* - use the built in tools to aid the creation of the lines.
% This option can be used to modify existing linework, create new linework,
% or copy the Sections > Boundary tool linework.
% * *Load* - load a shapefile with the lines to be used.
% * *Edit* - interactively digitise or edit the waterbody linework.
% * *Delete* - deletes the saved lines for the selected Case.
% * *Export* - export the saved lines for the selected Case to an ASCII 
% text file (.txt), a Matlab data file (.mat), or a shape file (.shp). 
% Text files include a header with details of the source and line type. 
% The same information is included in the saved metadata struct for the other file formats.
% * *View* - creates a plot of the boundary.

%% Setup > Input Parameters
% enter and edit the specified model parameters. The input parameters can be viewed on the Inputs tab.
%% Setup > Model Constants
% various constants are defined for use in models, such as the acceleration due to gravity, viscosity and density of sea water, and density of sediment. Generally, the default values are appropriate (9.81, 1.36e-6, 1025 , 2650 respectively) but these can be adjusted and saved with the project if required.

%% Tools
% * *Hypsometry*: use a loaded bathymetry data set to construct surface area, or along-channel width hypsometry datasets. These options replicate the data formats that can be imported using the Import Spatial Data options.
% * *Hypsometry > Surface area*: derive the surface area hypsometry from an imported bathymetry.
% * *Hypsometry > Width*: derive the along-channel width hypsometry from an imported bathymetry.
% * *Gross Properties*: the large-scale, or gross, morphological properties can be added
% as a table once, Tidal Levels and a Surface area or Width hypsometry have
% been defined. Add a row of data to the morphological properties
% table by selecting a hypsometry and a tidal data set to use.
% * *Combine Tables*: the tabular property data for individual estuary can 
% be combined into a table allowing intercomparison between estuaries. 
% The estuary Cases can be in the current file or in saved project files. 
% The output is a table of values for a number of estuaries. The table cannot 
% accept data from multiple sources with the same estuary name 
% (row names must be unique). Similarly, when combining Gross Property 
% tables, it is necessary to select a single row for inclusion in the combined table. 
% These can be selected based on the Source and Notes in fields of the source tables.
% * *Archive*: save an estuary Case as an ASCII text file. This file can be 
% loaded into EstuaryDB using _Setup > Import Spatial Data > Load archive file_. 
% The format of the saved file is detailed in Appendix F – Archive File Format
% of the <matlab:estdb_open_manual manual>.  _[Under development]_.
% * *Derive Output*: initialises the Derive Output UI to select and define manipulations of the data or call external functions and load the result as new data set.
% * *User Tools*: calls function ‘edb_user_tools.m’, which includes a function to:
%
% # create a figure tabulating a dataset (tabular data only);
% # add additional properties to a table and  (tabular estuary properties data only);
% # run and save the results of a convergence analysis (e.g. for along channel properties);
% # the option for the user to add functions as required.


%% Analysis
% * *Plots*: initialises the Plot UI to select variables and produce
% various types of plot. The user selects the Case, Dataset and Variable to
% used, along with the Plot type and any Scaling to be applied from a series of drop down lists.
% * *Statistics*: initialiss the Statistics UI to select data and run a range of standard statistical methods.
% * *Tabular Plots*: Bespoke plots for scalar tabular data.
%
% # plot a scatter diagram of two or three variables from any case (selected variables must be the same length);
% # plot a bar chart of a variable with the bars coloured based on a selected classification variable (from the same dataset as the main variable);
% # plot a range plot by selecting low-mean-high values of two properties (eg tidal ranges and river discharge);
% # plot a Geyer-McCready plot (Figure 6 in 2014 paper) using the gross properties of the estuaries
%
% * *Hypsometry Plots*: Bespoke plots for the surface area and width
% hypsometry data sets.
%
% # convergence plot has panels for along-channel variation of width, csa and depth and a fourth panel for an image of where the sections were taken (if available in the dataset).
%
% * *User Plots*: calls the edb_user_plots function, allowing additional
% plots to be added as required.

%% Help
% * *Help*: access the online documentation for EstuaryDB.

%% See Also
% The <matlab:estdb_open_manual manual> provides further details of setup and 
% configuration of the model.