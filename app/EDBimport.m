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
        Sections     %GD_Section instance with properties for Boundary, 
                     %ChannelLine, ChannelProps, SectionLines and CrossSections
        WaterBody    %shape file or xy struct polygon      
%change estuary properties and grossproperties to be stand alone properties
        TidalProps   %table of tidal levels
        RiverProps   %table of river discharges
        ClassProps   %table of estuary classification
        GrossProps   %table of estuary gross morphological properties
        Summary      %summary description of estuary
                     %Latitude and Longitude of estuary mouth
        Location = struct('Latitude',[],'Longitude',[],'Projection','')     
    end

    properties (Transient)
        formatypes   %import format file definitions
        datasetnames %reserved dataset names for each dataset type
        tablenames   %reserved table names for estuary properties
    end
    
    methods 
        function obj = EDBimport(formatfile)                
            %class constructor
            if nargin==1
                %different types of data can be added to a case. Hence the
                %format file spec is dynamic and can change with selection
                varlist = '(getFormat,var1,var2)';
                funcall = sprintf('@%s ',varlist);
                heq = str2func([funcall,[formatfile,varlist]]);
                obj = heq('getFormat',obj,formatfile);
            end
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
                if isempty(existest)                                       
                   isnew = true;                                           %no cases - must be new
                else
                    isnew =  ~any(strcmp(existest,estname));               %does not exist in catalogue
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
                    getdialog('Add Summary and Location details using Setup>Import Spatial Data options');
                else
                    %estuary exists - add data to existing record
                    classrec = find(strcmp(existest,estname)); 
                    localObj = muicat.DataSets.(classname)(classrec);
                    if isfield(localObj.Data,dstname{1}) %dataset already exists
                        dst = newdata.(dstname{1});
                        dstname = {setEDBdataset(localObj,dstname{1})}; %option to add or overwrite
                        if isempty(dstname), continue; end
                    else
                        dst = newdata.(dstname{1});                        
                    end
                    dst.Description = estname;
                    localObj.Data.(dstname{1}) = dst; 
                    updateCase(muicat,localObj,classrec,false);                
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
                        %add to an existing cases
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
        function loadArchive(muicat)
            %load class record from ASCII edb archive file
            %file is created using archiveTables - see below
            [fname,path,nfiles] = getfiles('MultiSelect','on','FileType','*.txt;',...
                                      'PromptText','Select archive file:');
            if nfiles<1, return; end

            for i=1:nfiles
                filename = [path,fname{i}];
                dstr = edb_read_archive(filename);
                %datastruct should include Header,TidalProps,RiverProps,
                %ClassProps,GrossProps,SurfaceArea,WaterBody,Width,ChannelLine,
                %SectionLines,ChannelLengths,TopoEdges,TopoNodes.
                obj = EDBimport();
                obj.DataFormats = {'EDBimport','edb_s_hyps_format','data'};
                obj.idFormat = 1;
                obj.FileSpec = {'on','*.txt; *.csv; *.xlsx;*.xls;'};
                estname = dstr.Header.Name;
                coords = split(dstr.Header.Coordinates,',');
                obj.Location.Longitude = str2double(coords{1});
                obj.Location.Latitude = str2double(coords{2});
                obj.Location.Projection = dstr.Header.Projection;
                obj.Summary = dstr.Header.Summary;
                propnames = fieldnames(dstr);
                obj = setPropertyTables(obj,dstr,propnames,estname);
                %add surface area table and linework
                if isfield(dstr,'SurfaceArea')
                    atable = dstr.SurfaceArea.DSP;
                    dspvars = table2cell(atable(:,1:5));
                    dsp = EDBimport.loadDSPproptables(dspvars,1);
                    dst = dstable(dstr.SurfaceArea.Sa,'RowNames',{estname},'DSproperties',dsp);                
                    dst.Dimensions.Z = dstr.SurfaceArea.Z;
                    dst.Description = estname;
                    obj.Data.SurfaceArea = dst;
                    obj.WaterBody.x = dstr.WaterBody.X;
                    obj.WaterBody.y = dstr.WaterBody.Y;
                end
    
                %add width table and linework
                if isfield(dstr,'Width')
                    atable = dstr.Width.DSP;
                    %load width data
                    ncol = length(dstr.Width.X); 
                    nrow = length(dstr.Width.Z);
                    width = {reshape(dstr.Width.W,1,ncol,nrow)};
                    if isfield(dstr.Width,'Wr')
                        nrec = length(dstr.Width.Wr);
                        for i=1:nrec
                            ncol = length(dstr.Width.Xr{i});
                            Wr{i} = reshape(dstr.Width.Wr{i},1,ncol,nrow);
                        end
                        width = [width,Wr]; %#ok<AGROW> 
                    else
                        nrec = 0;
                    end 
                    dspvars = table2cell(atable(:,1:5));
                    dsp = EDBimport.loadDSPproptables(dspvars,nrec+1);
                    dst = dstable(width{:},'RowNames',{estname},'DSproperties',dsp);    
                    dst.Dimensions.X = dstr.Width.X;
                    dst.Dimensions.Z = dstr.Width.Z;
                    dst.UserData.Xr = dstr.Width.Xr;
                    dst.Description = estname;
                    obj.Data.Width = dst;
                    obj.Sections = PL_Sections.getSections(obj);
                    obj.Sections.Boundary.x = dstr.Boundary.X;
                    obj.Sections.Boundary.y = dstr.Boundary.Y;
                    obj.Sections.ChannelLine.x = dstr.ChannelLine.X;
                    obj.Sections.ChannelLine.y = dstr.ChannelLine.Y;
                    obj.Sections.SectionLines.x = dstr.SectionLines.X;
                    obj.Sections.SectionLines.y = dstr.SectionLines.Y;
                    pp = dstr.ChannelProp;
                    obj.Sections.ChannelProps = struct('maxwl',pp(1),'dexp',pp(2),'cint',pp(3));
                    obj.Sections.ChannelProps.ChannelLenths = dstr.ChannelLengths;
                    %topology of network
                    edges = mergevars(dstr.TopoEdges,{'EndNodes_1','EndNodes_2'},...
                                                'NewVariableName','EndNodes');
                    nodes = dstr.TopoNodes;
                    obj.Sections.ChannelProps.Network = digraph(edges,nodes);
                end
                setDataSetRecord(obj,muicat,obj.Data,'data',{estname},false);
            end
        end

%%
        function addSummary(muicat)
            %add or edit summary text description about the estuary
            promptxt = 'Select Cases to add/edit summary:';
            %prompt to select cases and return the case record number
            [cobj,~,~] = selectCaseObj(muicat,[],{'EDBimport'},promptxt);
            if isempty(cobj), return; end

            caserec = caseRec(muicat,cobj.CaseIndex);
            casedesc = muicat.Catalogue.CaseDescription(caserec);
            if isempty(cobj.Summary), cobj.Summary = ''; end
            %summary = inputdlg({'Add/edit summary'},'Summary',1,{cobj.Summary});
            figtitle = {'Summary',sprintf('Summary description for %s',casedesc)};
            paneltxt = 'Add or edit a short descrition of the estuary. Plain text with no formatting';
            butdef = {'Save','Quit'};
            % inp = table({cobj.Summary});
            % summary = tablefigureUI(figtitle,paneltxt,inp,true,butdef);%true to edit
            [hf,hb,ht] = textfigure(figtitle,paneltxt,cobj.Summary,butdef);
            uiwait(hf)
            if any([hb(:).UserData]==1)
                summary = ht.String;
                if ~isempty(summary)
                    cobj.Summary = summary;
                end
            end
            delete(hf)
        end

%%
        function addLocation(muicat)
            %add the latitude and longitude coordinates at the mouth
            promptxt = 'Select Cases to add/edit location:';
            %prompt to select cases and return the case record number
            [cobj,~,~] = selectCaseObj(muicat,[],{'EDBimport'},promptxt);
            if isempty(cobj), return; end
            if isempty(cobj.Location.Longitude)
                defaults = {'999','999','WGS 94/OSGB36'};
            else
                defaults{1} = num2str(cobj.Location.Longitude);
                defaults{2} = num2str(cobj.Location.Latitude);
                defaults{3} = cobj.Location.Projection;
            end
            caserec = caseRec(muicat,cobj.CaseIndex);
            casedesc = muicat.Catalogue.CaseDescription(caserec);
            prompt1 = sprintf('Add co-ordinates (Lat/Long or Easting/Northing) %s\nLongitude/Easting',casedesc);
            promptxt = {prompt1,'Latitude/Northing','Coordinate Projection'};
            inp = inputdlg(promptxt,'Location',1,defaults);
            if isempty(inp), return; end
            cobj.Location.Longitude = str2double(inp{1}); 
            cobj.Location.Latitude = str2double(inp{2});             
            cobj.Location.Projection = inp{3};
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
                %and saved as GrossProps property (NOT a cobj.Data dataset)
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
        function loadEstuaryData(muicat,srctxt)
            %load tidal levels or river discharges
            answer = questdlg('Load data from Excel file or using UI?',...
                              'PropData','File','UI','File');
            if strcmp(answer,'UI')
                EDBimport.setEstuaryDataUI(muicat,srctxt);
                return;
            end

            promptxt = sprintf('Select Cases to add %s:',srctxt);
            %prompt to select cases and return the case record number
            [caserec,ok] = selectRecord(muicat,'CaseClass', {'EDBimport'},...
                           'PromptText',promptxt,...
                           'SelectionMode','multiple','ListSize', [300,200]);             
            if ~ok, return; end
            nrec = length(caserec);            
            anobj = muicat.DataSets.EDBimport(1);
            propname = anobj.tablenames{srctxt,1}{1}; 
            promptxt = sprintf('Select %s Excel Spreadsheet',srctxt);

            %now get file to load data from
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
                cobj.(propname) = dst;
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
                    msgtxt = 'No tidal level data to edit';
                case 'River Discharge'
                    msgtxt = 'No river discharge data to edit';
                case 'Classification'
                    msgtxt = 'No classification data to edit';                                    
                case 'Gross Properties'
                    msgtxt = 'No morphological properties data to edit';
            end 

            propname = cobj.tablenames{srctxt,1}{1}; 
            if isempty(cobj.(propname))
                getdialog(msgtxt);
            else
                dst = cobj.(propname); 
                cobj.(propname) = displayTable(dst);
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
            propname = cobj.tablenames{srctxt,1}{1};  
            if ~isempty(cobj.(propname))
                desc = cobj.(propname).Description;
                cobj.(propname) = [];
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
            %combine tabular data held in EstuaryProps or MorphProps into a
            %multi-estuary summary table
            anobj = EDBimport();           
            datatypes = anobj.tablenames.Properties.RowNames;
            selection = listdlg("PromptString",'Select table type:',...
                                'SelectionMode','single','ListSize',[160,100],...
                                'ListString',datatypes);
            if isempty(selection), return; end
            propname = anobj.tablenames{selection,1}{1};  
            clear anobj


            allobj = getClassObj(mobj,'Cases','EDBimport');

            [fname,path,nfiles] = getfiles('FileType','*.mat;','MultiSelect','on',...
                                      'PromptText','Select files to query');
            if nfiles>0
                for i=1:nfiles
                    S = load([path,fname{i}],'-mat');
                    addobj = S.sobj.Cases.DataSets.EDBimport;
                    allobj = [allobj,addobj]; %#ok<AGROW> 
                end
            end
            clear S

            ij = 1;
            for ii=1:length(allobj)
                if ~isempty(allobj(ii).(propname)) 
                    estnames{ij} = allobj(ii).(propname).Description; %#ok<AGROW> 
                    ij = ij+1;
                end
            end
            selection = listdlg("PromptString",'Select table type:',...
                                'SelectionMode','multiple','ListSize',[160,100],...
                                'ListString',estnames);
            if isempty(selection), return; end

            cobj = allobj(selection);

            proptable = [];
            if ~isempty(cobj)
                for j=1:length(cobj)
                    newtable = cobj(j).(propname);
                    if strcmp(propname,'GrossProps')
                        newtable = selectRow(newtable); %subselect single row
                    end
                    %
                    if ~isempty(newtable) && isempty(proptable)
                        proptable = newtable;
                    else                        
                        proptable = [proptable;newtable]; %#ok<AGROW> 
                    end
                end
            end
            
            obj = muiTableImport;
            setDataSetRecord(obj,mobj.Cases,proptable,'data'); 

            %nested function ----------------------------------------------
            function newtable = selectRow(newtable)
                if height(newtable)==1, return; end %single row in table
                 newtable = activatedynamicprops(newtable);  
                 for k=1:height(newtable)
                    listxt{k} = sprintf('%s: %s',newtable.DataTable.Source{k},newtable.Notes{k}); %#ok<AGROW> 
                 end
                iselect = listdlg("PromptString",'Select row to use:',...
                                'SelectionMode','single','ListSize',[180,100],...
                                'ListString',listxt');
                if isempty(iselect), iselect = 1; end
                newtable = getDSTable(newtable,iselect,[]);
                newtable.RowNames = {newtable.Description};
            end
            % -------------------------------------------------------------
        end

%%
        function archiveTables(mobj)
            %save an estuary Case to a an ASCII file (import using
            %loadArchive - see above)
            promptxt = 'Select Cases to archive';
            [caserecs,ok] = selectRecord(mobj.Cases,'PromptText',promptxt,...
                                'SelectionMode','multiple','CaseClass',...
                                {'EDBimport'},'ListSize', [180,120]);
            if ok<1, return; end
            cobj = getCases(mobj.Cases,caserecs);
            %[cobj,~,~] = selectCaseObj(mobj.Cases,[],{'EDBimport'},promptxt);
            %if isempty(cobj), return; end
            vN = getVersion(mobj);
            date = mobj.Info.ProjectDate;
            if isempty(date), date = cellstr(datetime('now'),'dd-MM-yyyy'); end
            %prompt for creator name and affiliation
            promptxt = {'Author/Creator','Affiliation'};
            auth = inputdlg(promptxt,'Archive',1);
            if isempty(auth), auth = {'',''}; end
            %wrtie each of selected cases to an archive file
            for i=1:length(cobj)
                edb_write_archive(cobj(i),vN,date,auth);
            end
        end

%%
        function setEstuaryDataUI(muicat,srctxt)
            promptxt = sprintf('Select Case to add %s:',srctxt);
            %prompt to select cases and return the case record number
            [caserec,ok] = selectRecord(muicat,'CaseClass', {'EDBimport'},...
                           'PromptText',promptxt,...
                           'SelectionMode','single','ListSize', [300,200]);             
            if ~ok, return; end
            [cobj,classrec] = getCase(muicat,caserec);
            casedesc = muicat.Catalogue.CaseDescription(caserec);
            dsp = EDBimport.getDSPvariables(srctxt);
            propdesc = {dsp.Variables(:).Description};
            inp = inputdlg(propdesc,'PropData',1);
            if isempty(inp), return; end
            vars = EDBimport.converCharNum(inp);
            dst = dstable(vars{:},'DSproperties',dsp);
            dst.Description = casedesc;
            dst.Source = 'User input';
            dst.MetaData = srctxt;
            propname = cobj.tablenames{srctxt,1}{1}; 
            cobj.(propname) = dst;
            %write new table to Case instance
            updateCase(muicat,cobj,classrec,false);  
        end

%%
        function vars = converCharNum(strtxt)
            %convert character strings of numbers to numeric and leave text unchanged
            vars = cellfun(@(x) ifelse(isnan(str2double(x)),{x},str2double(x)),...
                                   strtxt,'UniformOutput',false);
            %nested function ----------------------------------------------
            function result = ifelse(condition, trueResult, falseResult)
                % Helper function for inline if-else
                if condition
                    result = trueResult;
                else
                    result = falseResult;
                end
            end
            %-------------------------------------------------------------- 
        end
%%
        function dsp = getDSPvariables(srctxt)
            switch srctxt
                case 'Tidal Levels'
                    vars = {...
                        'HAT','Highest astronomical tide','mAD','Tide level (mAD)','data';...
                        'MHHW','Mean high high water','mAD','Tide level (mAD)','data';...
                        'MHW','Mean high water','mAD','Tide level (mAD)','data';...
                        'MLHW','Mean low high water','mAD','Tide level (mAD)','data';...
                        'MTL','Mean tide level','mAD','Tide level (mAD)','data';...
                        'MHLW','Mean high low water','mAD','Tide level (mAD)','data';...
                        'MLW','Mean low water','mAD','Tide level (mAD)','data';...
                        'MLLW','Mean low low water','mAD','Tide level (mAD)','data';...
                        'LAT','Lowest astronomical tide','mAD','Tide level (mAD)','data'};
                case 'River Discharge'
                    vars = {...
                        'Qf_annual_high','Annual high river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_annual_mean','Annual mean river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_annual_low','Annual low river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_spring_high','Spring high river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_spring_mean','Spring mean river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_spring_low','Spring low river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_summer_high','Summer high river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_summer_mean','Summer mean river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_summer_low','Summer low river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_autumn_high','Autumnhigh river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_autumn_mean','Autumn mean river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_autumn_low','Autumn low river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_winter_high','Winter high river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_winter_mean','Winter mean river discharge','m^3/s','River discharge (m^3/s)','data';...
                        'Qf_winter_low','Winter low river discharge','m^3/s','River discharge (m^3/s)','data'};
                case 'Classification'
                    vars = {...
                        'Country','Country','-','Country','data';...
                        'id','Index','-','Index','data';...
                        'EstuaryType','Estuary classification','-','Estuary/Inlet type','data';...
                        'TidalType','Tidal Type','-','Tidal type','data';...
                        'GeomorType','Geomorphic classification','-','Estuary/Inlet type','data'};
            end
            Variables = struct('Name',vars(:,1)','Description',vars(:,2)',...
                       'Unit',vars(:,3)','Label',vars(:,4)',...
                       'QCflag',vars(:,5)');
            dsp = EDBimport.loadDSproperties(Variables);
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

%%
function dsp = loadDSPproptables(dspvars,nr)
            %add the variable dimension properties for width or surface area
            dsp = struct('Variables',[],'Row',[],'Dimensions',[]); 
            dsp.Variables = struct(...
                'Name',dspvars(1:nr,1),...
                'Description',dspvars(1:nr,2),...
                'Unit',dspvars(1:nr,3),...
                'Label',dspvars(1:nr,4),...
                'QCflag',dspvars(1:nr,5));
            dsp.Row = struct(...
                'Name',{'Location'},...
                'Description',{'Estuary'},...
                'Unit',{'-'},...
                'Label',{'Estuary'},...
                'Format',{''});   
            dsp.Dimensions = struct(...
                'Name',dspvars(nr+1:end,1),...
                'Description',dspvars(nr+1:end,2),...
                'Unit',dspvars(nr+1:end,3),...
                'Label',dspvars(nr+1:end,4),...
                'Format',dspvars(nr+1:end,5));
        end
    end
%--------------------------------------------------------------------------
% Class get functions and superclass required functions
%--------------------------------------------------------------------------
    methods   
        function fmt = get.formatypes(obj) %#ok<MANU> 
            %create look-up table for file formats from dataset names
            dsetnames = {'Grid','SurfaceArea','Width','Image','GeoImage','ZMdata'};
            files = {'edb_bathy_format';'edb_s_hyps_format';...
                     'edb_w_hyps_format';'edb_image_format';...
                     'gd_geoimage_format';'edb_zm_data_format'};
            fmt = table(files,'RowNames',dsetnames);
        end

%%
        function dsname = get.datasetnames(obj) %#ok<MANU> 
            %create look-up table for dataset names from call text
            calltxt = {'Grid','Surface area','Width','Image',...
                                   'Gross Properties','GeoImage','ZMdata'};
            dsetnames = {'Grid';'SurfaceArea';'Width';'Image';...
                                         'Properties';'GeoImage';'ZMdata'};            
            dsname = table(dsetnames,'RowNames',calltxt);
        end

%%
        function tablename = get.tablenames(obj) %#ok<MANU> 
            %create look-up table for dataset names from call text
            calltxt = {'Tidal Levels','River Discharge','Classification','Gross Properties'};
            dsetnames = {'TidalProps';'RiverProps';'ClassProps';'GrossProps'};
            tabnames = {'Tides';'Rivers';'Classification';'Morphology'};
            tablename = table(dsetnames,tabnames,'RowNames',calltxt);
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
            if isempty(dst), return; end

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
            %select between Datasets and other data sets
            ht = findobj(src,'-not','Type','uitab'); %clear any existing content
            delete(ht)
            dst = [];
            idr = strcmp(obj.tablenames{:,2},src.Tag);
            propname = obj.tablenames{idr,1}{1};  
            if ~isempty(obj.(propname))
                dst = obj.(propname);
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

%%
        function tabSummary(obj,mobj,src)
            %display summary description of estuary on a tab
            ht = findobj(src,'-not','Type','uitab'); %clear any existing content
            delete(ht)
            caserec = caseRec(mobj.Cases,obj.CaseIndex);
            titletxt = mobj.Cases.Catalogue.CaseDescription(caserec);
            if isempty(obj.Location.Latitude)
                titletxt = sprintf('Case: %s',titletxt); 
            else
                lat = obj.Location.Latitude; long = obj.Location.Longitude;
                titletxt = sprintf('Case: %s (%d, %d)',titletxt,long,lat);              
            end

            uicontrol('Parent',src,'Style','text',...
                'Units','normalized','Position',[0.1,0.95,0.8,0.04],...
                'String',titletxt,'FontSize',10,...
                'HorizontalAlignment','center','Tag','titletxt');

            h_pan = uipanel('Parent',src,'Units','normalized',...
                                  'Position',[0.02,0.02,0.95,0.90]); 

            uicontrol('Parent',h_pan,'Style','text',...
                'String',obj.Summary,'FontSize',9,...
                'Units','normalized','Position',[0,0,1,1],...
                'HorizontalAlignment','left','Max',2);
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
        function obj = setPropertyTables(obj,dstr,propnames,estname)
            %add the archived property tables to a class instance
            % dstr - stuct read from archive file
            % propnames - cell array of table property names
            % estname - estuary name (Case) 
            idf = find(contains(propnames,'Props'));
            for i = 1:length(idf)
                atable = dstr.(propnames{idf(i)});
                dspvars = table2struct(atable(:,1:5));
                dsp = EDBimport.loadDSproperties(dspvars);
                %convert character strings of numbers to numeric and leave text unchanged 
                vars = EDBimport.converCharNum(atable{:,6}');
                obj.(propnames{idf(i)}) = dstable(vars{:},'DSproperties',dsp);
                obj.(propnames{idf(i)}).Description = estname;
                if strcmp(propnames{idf(i)},'GrossProps')
                    nrow = 1;
                    obj.(propnames{idf(i)}).RowNames = nrow;
                else
                    obj.(propnames{idf(i)}).RowNames = {estname};
                end
                    
                if width(atable)>6
                    for j=7:width(atable)
                        nrow = nrow+1;
                        rowvars = EDBimport.converCharNum(atable{:,j}');
                        obj.(propnames{idf(i)}) = addrows(obj.(propnames{idf(i)}),nrow,rowvars{:});
                    end
                end               
            end
                       
        end

%%
        function datasetname = setEDBdataset(obj,type)
            %set the name of a dataset to be added to a Case
            % type - core name: Grid, Width, SurfaceArea, Image, GeoImage
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