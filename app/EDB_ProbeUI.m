classdef EDB_ProbeUI < muiDataUI

   %%TAKEN FROM EF_ProbeUI AND STILL TO BE EDITED TO NEEDS OF EDB **********
%
%-------class help------------------------------------------------------
% NAME
%   EDB_ProbeUI.m
% PURPOSE
%   Class implements the muiDataUI class to access data for use in analysis and
%   plotting
% SEE ALSO
%   muiDataUI.m, muiPLotsUI, muiPlots.m
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2024
%--------------------------------------------------------------------------
% 
    properties (Transient)
        %Abstract variables for muiDataUI---------------------------        
        %names of tabs providing different data accces options
        TabOptions = {'Along Channel','Range'}; 
        %selections that force a call to setVariableLists
        updateSelections = {'Case','Dataset','Variable'};
        %Additional variables for application------------------------------
        Tabs2Use         %number of tabs to include  (set in getPlotGui)     
    end  

%%  
    methods (Access=protected)
        function obj = EDB_ProbeUI(mobj)
            %initialise standard figure and menus
            guititle = 'Select Data for Plotting';
            setDataUIfigure(obj,mobj,guititle);    %initialise figure     
        end
    end   

%%    
    methods (Static)
        function obj = getProbeUI(mobj)
            %this is the function call to initialise the UI and assigning
            %to a handle of the main model UI (mobj.mUI.PlotsUI) 
            %options for selection on each tab are defined in setTabContent
            if isempty(mobj.Cases.Catalogue.CaseID)
                warndlg('No data available to plot');
                obj = [];
                return;
            elseif isfield(mobj.mUI,'ProbeUI') && isa(mobj.mUI.ProbeUI,'EDB_ProbeUI')
                obj = mobj.mUI.ProbeUI;
                if isempty(obj.dataUI.Figure)
                    %initialise figure 
                    guititle = 'Select Data for Analysis';
                    setDataUIfigure(obj,mobj,guititle);    
                    setDataUItabs(obj,mobj); %add tabs 
                else
                    getdialog('EF Analysis UI is open');
                end
            else
                obj = EDB_ProbeUI(mobj);
                obj.Tabs2Use = obj.TabOptions;
                setDataUItabs(obj,mobj); %add tabs                
            end                
        end
    end

%%
%--------------------------------------------------------------------------
% Abstract methods required by muiDataUI to define tab content
%--------------------------------------------------------------------------
    methods (Access=protected) 
        function setTabContent(obj,src)
            %setup default layout options for individual tabs
            %Abstract function required by muiDataUI
            itab = find(strcmp(obj.Tabs2Use,src.Tag));
            obj.TabContent(itab) = muiDataUI.defaultTabContent;
            
            %customise the layout of each tab. Overload the default
            %template with a function for the tab specific definition
            switch src.Tag
                case 'Along Channel'
                    setAC_tab(obj,src);
                case 'Range'
                    setRange_tab(obj,src);   
                case 'Summary Plots'
                    setSum_tab(obj,src);
            end             
        end 

%%
        function setVariableLists(obj,src,mobj)
            %initialise the variable lists or values
            %Abstract function required by muiDataUI
            itab = strcmp(obj.Tabs2Use,src.Tag);
            S = obj.TabContent(itab);
            sel_uic = S.Selections;
            caserec = sel_uic{strcmp(S.Order,'Case')}.Value;
            cobj = getCase(mobj.Cases,caserec);
            dsnames = fieldnames(cobj.Data); 
            idd = strcmp(S.Order,'Dataset');
            ids = sel_uic{idd}.Value; 
            if ids>length(dsnames), ids = 1; sel_uic{idd}.Value = 1; end
%             [dsnames,idDS] = subSelectDatasets(obj,src,cobj); 
%             idd = strcmp(S.Order,'Dataset');
%             if any(idd), ids = sel_uic{idd}.Value; else, ids = 1; end   
            %ids = sel_uic{idd}.Value;
            %if ids>length(dsnames), ids = 1; sel_uic{idd}.Value = 1; end

            for i=1:length(sel_uic)                
                switch sel_uic{i}.Tag
                    case 'Case'
                        muicat = mobj.Cases.Catalogue;
                        sel_uic{i}.String = muicat.CaseDescription;
                        sel_uic{i}.UserData = sel_uic{i}.Value; %used to track changes
                    case 'Dataset'
                        sel_uic{i}.String = dsnames;                        
                        sel_uic{i}.UserData = sel_uic{i}.Value; %used to track changes        
                    case 'Variable'     
                        sel_uic{i}.Value = 1;
                        ds = fieldnames(cobj.Data);
                        %Datasets are subsampled so display order is not
                        %order of Data instance, hence use idDS(ids)
                        sel_uic{i}.String = cobj.Data.(ds{ids}).VariableDescriptions; 
                    case 'Type'
                        sel_uic{i}.String = S.Type; 
                    otherwise
                        sel_uic{i}.String = 'Not set';   
                end
            end        
            obj.TabContent(itab).Selections = sel_uic;
        end

%%        
        function useSelection(obj,src,mobj)  
            %make use of the selection made to create a plot of selected type
            %Abstract function required by muiDataUI
            if strcmp(src.String,'Save')   %save animation to file
                saveAnimation(obj,src,mobj);
            else
                %some tabs use sub-selections of Cases and/or Variables
                %however muiDataUI already checks for subselection and adjusts
               EDB_Probe.getPlot(obj,mobj);
            end
        end 
    end

%%
%--------------------------------------------------------------------------
% Additional methods used to control selection and functionality of UI
%--------------------------------------------------------------------------            
    methods (Access=private)     
        function [DSnames,idx] = subSelectDatasets(~,src,cobj)
            %limit the variables displayed in the UI based on dataset used
            DSfields = fieldnames(cobj.Data);
            if strcmp(src.Tag,'Along Channel')
                idx = find(contains(DSfields,'AlongChannel'));
            elseif strcmp(src.Tag,'Tidal Cycle')
                idx = find(contains(DSfields,'TidalCycle'));
            elseif strcmp(src.Tag,'Summary Plots')
                idx = find(contains(DSfields,'TidalCycleEnergy'));
                if isempty(idx), idx = 1; DSnames = 'Not yet set'; return; end
            else
                idx = 1:length(DSfields);
            end
            DSnames = DSfields(idx);
        end

%--------------------------------------------------------------------------
% Additional methods used to define tab content
%--------------------------------------------------------------------------
        function setAC_tab(obj,src)
            %customise the layout of the Along Channel analysis tab
            %overload defaults defined in muiDataUI.defaultTabContent
            itab = strcmp(obj.Tabs2Use,src.Tag);
            S = obj.TabContent(itab);
            S.HeadPos = [0.86,0.1];    %header vertical position and height
            txt1 = 'For an Along-Channel plot select Case, Dataset, Variable and plot Type';
            txt2 = 'Assign to the Var button and adjust the variable range, and scaling, if required';
            txt3 = 'Use the New, Add or Delete button to create or addd/delete selection to plot';
            S.HeadText = sprintf('1 %s\n2 %s\n3 %s',txt1,txt2,txt3);  
            %Specification of uicontrol for each selection variable  
            %Use default lists except
            
            %Tab control button options
            S.TabButText = {'New','Add','Delete','Clear'}; %labels for tab button definition
            S.TabButPos = [0.1,0.14;0.3,0.14;0.5,0.14;0.7,0.14]; %default positions
            
            %XYZ panel definition (if required)
            S.XYZnset = 1;                           %minimum number of buttons to use
            S.XYZmxvar = 1;                          %maximum number of dimensions per selection
            S.XYZpanel = [0.04,0.25,0.91,0.15];      %position for XYZ button panel
            S.XYZlabels = {'Var'};                   %default button labels
            
            %Action button specifications - use defaults
       
            obj.TabContent(itab) = S;                %update object
        end

%%
function setRange_tab(obj,src)
            %customise the layout of the Tidal Cycle analysis tab
            %overload defaults defined in muiDataUI.defaultTabContent
            itab = strcmp(obj.Tabs2Use,src.Tag);
            S = obj.TabContent(itab);
            
            %Header size and text
            S.HeadPos = [0.88,0.1];    %header vertical position and height
            txt1 = 'For a Range plot, select a Case and';
            txt2 = '';
            txt3 = '';
            S.HeadText = sprintf('1 %s\n2 %s\n3 %s',txt1,txt2,txt3);
            %Specification of uicontrol for each selection variable  
            %Use default lists except for:
            %Use default lists except
            %S.Style = {'popupmenu','text','text','popupmenu'};
            S.Type = {'Range plot','Geyer-McCready plot','User'}; 

            %Tab control button options
            S.TabButText = {'Select','Clear'}; %labels for tab button definition
            S.TabButPos = [0.1,0.03;0.3,0.03]; %default positions
            
            %XYZ panel definition (if required)
            S.XYZnset = 3;                           %minimum number of buttons to use
            S.XYZmxvar = [1,1,1];                    %maximum number of dimensions per selection
                                                     %set to 0 to ignore subselection
            S.XYZpanel = [0.05,0.2,0.9,0.3];    %position for XYZ button panel
            S.XYZlabels = {'Upper','Central','Lower'};        %default button labels

            %Action button specifications - use defaults

            obj.TabContent(itab) = S;                %update object            
        end

    end
end


