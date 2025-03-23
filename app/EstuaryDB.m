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
        vNumber = '2.0'
        vDate   = 'March 2025'
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
                                                             
            MenuLabels = {'File','Clear','Project','Setup','Tools',...
                                                        'Analysis','Help'};
            menu = menuStruct(obj,MenuLabels);  %create empty menu struct
            %
            %% File menu --------------------------------------------------
             %list as per muiModelUI.fileMenuOptions
            menu.File.List = {'New','Open','Save','Save as','Exit'};
            menu.File.Callback = repmat({@obj.fileMenuOptions},[1,5]);
            
            %% Clear menu -------------------------------------------------
            %list as per muiModelUI.toolsMenuOptions
            menu.Clear(1).List = {'Refresh','Clear all'};
            menu.Clear(1).Callback = {@obj.refresh, 'gcbo;'};  
            
            % submenu for 'Clear all'
            menu.Clear(2).List = {'Model','Figures','Cases'};
            menu.Clear(2).Callback = repmat({@obj.toolsMenuOptions},[1,3]);

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
            N = 1;
            menu.Setup(N).List = {'Import Table Data','Import Spatial Data',...
                                  'Estuary Properties','Grid Parameters',...
                                  'Grid Tools','Sections','Waterbody'...
                                  'Input Parameters','Model Constants'};                                                                         
            menu.Setup(N).Callback = [repmat({'gcbo;'},[1,3]),...
                                     {@obj.gridMenuOptions},...
                                     repmat({'gcbo;'},[1,3]),...
                                     repmat({@obj.setupMenuOptions},[1,2])];
            %add separators to menu list (optional - default is off)
            menu.Setup(N).Separator = {'off','off','off','on',...
                                             'off','off','off','on','on'}; %separator preceeds item
            
            % submenu for Import Data (if these are changed need to edit
            % loadMenuOptions to be match)
            N = N+1;
            menu.Setup(N).List = {'Load','Add to Table','Delete from Table'};
            menu.Setup(N).Callback = {@obj.loadTableOptions,'gcbo;','gcbo;'};
            N = N+1;
            menu.Setup(N).List = {'Rows','Variables','Dataset'};
            menu.Setup(N).Callback = repmat({@obj.loadTableOptions},[1,3]);
            N = N+1;
            menu.Setup(N).List = {'Rows','Variables','Dataset'};
            menu.Setup(N).Callback = repmat({@obj.loadTableOptions},[1,3]);
            N = N+1;
            menu.Setup(N).List = {'Load or Add dataset','Load archive file',...
                  'Add/Edit Summary','Add/Edit Location','Delete dataset'};
            menu.Setup(N).Callback = repmat({@obj.loadMenuOptions},[1,5]);
            N = N+1;
            menu.Setup(N).List = {'Tidal Levels','River Discharge','Classification'};
            menu.Setup(N).Callback = repmat({'gcbo;'},[1,3]);   
            N = N+1;
            menu.Setup(N).List = {'Add','Edit','Delete'};
            menu.Setup(N).Callback = repmat({@obj.loadMenuOptions},[1,3]);
            N = N+1;
            menu.Setup(N).List = {'Add','Edit','Delete'};
            menu.Setup(N).Callback = repmat({@obj.loadMenuOptions},[1,3]);
            N = N+1;
            menu.Setup(N).List = {'Add','Edit','Delete'};
            menu.Setup(N).Callback = repmat({@obj.loadMenuOptions},[1,3]);
            N = N+1;         
            menu.Setup(N).List = {'Translate Grid','Rotate Grid',...
                                  'Re-Grid','Sub-Grid',...
                                  'Combine Grids','Add Surface','Infill Surface',...
                                  'To curvilinear','From curvilinear',... 
                                  'Display Dimensions','Difference Plot',...
                                  'Plot Sections','Grid Image','Digitise Line',...
                                  'Export xyz Grid','User Function'};                                                                          
            menu.Setup(N).Callback = repmat({@obj.gridMenuOptions},[1,16]);
            menu.Setup(N).Separator = [repmat({'off'},[1,7]),...
                       {'on','off','on','off','off','off','on','on','on'}];%separator preceeds item
            N = N+1;
            menu.Setup(N).List = {'Boundary',...
                                  'Channel Network',...                                  
                                  'Section Lines',...
                                  'Sections',...
                                  'Channel Links',...                                  
                                  'View Sections'};                            
            menu.Setup(N).Callback = [repmat({'gcbo;'},[1,3]),...
                         repmat({@obj.sectionMenuOptions},[1,2]),{'gcbo;'}];
            menu.Setup(N).Separator = repmat({'off'},[1,6]);  
            N = N+1;
            menu.Setup(N).List = {'Generate','Load','Edit','Delete','Export'};
            menu.Setup(N).Callback = repmat({@obj.sectionMenuOptions},[1,5]);
            N = N+1;
            menu.Setup(N).List = {'Generate','Load','Edit','Delete','Export'};
            menu.Setup(N).Callback = repmat({@obj.sectionMenuOptions},[1,5]);         
            N = N+1;
            menu.Setup(N).List = {'Generate','Load','Edit','Delete','Export'};
            menu.Setup(N).Callback = repmat({@obj.sectionMenuOptions},[1,5]);
            N = N+1;
            menu.Setup(N).List = {'Layout','Sections','Network'};
            menu.Setup(N).Callback = repmat({@obj.sectionMenuOptions},[1,3]);
            N = N+1;
            menu.Setup(N).List = {'Generate','Load','Edit','Delete','Export','View'};
            menu.Setup(N).Callback = repmat({@obj.sectionMenuOptions},[1,6]);

            %% Tools menu ---------------------------------------------------
            menu.Tools(1).List = {'Hypsometry','Gross Properties',...
                                 'Combine Tables','Archive','Derive Output','User Tools'};
            menu.Tools(1).Callback = [repmat({'gcbo;'},[1,2]),...
                                     repmat({@obj.toolsMenuOptions},[1,4])];
            menu.Tools(1).Separator = {'off','off','off','off','on','on'}; %separator preceeds item

            menu.Tools(2).List = {'Surface area','Width'};
            menu.Tools(2).Callback = repmat({@obj.toolsMenuOptions},[1,2]);

            menu.Tools(3).List = {'Add','Edit','Delete'};
            menu.Tools(3).Callback = repmat({@obj.loadMenuOptions},[1,3]);

            %% Plot menu --------------------------------------------------  
            menu.Analysis(1).List = {'Plots','Statistics','Tabular Plots',...
                                     'Hypsometry Plots','User Plots'};
            menu.Analysis(1).Callback = repmat({@obj.analysisMenuOptions},[1,5]);
            menu.Analysis(1).Separator = {'off','off','on','off','on'}; %separator preceeds item
            
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
            tabs.Estuary = {'  Estuary  ',@obj.refresh}; 
            tabs.Data  = {'   Data   ',@obj.refresh};       
            tabs.Inputs = {'  Inputs  ',@obj.InputTabSummary};
            tabs.Table = {' Properties ',''};
            subtabs.Table(1,:)   = {'  Summary  ',@obj.getTabData};
            subtabs.Table(2,:)   = {'  Dataset  ',@obj.getTabData};
            subtabs.Table(3,:)   = {' Tides ',@obj.getTabData};
            subtabs.Table(4,:)   = {' Rivers ',@obj.getTabData};
            subtabs.Table(5,:)   = {'Classification',@obj.getTabData};
            subtabs.Table(6,:)   = {' Morphology ',@obj.getTabData};

            tabs.Plot   = {'  Q-Plot  ',@obj.getTabData};
            tabs.Stats = {'   Stats   ',@obj.setTabAction};
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
        function setTabAction(obj,src,cobj)
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
                case 'Summary'
                    classname = metaclass(cobj).Name;
                    if strcmp(classname,'EDBimport')
                        tabSummary(cobj,obj,src)
                    else
                        getdialog('Not an estuary data set (EDBimport)')
                    end
                case 'Dataset'
                    tabTable(cobj,src); 
                case {'Tides','Rivers','Morphology','Classification'}
                    classname = metaclass(cobj).Name;
                    if strcmp(classname,'EDBimport')
                       tabTablesection(cobj,src);  
                    else
                        getdialog('Not an estuary data set (EDBimport)')
                    end
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
                case 'Waterbody'
                    PL_Sections.sectionMenuOptions(obj,src,{'EDBimport'});
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
                case 'Load archive file'
                    EDBimport.loadArchive(obj.Cases);
                case 'Add/Edit Summary'
                    EDBimport.addSummary(obj.Cases);
                case 'Add/Edit Location'
                    EDBimport.addLocation(obj.Cases);
                case 'Delete dataset'
                    useCase(obj.Cases,'single',{classname},'delDataset');                             
            end
            
            switch src.Text
                case 'Add'
                    switch src.Parent.Text
                        case {'Tidal Levels','River Discharge','Classification'}
                            EDBimport.loadEstuaryData(obj.Cases,src.Parent.Text);
                        case 'Gross Properties'
                            EDBimport.loadTable(obj.Cases,src.Parent.Text);
                    end
                case 'Edit'
                    EDBimport.editTable(obj.Cases,src.Parent.Text);
                case 'Delete'
                    EDBimport.deleteTable(obj.Cases,src.Parent.Text);
            end

            DrawMap(obj);
        end
%%
        function sectionMenuOptions(obj,src,~)
            %callback functions to import or create sections
            classname = {'EDBimport'};
            if strcmp(src.Text,'Generate')
                %EDBimport inherits GDinterface, which includes the grids
                %needed for PL_Sections methods
                PL_Sections.sectionMenuOptions(obj,src.Parent,classname);
            elseif any(strcmp({'Sections','Channel Links'},src.Text))
                PL_Sections.sectionMenuOptions(obj,src,classname);
            elseif any(strcmp({'Layout','Sections','Network'},src.Text))
                PL_Sections.sectionMenuOptions(obj,src,classname);
            elseif strcmp(src.Text,'Load')
                PL_Sections.loadLines(obj,src.Parent,classname);
            elseif strcmp(src.Text,'Edit')
                PL_Sections.editLines(obj,src,classname);
            elseif strcmp(src.Text,'Delete')
                PL_Sections.deleteLines(obj,src,classname);
            elseif strcmp(src.Text,'View')
                PL_Sections.view_WBlines(obj,src,classname);
            elseif strcmp(src.Text,'Export')
                PL_Sections.exportLines(obj,src,classname);
            end
            DrawMap(obj);
        end  
%%
        function gridMenuOptions(obj,src,~)
            %callback functions for grid tools options
            gridclasses = {'EDBimport'};
            switch src.Text
                case 'Grid Parameters'
                    GD_GridProps.setInput(obj);
                otherwise
                    %EDBimport inherits GDinterface, which includes the grid tools
                    GDinterface.gridMenuOptions(obj,src,gridclasses);
            end
            DrawMap(obj);
        end    

        %% Tools menu -------------------------------------------------------
        function toolsMenuOptions(obj,src,~)
            %callback functions to run model
            switch src.Text                   
                case 'Models'
                    obj.mUI.ProbeUI = EDB_ProbeUI.getProbeUI(obj);
                case {'Surface area','Width'}
                    EDBimport.loadTable(obj.Cases,src.Text); 
                case 'Combine Tables'
                    EDBimport.combineTables(obj);
                case 'Archive'
                    EDBimport.archiveTables(obj);
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
                case 'Tabular Plots'
                    edb_table_plots(obj);  
                case 'Hypsometry Plots'
                    edb_hypsometry_plots(obj);  
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
            ecdata = {'0','Type','Description of individual cases','#','#','xxx'};
            irec = 1;
            for i=1:length(caseid)
                case_id = num2str(caseid(i));
                if ~isfield(muicat.DataSets,caseclass{i}) || ...
                                  isempty(muicat.DataSets.(caseclass{i}))
                    type = 'New';
                else
                    type = caseclass{i};
                end
                %
                if strcmp(ht.Tag,'Estuary')
                    cobj = getCase(muicat,caserec(i));
                    lat = cobj.Location.Longitude;
                    long = cobj.Location.Latitude;
                    proj = cobj.Location.Projection;
                    ecdata(irec,:) = {case_id,type,char(casedesc{i}),long,lat,proj};
                else
                    dst = getDataset(muicat,caserec(i),1);
                    if isempty(dst), continue; end
                    reclen = num2str(height(dst.DataTable));
                    cdata(irec,:) = {case_id,type,char(casedesc{i}),reclen}; 
                end
                irec = irec+1;
            end
            
            if strcmp(ht.Tag,'Estuary')
                headers = {'ID','Model Class','Model Description',...
                           'Long/East','Lat/North','Projection'};
                cwidth = {25 100 240 70 70 70 };
                cdata = ecdata;
            else
                headers = {'ID','Data Class','Data Description','Nrec'};
                cwidth = {25 100 380 70};
            end
            
            % draw table of case descriptions
            tc=uitable('Parent',ht,'Units','normalized',...
                'CellSelectionCallback',@obj.caseCallback,...
                'Tag','cstab');
            tc.ColumnName = headers;
            tc.RowName = {};
            tc.Data = cdata;
            tc.ColumnWidth = cwidth;
            tc.RowStriping = 'on';
            tc.Position(3:4)=[0.935 0.8];    %may need to use tc.Extent?
            tc.Position(2)=0.9-tc.Position(4);
        end   
%%
        function subset = tabSubset(obj,srctxt)  
            %get the cases of a given CaseType and return as logical array
            %in CoastalTools seperate data from everything else
            % srctxt - Tag for selected tab (eg src.Tag)
            % Called by MapTable. Separate function so that it can be 
            % overloaded from muiModelUI version.
            caseclass = obj.Cases.Catalogue.CaseClass;
            switch srctxt
                case 'Estuary'
                    subset = contains(caseclass,'EDBimport');   
                otherwise
                    subset = ~contains(caseclass,'EDBimport');  
            end
        end
%%


    end 

%%
    methods
        function vN = getVersion(obj)
            vN = obj.vNumber;
        end
    end
end    
    
    
    
    
    
    
    
    
    
    