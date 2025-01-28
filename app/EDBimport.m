classdef EDBimport < GDinterface                   
%
%-------class help---------------------------------------------------------
% NAME
%   EDBimport.m
% PURPOSE
%   Class to import a spreadsheet table, ascii data or Matlab table, adding 
%   the results to dstable and a record in a dscatlogue (as a property 
%   of muiCatalogue)
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
            listxt = {'Surface area','Width','Bathymetry','Image'};
            selection = listdlg('PromptString','Select data type to import:',...
                'ListString',listxt,'ListSize',[140,100],'SelectionMode','single');
            if isempty(selection), return; end

            switch selection
                case 1 %surface area
                    formatfile = 'edb_s_hyps_format';
                case 2 %width
                    formatfile = 'edb_w_hyps_format';
                case 3 %bathymetry
                    formatfile = 'edb_bathy_format';
                case 4 %image
                    formatfile = 'edb_image_format';
            end

            obj = EDBimport(formatfile);   
            if isempty(obj.DataFormats), return; end
            classname = metaclass(obj).Name; 
            
            [fname,path,nfiles] = getfiles('MultiSelect',obj.FileSpec{1},...
                'FileType',obj.FileSpec{2},'PromptText','Select file(s):');
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
                idx = strcmp(muicat.Catalogue.CaseClass,classname);
                existest = muicat.Catalogue.CaseDescription(idx);
                %if the estuary does not exist save as new record                    
                if isempty(existest) || ...
                                    all(~strcmp(existest,estname))
                    %add estuary as a new case record
                    %classobj,muicat,dataset,casetype,casedesc,SupressPrompts
                    dtype = obj.DataFormats{3};
                    setDataSetRecord(obj,muicat,newdata,dtype,{estname},true); 
                    obj = EDBimport(obj.DataFormats{2}); %initialise next instance
                else
                    %estuary exists - add data to existing record
                    classrec = find(strcmp(existest,estname)); 
                    localObj = muicat.DataSets.(classname)(classrec);
                    if isfield(localObj.Data,dstname{1})
                        answer = questdlg(sprintf('%s dataset already exists, Overwrite?',dstname{1}),...
                                                   'Overwrite','Yes','No','Yes');
                        if strcmp(answer,'No')
                            obj = []; close(hw); return; 
                        end
                    end
                    localObj.Data.(dstname{1}) = newdata.(dstname{1}); 
                    updateCase(muicat,localObj,classrec,false);
                end  
               
                clear existest newdata estname dstname
                waitbar(jf/nfiles)
            end
            close(hw);

            if nfiles>1
                getdialog(sprintf('Data loaded in class: %s',classname)); 
            end
        end
%%
        function loadTable(muicat,newdataset)
            %use bathymetry to create a SurfaceArea or Width table
            ok = 0;
            while ok<1
                promptxt = 'Select case with bathymetry:';
                [cobj,classrec] = selectCaseObj(muicat,{'data'},{'EDBimport'},promptxt);
                if isempty(cobj), return; end
                dsetnames = fieldnames(cobj.Data);
                if any(contains(dsetnames,'Grid')), ok = 1; end
            end

            dset2add = cobj.datasetnames{newdataset,1}{1};            
            %create new table and add to case object
            if strcmp(dset2add,'SurfaceArea')
                cobj = edb_surfacearea_table(cobj);
            elseif strcmp(dset2add,'Width')
                cobj = edb_width_table(cobj);
            else
                errdlg('Should not be here'); return;
            end

            %write new table to Case record
            if ~isempty(cobj)
               updateCase(muicat,cobj,classrec,true);
            end
        end

%%
        function loadProperties(muicat)
            %add gross properties dataset from bathymetry or exising
            %hypsometry dataset
            dset2add = 'Properties';       

                warndlg('Gross properties not yet implemented')     
        end
    end
%%
    methods   
        function fmt = get.formatypes(obj) %#ok<MANU> 
            %create look-up table for file formats from dataset names
            dsetnames = {'SurfaceArea','Width','Grid','Image'};
            files = {'edb_s_hyps_format';'edb_w_hyps_format';'edb_bathy_format';'edb_image_format'};
            fmt = table(files,'RowNames',dsetnames);
        end

%%
        function dsname = get.datasetnames(obj) %#ok<MANU> 
            %create look-up table for dataset names from call text
            calltxt = {'Surface area','Width','Grid','Image','Gross properties'};
            dsetnames = {'SurfaceArea';'Width';'Grid';'Image';'Properties'};            
            dsname = table(dsetnames,'RowNames',calltxt);
        end

%%
        function delDataset(obj,classrec,~,muicat)
            %delete a dataset
            dst = obj.Data;
            N = length(fieldnames(dst));
            if N==1
                %catch if only one dataset as need to delete Case
                warndlg(sprintf('There is only one dataset in this Case\nTo delete the Case use: Project > Cases > Delete Case'))
                return
            else
                promptxt = 'Select whihc datasets to delete:';
                datasets = getDataSetName(obj,promptxt,'multiple'); %prompts user to select dataset if more than one
                if ischar(datasets), datasets = {datasets}; end
                %get user to confirm selection
                for i=1:length(datasets)    
                    checktxt = sprintf('Deleting the following dataset: %s',datasets{i});
                    answer = questdlg(checktxt,'Delete','Continue','Skip','Skip');
                    if strcmp(answer,'Skip'), continue; end
                    dst = rmfield(dst,datasets{i});    %delete selected dstable
                end
            end

            obj.Data = dst;
            updateCase(muicat,obj,classrec);
        end

%%
        function tabPlot(obj,src)
            %generate plot for display on Q-Plot tab
            funcname = 'getPlot';
            datasetname = getDataSetName(obj);
            if isempty(datasetname), return; end

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
            dst = obj.Data.(datasetname);

            %generate table
            table_figure(dst,src)
        end

%%
        function [dst,idv,props] =selectVariable(obj,datasetname,subset)
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