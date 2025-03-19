classdef EDBimport < GD_ImportData                  
%
%-------class help---------------------------------------------------------
% NAME
%   EDBimport.m
% PURPOSE
%   Class to import a 
% USAGE
%   obj = EDBimport.loadData(muicat)
% NOTES
%   Flat tables (eg for gross properties of estuaries) are loaded using the
%   muiTableImport class. This class handles other formats such as alongchannel
%   vector data. the import format and DSproperties for each dataset type
%   are defined in a formatfile. Each estuary is held as a location "case" 
%   as used for profiles in CoastalTools. Multiple tables can be added
%   to a location for vector data, bathymetry, images, etc.
% SEE ALSO
%   uses dstable and dscatalogue and inherits muiDataSet 
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2024
%--------------------------------------------------------------------------
%    
    properties  
        %inherits Data, RunParam, MetaData and CaseIndex from muiDataSet        
        Sections   %GD_Section instance with properties for Boundary, 
                   %ChannelLine, ChannelProps, SectionLines and CrossSections
        WaterBody  %shape file or xy struct polygon      
        HydroProps
        EstuaryProps %struct for TidalLevels, RiverDischarges and Classification
        MorphProps %table for morphological gross properties derived from
                   %surface area or width hypsometry (row for each)
    end

    properties (Transient)
        formatypes
        datasetnames
    end
    
    methods 
        function obj = EDBimport(formatfile)                
            %class constructor
            if nargin<1
                formatfile = obj.setFileFormat;
                if isempty(formatfile), return; end
            end
            %different types of data can be added to a case. Hence the
            %format file spec is dynamic and can change with selection
            varlist = '(getFormat,var1,var2)';
            funcall = sprintf('@%s ',varlist);
            heq = str2func([funcall,[formatfile,varlist]]);
            obj = heq('getFormat',obj,formatfile);
        end
    end

%%
%--------------------------------------------------------------------------
%   functions to read data from file and load as a dstable
%   data formats are defined in the format files
%--------------------------------------------------------------------------
    methods  (Static)
        function obj = loadData(muicat)
            %load user data set from one or more files
            % mobj - handle to modelui instance 
            listxt = {'Bathymetry','Surface area','Width','Image','GeoImage'};
            selection = listdlg('PromptString','Select data type to import:',...
                'ListString',listxt,'ListSize',[140,100],'SelectionMode','single');
            if isempty(selection), return; end

            switch selection
                case 1 %bathymetry
                    formatfile = 'edb_bathy_format';
                case 2 %surface area
                    formatfile = 'edb_s_hyps_format';
                case 3 %width
                    formatfile = 'edb_w_hyps_format';                
                case 4 %image
                    formatfile = 'edb_image_format';
                case 5 %geoimage
                    formatfile = 'gd_geoimage_format';
            end

            obj = EDBimport(formatfile);   
            if isempty(obj.DataFormats), return; end
            classname = metaclass(obj).Name; 
            
            [fname,path,nfiles] = getfiles('MultiSelect',obj.FileSpec{1},...
                'FileType',obj.FileSpec{2},'PromptText','Select data file(s):');
            if isnumeric(fname) && fname==0
                return;            %user cancelled
            elseif ~iscell(fname)
                fname = {fname};   %single select returns char
            end
         
            %assume metatxt description of data source applies to all files
            promptxt = {'Provide description of the data source          >'};
            metatxt = inputdlg(promptxt,'EDBimport',1);
            waitfor(metatxt)
            funcname = 'getData';
            hw = waitbar(0, 'Loading data. Please wait');  

            %load file and create master collection which can
            %have multiple estuaries (ie locations)            
            for jf=1:nfiles
                filename = [path fname{jf}];
                [newdata,ok] = callFileFormatFcn(obj,funcname,obj,filename,metatxt{1});
                if ok<1 || isempty(newdata), continue; end
                dstname = fieldnames(newdata);
                estname = newdata.(dstname{1}).Description;
                idx = strcmp(muicat.Catalogue.CaseClass,classname);        %index for existing class records
                existest = muicat.Catalogue.CaseDescription(idx);          %Case names
                isnew = isempty(existest);                                 %no cases - must be new
                if ~isnew                
                    isnew =  all(~strcmp(existest,estname));               %does not exist in catalogue
                    %check where user wants to save new data
                    [isnew,estname] = estuaryName(dstname{1},estname,existest,isnew);
                end
                                    
                %if the estuary does not exist save as new record                    
                if isnew
                    %add estuary as a new case record
                    %classobj,muicat,dataset,casetype,casedesc,SupressPrompts
                    dtype = obj.DataFormats{3};
                    setDataSetRecord(obj,muicat,newdata,dtype,{estname},false); %false-force prompt for case description
                    obj = EDBimport(obj.DataFormats{2}); %initialise next instance
                else
                    %estuary exists - add data to existing record
                    classrec = find(strcmp(existest,estname)); 
                    localObj = muicat.DataSets.(classname)(classrec);
                    if isfield(localObj.Data,dstname{1})
                        dst = newdata.(dstname{1});
                        dstname = {setEDBdataset(localObj,dstname{1})};
                        if ~isempty(dstname)
                            localObj.Data.(dstname{1}) = dst; 
                            updateCase(muicat,localObj,classrec,false);
                        end
                    end
                end  
               
                clear existest newdata estname dstname isnew
                waitbar(jf/nfiles)
            end
            close(hw);

            if nfiles>1
                getdialog(sprintf('Data loaded in class: %s',classname)); 
            end
            %nested functions----------------------------------------------
            function [isnew,estname] = estuaryName(dstname,estname,existest,isnew)
                %check whether any
                prmptxt = sprintf('%s from %s\nLoad as a New case of Add to existing case?',...
                                                          dstname,estname);
                answr = questdlg(prmptxt,'Load','New','Add','New');
                if strcmp(answr,'New')
                    isnew = true;
                else
                    if isnew
                        %select case from existing cases
                        idc = selectEstuaryCase(existest,dstname);
                        if isempty(idc), return; end %returns isnew as true and estname unchanged
                    else
                        prmptxt = sprintf('Add to %s case',estname);
                        answr = questdlg(prmptxt,'Load','Yes','No','Yes');
                        if strcmp(answr,'Yes')
                            idc = strcmp(existest,estname);
                        else
                            %select case from existing cases
                            idc = selectEstuaryCase(existest,dstname);
                            if isempty(idc), return; end %returns isnew as true and estname unchanged
                        end
                    end
                    estname = existest{idc};
                    isnew = false;
                end
            end
            %--------------------------------------------------------------
            function select = selectEstuaryCase(existest,dstname)
                prmptxt = sprintf('Select the case to add %s',dstname);
                select = listdlg('Name','Case Name','ListString',existest,...
                                 'PromptString',prmptxt,'ListSize',[160,200],...
                                 'OKstring','Select','CancelString','New Case',...
                                 'SelectionMode','single'); 
            end
            %--------------------------------------------------------------
        end
%%
        function loadTable(muicat,newdataset)
            %use bathymetry to create a SurfaceArea or Width table
            if strcmp(newdataset,'Gross Properties')
                promptxt = 'Select case with surface area or width hypsometry';
            else
                promptxt = 'Select case with bathymetry';
            end
            [cobj,classrec] = selectCaseObj(muicat,{'data'},{'EDBimport'},promptxt);
            if isempty(cobj), return; end

            dset2add = cobj.datasetnames{newdataset,1}{1};            
            %create new table and add to case object
            if strcmp(dset2add,'SurfaceArea')
                [cobj,isok] = edb_surfacearea_table(cobj);
            elseif strcmp(dset2add,'Width')
                [cobj,isok] = edb_width_table(cobj);
            elseif strcmp(dset2add,'Properties')
                %output derived from SurfaceArea and Width Data sets
                %and saved as MorphProps property (NOT a cobj.Data dataset)
                [cobj,isok] = edb_grossprops_table(cobj);
            else
                errdlg('Should not be here'); return;
            end

            %write new table to Case record
            if isok
               updateCase(muicat,cobj,classrec,true);
            end
        end

%%
        function loadHydroData(muicat,srctxt)
            %load tidal levels or river discharges
            promptxt = sprintf('Select Cases to add %s:',srctxt);
            %prompt to select cases and return the case record number
            [caserec,ok] = selectRecord(muicat,'CaseClass', {'EDBimport'},...
                           'PromptText',promptxt,...
                           'SelectionMode','multiple','ListSize', [300,200]);             
            if ~ok, return; end
            nrec = length(caserec);

            if strcmp(srctxt,'Tidal Levels')
                promptxt = 'Select Water Levels Excel Spreadsheet';
                propname = 'TidalLevels';
            elseif strcmp(srctxt,'River Discharge')
                promptxt = 'Select River Discharges Excel Spreadsheet';
                propname = 'RiverDischarges';
            else
                promptxt = 'Select Classification Excel Spreadsheet';
                propname = 'Classification';               
            end
            [fname,path,nfiles] = getfiles('FileType','*.xlsx','PromptText',promptxt);
            if nfiles<1, return; end
        
            %load data from an Excel spreadsheet
            datatable = readspreadsheet([path,fname],false); %return a table

            [fname,path,nfiles] = getfiles('FileType','*.xlsx',...
                                      'PromptText','Select DSP Excel file');                            
            if nfiles<1, return; end

            %load data from an Excel spreadsheet
            cell_ids = {'A1';'A2';''};
            vartable = readspreadsheet([path,fname],false,cell_ids); %return a table
            dspvars = table2struct(vartable);
            dsp = EDBimport.loadDSproperties(dspvars);
            dsp = dsproperties(dsp,'test');
            if ~isempty(dsp.errmsg), return; end
            
            count = 0;
            for i=1:nrec
                [cobj,classrec] = getCase(muicat,caserec(i));
                casedesc = muicat.Catalogue.CaseDescription(caserec(i));
                estnames = datatable.Properties.RowNames;
                idr = strcmp(estnames,casedesc);
                if all(~idr)
                    promptxt = {sprintf('Case %s not found',casedesc),...
                              sprintf('Select a %s station to use',srctxt)};
                    idr = listdlg("PromptString",promptxt,...
                                  "Name",'Import','SelectionMode','single',...
                                  'ListSize',[180,120],'ListString',estnames);
                    if isempty(idr), continue; end
                end
                count = count+1;
                dst = dstable(datatable(idr,:),'RowNames',estnames(idr),'DSproperties',dsp);
                dst.Source = fname;
                dst.MetaData = srctxt;
                dst.Description = casedesc;
                cobj.EstuaryProps.(propname) = dst;
                %write new table to Case instance
                updateCase(muicat,cobj,classrec,false);
            end
            getdialog(sprintf('Updated %s for %d cases',srctxt,count))
        end

%%
        function editTable(muicat,srctxt)
            %edit Estuary Properties Tables (Tides, Discharge, or Gross Properties)
            promptxt = sprintf('Select Cases to delete rows from  %s table:',srctxt);
            %prompt to select cases and return the case record number
            [cobj,~] = selectCaseObj(muicat,[],{'EDBimport'},promptxt);
            if isempty(cobj), return; end

            switch srctxt
                case 'Tidal Levels'
                    if isempty(cobj.EstuaryProps) || ...
                            ~isfield(cobj.EstuaryProps,'TidalLevels') || ...
                                    isempty(cobj.EstuaryProps.TidalLevels)
                        getdialog('No tidal level data to edit');
                    elseif ~isempty(cobj.EstuaryProps.TidalLevels)
                        dst = cobj.EstuaryProps.TidalLevels; 
                        cobj.EstuaryProps.TidalLevels = displayTable(dst);
                    end
                case 'River Discharge'
                    if  isempty(cobj.EstuaryProps)|| ...
                            ~isfield(cobj.EstuaryProps,'RiverDischarges') ||...
                                 isempty(cobj.EstuaryProps.RiverDischarges)
                        getdialog('No river discharge data to edit');
                    elseif ~isempty(cobj.EstuaryProps.RiverDischarges)
                        dst = cobj.EstuaryProps.RiverDischarges; 
                        cobj.EstuaryProps.RiverDischarges = displayTable(dst);
                    end
                case 'Gross Properties'
                    if isempty(cobj.MorphProps)
                        getdialog('No morphological properties data to edit');
                    else
                        dst = cobj.MorphProps; 
                        cobj.MorphProps = displayTable(dst);
                    end
            end  

            % Nested function----------------------------------------------
            function output = displayTable(dst)
                figtitle = {'Edit table',sprintf('Case: %s',dst.Description)};
                paneltxt = 'Use button to add rows and columns. Use left mouse click to edit cells. Use right mouse click to delete rows or columns';
                butdef.Text = {'Add','Save','Cancel'};
                output = tablefigureUI(figtitle,paneltxt,dst,true,butdef);
                if isempty(output), output = dst; end
            end
            %--------------------------------------------------------------
        end

%%
        function deleteTable(muicat,srctxt)
            %delete an Estuary Properties Table (Tides, Discharge, or Gross Properties)
            promptxt = sprintf('Select Cases to delete rows from  %s table:',srctxt);
            %prompt to select cases and return the case record number
            [cobj,~,catrec] = selectCaseObj(muicat,[],{'EDBimport'},promptxt);
            if isempty(cobj), return; end
            
            desc = [];
            switch srctxt
                case 'Tidal Levels'
                    if ~isempty(cobj.EstuaryProps.TidalLevels)
                        desc = cobj.EstuaryProps.TidalLevels.Description;
                        cobj.EstuaryProps.TidalLevels = [];                        
                    end
                case 'River Discharge'
                    if ~isempty(cobj.EstuaryProps.RiverDischarges)
                        desc = cobj.EstuaryProps.RiverDischarges.Description;
                        cobj.EstuaryProps.RiverDischarges = [];
                    end
                case 'Gross Properties'
                    if ~isempty(cobj.MorphProps)
                        desc = cobj.MorphProps.Description;
                        cobj.MorphProps = [];
                    end
            end 
            %notify user of any changes
            if isempty(desc)
                desc =catrec.CaseDescription;
                getdialog(sprintf('No %s data to delete for %s',srctxt,desc))
            else
                getdialog(sprintf('Deleted %s for %s',srctxt,desc))
            end
        end

%%
        function combineTables(mobj)
            getdialog('Not yet implemented')
        end
        
%%
        function dsp = loadDSproperties(dspvars)
            %define a dsproperties struct and add the metadata
            dsp = struct('Variables',[],'Row',[],'Dimensions',[]); 
            dsp.Variables = dspvars;
            dsp.Row = struct(...
                'Name',{'Location'},...
                'Description',{'Estuary'},...
                'Unit',{'-'},...
                'Label',{'Estuary'},...
                'Format',{''});       
            dsp.Dimensions = struct(...    
                'Name',{''},...
                'Description',{''},...
                'Unit',{''},...
                'Label',{''},...
                'Format',{''});   
        end
    end
%--------------------------------------------------------------------------
% Class get functions and superclass required functions
%--------------------------------------------------------------------------
    methods   
        function fmt = get.formatypes(obj) %#ok<MANU> 
            %create look-up table for file formats from dataset names
            dsetnames = {'Grid','SurfaceArea','Width','Image','GeoImage'};
            files = {'edb_bathy_format';'edb_s_hyps_format';...
                     'edb_w_hyps_format';'edb_image_format';...
                     'gd_geoimage_format'};
            fmt = table(files,'RowNames',dsetnames);
        end

%%
        function dsname = get.datasetnames(obj) %#ok<MANU> 
            %create look-up table for dataset names from call text
            calltxt = {'Grid','Surface area','Width','Image','Gross Properties','GeoImage'};
            dsetnames = {'Grid';'SurfaceArea';'Width';'Image';'Properties';'GeoImage'};            
            dsname = table(dsetnames,'RowNames',calltxt);
        end

%%
        function tabPlot(obj,src)
            %generate plot for display on Q-Plot tab
            funcname = 'getPlot';
            datasetname = getDataSetName(obj);
            if isempty(datasetname), return; end

            if strcmp(datasetname,'Sections')
                viewSections(obj.Sections,obj,src);
            end
            %format file to call depends on the data type. dynamically
            %update the DataFormat to the user dataset selection
            try
                obj.DataFormats{2} = obj.formatypes{datasetname,1}{1};
            catch
                sourcename = extractBefore(datasetname,digitsPattern);
                obj.DataFormats{2} = obj.formatypes{sourcename,1}{1};
            end

            [var,ok] = callFileFormatFcn(obj,funcname,obj,src,datasetname);
            if ok<1, return; end
            
            if var==0  %no plot defined so use muiDataSet default plot
                tabDefaultPlot(obj,src);
            end
        end

%%
        function tabTable(obj,src)
            %generate table for display on Table tab
            ht = findobj(src,'-not','Type','uitab'); %clear any existing content
            delete(ht)
            datasetname = getDataSetName(obj);
            if isempty(datasetname), return; end
            dst = obj.Data.(datasetname);

            if strcmp(datasetname,'Width')
                varnames = dst.VariableDescriptions;
                idx = listdlg('PromptString','Select a variable:',...
                                  'SelectionMode','single','ListSize',[160,200],...
                                  'Name','TableFigure','ListString',varnames);
                if isempty(idx)
                    return; 
                elseif idx==1
                    dst = getDSTable(dst,1,idx,{[],[]});
                else
                    %use indices to extract new dstable
                    Xr = dst.UserData.Xr{idx-1};
                    dst = getDSTable(dst,1,idx,{1:length(Xr),[]});
                    dst.Dimensions.X = Xr;
                end
            end                                                                                                                    
            
            %check that data is not too large to display
            if numel(dst.DataTable{1,1})<2e5
                %generate table
                table_figure(dst,src,true); %funtion in dstable, true to format
            else
                warndlg('Dataset too large to display as a table')
            end            
        end
        
%%
        function tabTablesection(obj,src)
            %select between HydroData and other data sets
            ht = findobj(src,'-not','Type','uitab'); %clear any existing content
            delete(ht)
            dst = [];
            if strcmp(src.Tag,'Dataset')
                tabTable(obj,src);
            else
                switch src.Tag
                    case 'Tides'
                        if isfield(obj.EstuaryProps,'TidalLevels')
                            dst = obj.EstuaryProps.TidalLevels;
                        end
                    case 'Rivers'
                        if isfield(obj.EstuaryProps,'RiverDischarges')
                            dst = obj.EstuaryProps.RiverDischarges;
                        end
                    case 'Classification'
                        if isfield(obj.EstuaryProps,'Classification')
                            dst = obj.EstuaryProps.Classification;
                        end                    
                    case 'Morphology'
                        if ~isempty(obj.MorphProps)
                            dst = obj.MorphProps;
                        end 
                end
                if isempty(dst), getdialog('No data',[],1); return; end

                desc = sprintf('Source: %s\nMeta-data: %s',dst.Source,dst.MetaData);
                titletxt = dst.Description;
                dst.UserData.isFormat = true;
                [ht,hp] = tablefigure(src,desc,dst); %ht-tab; hp-panel; htable-table
                ht.Units = 'normalized'; hp.Units = 'normalized'; 
                htxt = findobj(ht,'Tag','statictextbox');
                htxt.Units = 'normalized';
                uicontrol('Parent',ht,'Style','text',...
                    'Units','normalized','Position',[0.1,0.97,0.8,0.035],...
                    'String',['Case: ',titletxt],'FontSize',10,...
                    'HorizontalAlignment','center','Tag','titletxt');
            end
        end

%%
        function delDataset(obj,classrec,~,muicat)
            %delete a dataset
            dst = obj.Data;
            fnames = fieldnames(dst);
            msgtxt = 'To delete the Case use: Project > Cases > Delete Case';
            if isscalar(fnames)
                %if only one dataset, need to delete Case
                msgtxt = sprintf('There is only one dataset in this Case\n%s',msgtxt);
                warndlg(msgtxt); return
            else
                promptxt = 'Select which datasets to delete:';
                datasets = getDataSetName(obj,promptxt,'multiple'); %prompts user to select dataset if more than one
                if ischar(datasets), datasets = {datasets}; end

                if length(fnames)==length(datasets)
                    %if all datasets selected, need to delete Case
                     msgtxt = sprintf('Cannot delete all the datasets in a Case\n%s',msgtxt);
                    warndlg(msgtxt); return
                end
                %get user to confirm selection
                for i=1:length(datasets)    
                    checktxt = sprintf('Deleting the following dataset: %s',datasets{i});
                    answer = questdlg(checktxt,'Delete','Delete','Skip','Skip');
                    if strcmp(answer,'Skip'), continue; end
                    dst = rmfield(dst,datasets{i});    %delete selected dstable
                end
            end

            obj.Data = dst;
            updateCase(muicat,obj,classrec);
        end

%%
        function datasetname = setEDBdataset(obj,type)
            %set the name of a dataset to be added to a Case
            dsetnames = fieldnames(obj.Data);
            %check whether existing table is to be overwritten or a new table created
            isdset = any(ismatch(dsetnames,type));
            if isdset
                promptxt = sprintf('Overwrite existing %s or Add new %s table?',type,type);
                answer = questdlg(promptxt,'EDB table','Overwrite','Add','Quit','Add');                                  
                if strcmp(answer,'Quit')
                    datasetname = []; return;
                elseif strcmp(answer,'Add')
                    nrec = sum(contains(dsetnames,type))+1;
                    datasetname = sprintf('%s%d',type,nrec);
                else
                    datasetname = type;
                end
            else
                datasetname = type;
            end            
        end

%%
        function datasetname = getEDBdataset(obj,type)
            %get the name of a dataset to be retrieved from a Case
            if nargin<2
                type = [];
            end
            dsetnames = fieldnames(obj.Data);
            if ~isempty(type)
                idx = contains(dsetnames,type);
                dsetnames = dsetnames(idx);
            end
            %select a specific dataset
           selection = listdlg('PromptString','Select dataset:',...
                'ListString',dsetnames,'ListSize',[140,100],'SelectionMode','single');
           if isempty(selection)
               datasetname = [];
           else            
               datasetname = dsetnames{selection};
           end
        end

%%
        function [dst,idv,props] = selectVariable(obj,datasetname,subset)
            %select variable to use for plot/analysis
            % subset - sub-selection of variables (optional)
            % dst - dstable for selected data set
            % idv - index of selected variable in dstable
            % props - as used in get_selection_text (based on getProperty)
            %called in getPlot in the format files for EDBimport data types
            dst = obj.Data.(datasetname);
            %--------------------------------------------------------------
            if nargin<3
                vardesc = dst.VariableDescriptions;
            else
                vardesc = dst.VariableDescriptions(subset);
            end
            if length(vardesc)>1
                idv = listdlg('PromptString','Select variable:',...
                          'SelectionMode','single','ListString',vardesc); 
                if isempty(idv), props = []; return; end
            else
                idv = 1;
            end
            props.case = dst.Description;
            props.dset = datasetname;
            props.desc = vardesc{idv};
        end  
    end
end