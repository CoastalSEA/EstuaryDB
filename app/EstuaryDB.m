classdef EstuaryDB < muiModelUI                        
%
%-------class help---------------------------------------------------------
% NAME
%   UseUI_template.m
% PURPOSE
%   Main GUI for a generic model interface, which implements the 
%   muiModelUI abstract class to define main menus.
% SEE ALSO
%   Abstract class muiModelUI.m and tools provided in muitoolbox
%
% Author: Ian Townend
% CoastalSEA (c) Jan 2021
%--------------------------------------------------------------------------
% 
    properties  (Access = protected)
        %implement properties defined as Abstract in muiModelUI
        vNumber = '1.0'
        vDate   = 'May 2024'
        modelName = 'EstuaryDB'                        
        %Properties defined in muiModelUI that need to be defined in setGui
        % ModelInputs  %classes required by model: used in isValidModel check 
        % DataUItabs   %struct to define type of muiDataUI tabs for each use                         
    end
    
    methods (Static)
        function obj = EstuaryDB                      
            %constructor function initialises GUI
            isok = check4muitoolbox(obj);
            if ~isok, return; end
            %
            obj = setMUI(obj);             
        end
    end
%% ------------------------------------------------------------------------
% Definition of GUI Settings
%--------------------------------------------------------------------------  
    methods (Access = protected)
        function obj = setMUI(obj)
            %initialise standard figure and menus    
            %classes required to run model, format:
            %obj.ModelInputs.<model classname> = {'Param_class1',Param_class2',etc}
            %                                        % << Edit to model and input parameters classnames 
            obj.ModelInputs.EDBmodel = {'EDBparameters'};
            %tabs to include in DataUIs for plotting and statistical analysis
            %select which of the options are needed and delete the rest
            %Plot options: '2D','3D','4D','2DT','3DT','4DT'
            obj.DataUItabs.Plot = {'2D','3D'};  
            %Statistics options: 'General','Timeseries','Taylor','Intervals'
            obj.DataUItabs.Stats = {'General'};  
            
            modelLogo = 'EstuaryDB_logo.jpg';  %default splash figure - edit to alternative
            initialiseUI(obj,modelLogo); %initialise menus and tabs                  
        end    
        
%% ------------------------------------------------------------------------
% Definition of Menu Settings
%--------------------------------------------------------------------------
        function menu = setMenus(obj)
            %define top level menu items and any submenus
            %MenuLabels can any text but should avoid these case-sensitive 
            %reserved words: "default", "remove", and "factory". If label 
            %is not a valid Matlab field name this the struct entry
            %is modified to a valid name (eg removes space if two words).
            %The 'gcbo:' Callback text triggers an additional level in the 
            %menu. Main menu labels are defined in sequential order and 
            %submenus in order following each brach to the lowest level 
            %before defining the next branch.         
                                                             
            MenuLabels = {'File','Tools','Project','Setup','Run',...
                                                        'Analysis','Help'};
            menu = menuStruct(obj,MenuLabels);  %create empty menu struct
            %
            %% File menu --------------------------------------------------
             %list as per muiModelUI.fileMenuOptions
            menu.File.List = {'New','Open','Save','Save as','Exit'};
            menu.File.Callback = repmat({@obj.fileMenuOptions},[1,5]);
            
            %% Tools menu -------------------------------------------------
            %list as per muiModelUI.toolsMenuOptions
            menu.Tools(1).List = {'Refresh','Clear all'};
            menu.Tools(1).Callback = {@obj.refresh, 'gcbo;'};  
            
            % submenu for 'Clear all'
            menu.Tools(2).List = {'Model','Figures','Cases'};
            menu.Tools(2).Callback = repmat({@obj.toolsMenuOptions},[1,3]);

            %% Project menu -----------------------------------------------
            menu.Project(1).List = {'Project Info','Cases','Export/Import'};
            menu.Project(1).Callback = {@obj.editProjectInfo,'gcbo;','gcbo;'};
            
            %list as per muiModelUI.projectMenuOptions
            % submenu for Scenarios
            menu.Project(2).List = {'Edit Description','Edit DS properties',...
                                    'Edit Data Set','Modify Variable Type',...
                                    'Save Data Set','Delete Case','Reload Case',...
                                    'View Case Settings'};                                               
            menu.Project(2).Callback = repmat({@obj.projectMenuOptions},[1,8]);
            menu.Project(2).Separator = {'off','on','off','off','off','off','on','off'}; 

            % submenu for 'Export/Import'                                          
            menu.Project(3).List = {'Export Case','Import Case'};
            menu.Project(3).Callback = repmat({@obj.projectMenuOptions},[1,2]);
            
            %% Setup menu -------------------------------------------------
            menu.Setup(1).List = {'Import Table Data','Import Spatial Data',...
                                  'Add table from bathymetry','Grids','Sections',...
                                  'Input Parameters','Model Constants'};                                                                         
            menu.Setup(1).Callback = [repmat({'gcbo;'},[1,5]),repmat({@obj.setupMenuOptions},[1,2])];
            %add separators to menu list (optional - default is off)
            menu.Setup(1).Separator = {'off','off','off','on','off','on','on'}; %separator preceeds item
            
            % submenu for Import Data (if these are changed need to edit
            % loadMenuOptions to be match)
            menu.Setup(2).List = {'Load','Add to Table','Delete from Table'};
            menu.Setup(2).Callback = {@obj.loadTableOptions,'gcbo;','gcbo;'};

            menu.Setup(3).List = {'Rows','Variables','Dataset'};
            menu.Setup(3).Callback = repmat({@obj.loadTableOptions},[1,3]);

            menu.Setup(4).List = {'Rows','Variables','Dataset'};
            menu.Setup(4).Callback = repmat({@obj.loadTableOptions},[1,3]);

            menu.Setup(5).List = {'Load or Add dataset','Delete dataset'};
            menu.Setup(5).Callback = repmat({@obj.loadMenuOptions},[1,2]);

            menu.Setup(6).List = {'Surface area','Width','Properties'};
            menu.Setup(6).Callback = repmat({@obj.loadMenuOptions},[1,3]);

            menu.Setup(7).List = {'Grid Parameters','Grid Tools'};
            menu.Setup(7).Callback = [{@obj.loadGridOptions},{'gcbo;'}];

            menu.Setup(8).List = {'Translate Grid','Rotate Grid',...
                                  'Re-Grid','Sub-Grid',...
                                  'Combine Grids','Add Surface',...
                                  'To curvilinear','From curvilinear',... 
                                  'Display Dimensions','Difference Plot',...
                                  'Plot Sections','Digitise Line',...
                                  'Export xyz Grid','User Function'};                                                                          
            menu.Setup(8).Callback = repmat({@obj.gridMenuOptions},[1,14]);
            menu.Setup(8).Separator = [repmat({'off'},[1,6]),...
                             {'on','off','on','off','off','on','on','on'}];%separator preceeds item

            menu.Setup(9).List = {'Bounding polygon','Section Tools'};
            menu.Setup(9).Callback = [{@obj.loadSectionOptions},{'gcbo;'}];

            menu.Setup(10).List = {'Load','Add','Edit','Delete'};
            menu.Setup(10).Callback = repmat({@obj.loadSectionOptions},[1,4]);
            
            %% Run menu ---------------------------------------------------
            menu.Run(1).List = {'Models','Derive Output','User Tools'};
            menu.Run(1).Callback = repmat({@obj.runMenuOptions},[1,3]);
            menu.Run(1).Separator = {'off','off','on'}; %separator preceeds item

            %% Plot menu --------------------------------------------------  
            menu.Analysis(1).List = {'Plots','Statistics','User Plots'};
            menu.Analysis(1).Callback = repmat({@obj.analysisMenuOptions},[1,3]);
            menu.Analysis(1).Separator = {'off','off','on'}; %separator preceeds item
            
            %% Help menu --------------------------------------------------
            menu.Help.List = {'Documentation','Manual'};
            menu.Help.Callback = repmat({@obj.Help},[1,2]);
            
        end
        
%% ------------------------------------------------------------------------
% Definition of Tab Settings
%--------------------------------------------------------------------------
        function [tabs,subtabs] = setTabs(obj)
            %define main tabs and any subtabs required. struct field is 
            %used to set the uitab Tag (prefixed with sub for subtabs). 
            %Order of assignment to struct determines order of tabs in figure.
            %format for tabs: 
            %    tabs.<tagname> = {<tab label>,<callback function>};
            %format for subtabs: 
            %    subtabs.<tagname>(i,:) = {<subtab label>,<callback function>};
            %where <tagname> is the struct fieldname for the top level tab. 
            tabs.Data  = {'   Data  ',@obj.refresh};        
            tabs.Models = {'  Models  ',@obj.refresh};           
            tabs.Inputs = {'  Inputs  ',@obj.InputTabSummary};
            tabs.Table = {'  Table  ',@obj.getTabData};
            tabs.Plot   = {'  Q-Plot  ',@obj.getTabData};
            %if subtabs are not required eg for Stats
            tabs.Stats = {'   Stats   ',@obj.setTabAction};
            subtabs = [];
        end
       
%%
        function props = setTabProperties(~)
            %define the tab and position to display class data tables
            %props format: {class name, tab tag name, position, ...
            %               column width, table title}
            % position and column widths vary with number of parameters
            % (rows) and width of input text and values. Inidicative
            % positions:  top left [0.95,0.48];    top right [0.95,0.97]
            %         bottom left [0.45, 0.48]; bottom right [0.45,0.97]
            props = {... 
                'GD_GridProps','Inputs',[0.90,0.95],{160,90}, 'Grid parameters:';...
                'EDBparameters','Inputs',[0.90,0.48],{180,60},'Input parameters:'};
        end    
 %%
        function setTabAction(~,src,cobj)
            %function required by muiModelUI and sets action for selected
            %tab (src)
            msg = 'No results to display';
            switch src.Tag                                
                case 'Plot' 
                     tabPlot(cobj,src);
                case 'Stats'
                    lobj = getClassObj(obj,'mUI','Stats',msg);
                    if isempty(lobj), return; end
                    tabStats(lobj,src);
                case 'Table'
                    classname = metaclass(cobj).Name;
                    tabTable(cobj,src); 
%                     if strcmp(classname,'EDBimport')
% 
%                     else
%                         tabTable(cobj,src);   
%                     end
            end
        end      
%% ------------------------------------------------------------------------
% Callback functions used by menus and tabs
%-------------------------------------------------------------------------- 
        %% File menu ------------------------------------------------------
        %use default menu functions defined in muiModelUI
            
        %% Tools menu -----------------------------------------------------
        %use default menu functions defined in muiModelUI
                
        %% Project menu ---------------------------------------------------
        %use default menu functions defined in muiModelUI           

        %% Setup menu -----------------------------------------------------
        function setupMenuOptions(obj,src,~)
            %callback functions for data input
            switch src.Text
                case 'Input Parameters'                       
                    EDBparameters.setInput(obj);  
                    %update tab display with input data
                    tabsrc = findobj(obj.mUI.Tabs,'Tag','Inputs');
                    InputTabSummary(obj,tabsrc);
                case 'Model Constants'
                    obj.Constants = setInput(obj.Constants);
            end
        end  
%%
        function loadTableOptions(obj,src,~)
            %callback functions to import tabular data
            classname = 'muiTableImport';
            switch src.Text
                case 'Load'
                    muiTableImport.loadData(obj.Cases);
                otherwise
                    switch src.Parent.Text
                        case 'Add to Table'
                            functxt = ['add',src.Text];
                        case 'Delete from Table'
                            functxt = ['del',src.Text];
                        otherwise
                            functxt = [];
                    end
                    useCase(obj.Cases,'single',{classname},functxt);
            end
            DrawMap(obj);
        end   
%%
        function loadMenuOptions(obj,src,~)
            %callback functions to import vector data
            classname = 'EDBimport';
            switch src.Text
                case 'Load or Add dataset'
                    EDBimport.loadData(obj.Cases);
                case 'Delete dataset'
                    useCase(obj.Cases,'single',{classname},'delDataset'); 
                case 'Surface area'
                    EDBimport.loadTable(obj.Cases,src.Text);
                case 'Width'
                    EDBimport.loadTable(obj.Cases,src.Text);
                case 'Properties'
                    EDBimport.loadProperties(obj.Cases);
            end
            DrawMap(obj);
        end
%%
        function loadGridOptions(obj,src,~)
            %callback functions to import data
            classname = 'EDB_GridImport';
            switch src.Text
                case 'Load'
                    fname = sprintf('%s.loadData',classname);
                    callStaticFunction(obj,classname,fname); 
                case 'Add'
                    useCase(obj.Cases,'single',{classname},'addData');
                case 'Delete'
                    useCase(obj.Cases,'single',{classname},'deleteGrid');
                case 'Grid Parameters'
                    GD_GridProps.setInput(obj);  
            end
            DrawMap(obj);
        end  
%%
        function gridMenuOptions(obj,src,~)
            %callback functions for grid tools options
            gridclasses = {'EDBimport'};
            %CF_FromModel inherits GDinterface, which includes the grid tools
            GDinterface.gridMenuOptions(obj,src,gridclasses);
            DrawMap(obj);
        end    

        %% Run menu -------------------------------------------------------
        function runMenuOptions(obj,src,~)
            %callback functions to run model
            switch src.Text                   
                case 'Models'
                    obj.mUI.ProbeUI = EDB_ProbeUI.getProbeUI(obj);
                case 'Derive Output'
                    obj.mUI.ManipUI = muiManipUI.getManipUI(obj);
                case 'User Tools'
                    edb_user_tools(obj);     
            end            
        end               
            
        %% Analysis menu ------------------------------------------------------
        function analysisMenuOptions(obj,src,~)
            switch src.Text
                case 'Plots'
                    obj.mUI.PlotsUI = muiPlotsUI.getPlotsUI(obj);
                case 'Statistics'
                    obj.mUI.StatsUI = muiStatsUI.getStatsUI(obj);
                case 'User Plots'                            
                    edb_user_plots(obj);     
            end            
        end

        %% Help menu ------------------------------------------------------
        function Help(~,src,~)
            %menu to access online documentation and manual pdf file                  
            switch src.Text
                case 'Documentation'
                    doc estuarydb          %must be name of html help file 
                case 'Manual'
                    estdb_open_manual;
            end  
        end

        %% Check that toolboxes are installed------------------------------
        function isok = check4muitoolbox(~)
            %check that dstoolbox and muitoolbox have been installed
            fname = 'dstable.m';
            dstbx = which(fname);

            fname = 'muiModelUI.m';
            muitbx = which(fname);

            if isempty(dstbx) && ~isempty(muitbx)
                warndlg('dstoolbox has not been installed')
                isok = false;
            elseif ~isempty(dstbx) && isempty(muitbx)
                warndlg('muitoolbox has not been installed')
                isok = false;
            elseif isempty(dstbx) && isempty(muitbx)
                warndlg('dstoolbox and muitoolbox have not been installed')
                isok = false;
            else
                isok = true;
            end
        end
%% ------------------------------------------------------------------------
% Overload muiModelUI.MapTable to customise Tab display of records (if required)
%--------------------------------------------------------------------------     
        function MapTable(obj,ht)
            %create tables for Data and Model tabs - called by DrawMap
            % load case descriptions
            muicat = obj.Cases;
            caserec = find(tabSubset(obj,ht.Tag));
            caseid = muicat.Catalogue.CaseID(caserec);
            casedesc = muicat.Catalogue.CaseDescription(caserec);
            caseclass = muicat.Catalogue.CaseClass(caserec);

            cdata = {'0','Type','Description of individual cases','#'};
            irec = 1;
            for i=1:length(caseid)
                case_id = num2str(caseid(i));
                if ~isfield(muicat.DataSets,caseclass{i}) || ...
                                  isempty(muicat.DataSets.(caseclass{i}))
                    type = 'New';
                else
                    type = caseclass{i};
                    if contains(type,'CT_')
                        type = split(type,'_');
                        type = type{2};
                    elseif strcmpi(type(1:2),'ct')
                        type = type(3:end);
                    end
                end
                %
                dst = getDataset(muicat,caserec(i),1);
                if isempty(dst), continue; end
                reclen = num2str(height(dst.DataTable));
                cdata(irec,:) = {case_id,type,char(casedesc{i}),reclen}; 
                irec = irec+1;
            end
            
            if strcmp(ht.Tag,'Models')
                headers = {'ID','Model Class','Model Description','Nrec'...
                };
            else
                headers = {'ID','Data Class','Data Description','Nrec'...
                };
            end
            
            % draw table of case descriptions
            tc=uitable('Parent',ht,'Units','normalized',...
                'CellSelectionCallback',@obj.caseCallback,...
                'Tag','cstab');
            tc.ColumnName = headers;
            tc.RowName = {};
            tc.Data = cdata;
            tc.ColumnWidth = {25 100 380 70};
            tc.RowStriping = 'on';
            tc.Position(3:4)=[0.935 0.8];    %may need to use tc.Extent?
            tc.Position(2)=0.9-tc.Position(4);
        end   
    end    
end    
    
    
    
    
    
    
    
    
    
    