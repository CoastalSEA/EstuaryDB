%% Menu Options
% Summary of the options available for each drop down menu.

%% File
% * *New*: clears any existing model (prompting to save if not already saved) and a popup dialog box prompts for Project name and Date (default is current date). 
% * *Open*: existing Asmita models are saved as *.mat files. User selects a model from dialog box.
% * *Save*: save a file that has already been saved.
% * *Save as*: save a file with a new or different name.
% * *Exit*: exit the program. The close window button has the same effect.

%% Tools
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
% * *Cases > Reload*: user selects a Case to reload as the current parameter settings.
% * *Cases > View settings*: user selects a Case to display a table listing the parameters used for the selected Case. 
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

%% Setup > Add Table from Bathymetry
% Use a loaded bathymetry data set to construct surface area or
% along-channel width hypsometry datasets. Tese options replicate the data
% formats tha can be imported using the *Import Table Data* option.
%%
% * *Surface area* -- derive the surface area hypsometry from an imported
% bathymetry (to save space import the grid, run the utility and then delete
% the grid).
% * *Width* - derive the along-channel width hypsometry from an imported
% bathymetry (to save space import the grid, run the utility and then delete
% the grid).
% * *Properties* - derive gross properties for an estuary. Can use
% bathymetry, surface area hypsometry table or width hypsometry table.

%% Setup > Import Spatial Data
% * *Load or Add Dataset* - load various forms of spatial data, such as
% bathymetry, surface area hypsometry, along-channel width hypsometry and
% images. the format to be loaded is defined in a format file (see further details <matlab:doc('estdb_class_fcns') here>.)
%  and the file name is used to assign either create an estuary Case or add the data as
% a new dataset to an existing case. If the dataset already exists the user
% is prompted to either overwrite the existing dataset, or add another dataset 
% of the same type.
% * *Delete Dataset* - select an estuary case and the Dataset(s) to be
% deleted.

%% Setup > Grids
% * *Grid Tools > Translate Grid*: interactively translate grid x-y
% coordinates;
% * *Grid Tools > Rotate Grid*: interactively flip or rotate grid;   
% * *Grid Tools > Re-Grid*: regrid a gridded dataset to match another grid or to user
% specified dimensions;
% * *Grid Tools > Sub-Grid*: interactively define a subgrid and save grid as a new Case;               
% * *Grid Tools > Combine Grids*: superimpose one grid on another based on maximum
% or minimum set of values;
% * *Grid Tools > Add Surface*: add horizontal surface to an extisting
% grid;
% * *Grid Tools > To curvilinear*: map grid from cartesian to curvilinear coordinates; 
% * *Grid Tools > From curvilinear*: map grid from curvilinear to cartesian
% coordinates;
% * *Grid Tools > Display Dimensions*: display a table with the dimensions
% of a selected grid;
% * *Grid Tools > Difference Plot*: generate a plot of the difference
% between two grids;
% * *Grid Tools > Plot Sections*: interactively define sections and plot
% them on a figure;
% * *Grid Tools > Digitise Line*: interactively digitise a line (with
% option to add z values) using selected grid as base map;
% * *Grid Tools > Export xyz Grid*: select a Case and export grid as xyz
% tuples;
% * *Grid Parameters*: dialogue to set dimensions of default grid.

%% Setup > Sections
% *Shoreline* - Load or create a polygon, or set of lines, that define the
% shoreline. This is used to determine the extent of the section lines.
% Consequently it does not have to be be an exact, or detailed, representation of the actual
% shoreline but should be positioned at an elevation that captures the 
% desired range for the hypsometry. For example to examine future change
% this might be close to the contour for Highest Tide + 1m to account for
% surge or sea level rise.
%%
% *Section Tools* - Load or create a set of sections across the estuary.
% These are used in conjunction with the bathymetry to create a table for
%  the along-channel width hypsometry (see *Add Table from Bathymetry > Width*)
%%
% * *Load* - load a shapefile with the sections to be used.
% * *Add* - interactively define the sections to be used.
% * *Edit* - interactively edit the end points of an existing set of Sections.
% * *Delete* - select sections to be deleted, or delete all of them.

%% Run
% * *Run Model*: runs model, prompts for a Case description, which is added to the listing on the Cases tab.
% * *Derive Output*: initialises the Derive Output UI to select and define manipulations of the data or call external functions and load the result as new data set.

%% Analysis
% * *Plots*: initialises the Plot UI to select variables and produce various types of plot. The user selects the Case, Dataset and Variable to used, along with the Plot type and any Scaling to be applied from a series of drop down lists, 
% * *Statistics*: initialiss the Statistics UI to select data and run a range of standard statistical methods.

%% Help
% * *Help*: access the online documentation for EstuaryDB.

%% See Also
% The <matlab:estdb_open_manual manual> provides further details of setup and 
% configuration of the model.