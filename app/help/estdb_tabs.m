%% Tab options
% The Tabs display various information such as a list of data sets available (Cases), a summary of what is 
% currently defined and rapid access to simple plots. Note: these only update when clicked on using a mouse 
% and values cannot be edited from the Tabs.

%% Summary of Tabs
% * *Data*: lists the cases that have been run with a case id and description.
% * *Models*: lists the cases for model runs or derived data sets.
% * *Inputs*: summmary of the properties that have been defined.
% * *Table*: tabulates a selected dataset (display only) and has the following sub-Tabs:
% * _Dataset_: tabulates Case datasets that are scalar, vector or matrices.
% * _Tides_: tabulates any tidal elevation data added for the specific estuary.
% * _Rivers_: tabulates any river discharge data added for the specific estuary.
% * _Morphology_: tabulates the gross properties for the estuary derived from either the surface area hypsometry or the width hypsometry and selected tidal range.
% * *Q-Plot*: user selects a variable from imported data or model output, and creates a plot on the tab. The plot cannot be edited.
% * *Stats*: view statistical output that are tabulr (not saved but viewable while Statistics UI remains open).


%% Accessing Case meta-data
% On the *Cases* tab, using the mouse to click on a case record generates a
% table figure with a summary of the meta-data for the selected case. The
% figure includes buttons to Copy the data to the clipboard, view the
% DSproperties of the selected dataset and examine the Source of the
% dataset, which may be alist of files for imported data or details of the
% model used.

%% See Also
% The <matlab:estdb_open_manual manual> provides further details of setup and 
% configuration of the model.