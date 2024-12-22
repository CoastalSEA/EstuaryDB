classdef EDBimport < muiDataSet                       
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
        function obj = loadData(muicat,classname,~)
            %load user data set from one or more files
            % mobj - handle to modelui instance 
            % classname - name of class being loaded
            obj = EDBimport;
            if isempty(obj.DataFormats), return; end
            
            [fname,path,nfiles] = getfiles('MultiSelect',obj.FileSpec{1},...
                'FileType',obj.FileSpec{2},'PromptText','Select file(s):');
            if isnumeric(fnames) && fnames==0
                return;            %user cancelled
            elseif ~iscell(fname)
                fname = {fname};   %single select returns char
            end
         
            %assume metatxt description of data source applies to all files
            promptxt = {'Provide description of the data source          >'};
            metatxt = inputdlg(promptxt,'EDBimport',1);
    
            funcname = 'getData';
            hw = waitbar(0, 'Loading data. Please wait');  

            %load file and create master collection which can
            %have multiple estuaries (ie locations)            
            for jf=1:nfiles
                filename = [path fname{jf}];
                [newdata,ok] = callFileFormatFcn(obj,funcname,obj,filename);
                if ok<1 || isempty(newdata), continue; end
                dstname = fieldnames(newdata);
                estname = newdata.(dstname{1}).Description;
                newdata.(dstname{1}).MetaData = metatxt{1};
                %newdst is a struct of dstables with estuaryname as the fieldname
                idx = strcmp(muicat.Catalogue.CaseClass,classname);
                existest = muicat.Catalogue.CaseDescription(idx);
                %loop round and add each profile as a new record

                    %newdata = newdata.(profid{ip}); %dstable of profile data
                    %if the estuary does not exist save as new record                    
                    if isempty(existest) || ...
                                        all(~strcmp(existest,estname))
                        %cumulative list of files names used to load data
                        newdata.(dstname{1}).Source{1} = filename;   
                        %add file format
                        newdata.(dstname{1}).UserData = obj.DataFormats{2};
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
                        localObj.Data.(dstname{1}).UserData = obj.DataFormats{2};
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
        function [pmax] = vectorplot(ax,dst,props,idv,idx)
            %plot selected variable for all locations 
            %props - array of props, same size as idv to define legend
            Xvar = dst.(dst.VariableNames{idx});
            xvar = Xvar/max(Xvar);
            hold on
            for i=1:length(idv)
                var = dst.(dst.VariableNames{idv(i)});
                pvar = var/max(var);  
                cname = get_selection_text(props(i),1);
                pl = plot(ax,xvar,pvar,'DisplayName',cname);
                pl.ButtonDownFcn = {@godisplay};
                varmax(i) = max(var); %#ok<AGROW> 
            end
            pmax.var = num2cell(varmax);
            pmax.x = max(Xvar);
            hold off
            legend
            xlabel(sprintf('Normalised %s',dst.VariableLabels{idx}))
            ylabel(sprintf('Normalised %s',dst.VariableLabels{idv(1)}))
            title(['Case: ',dst.Description])
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plot  
        end
    end
%%
    methods     
        function delDataset(obj,classrec,~,muicat)
            %delete a dataset
            dst = obj.Data;
            N = length(fieldnames(dst));
            if N==1
                %catch if only one dataset as need to delete Case
                warndlg(sprintf('There is only one dataset in this Case\nTo delete the Case use: Project > Cases > Delete Case'))
                return
            else
                datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
                %get user to confirm selection
                checktxt = sprintf('Deleting the following dataset: %s',datasetname);
                answer = questdlg(checktxt,'Delete','Continue','Quit','Quit');
                if strcmp(answer,'Quit'), return; end
                dst = rmfield(dst,datasetname);    %delete selected dstable
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
            obj.DataFormats{2} = obj.Data.(datasetname).UserData;

            [var,ok] = callFileFormatFcn(obj,funcname,obj,src,datasetname);
            if ok<1, return; end
            
            if var==0  %no plot defined so use muiDataSet default plot
                tabDefaultPlot(obj,src);
            end
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

 %%
        function tabTable(obj,src)
            %generate table for display on Table tab
            ht = findobj(src,'-not','Type','uitab'); %clear any existing content
            delete(ht)
            datasetname = getDataSetName(obj);
            dst = obj.Data.(datasetname);
            firstcell = dst.DataTable{1,1};
            if ~isscalar(firstcell) || (iscell(firstcell) && ~isscalar(firstcell{1}))
                %not tabular data
                warndlg('Selected dataset is not tabular')
                return; 
            end 

            desc = sprintf('Source:%s\nMeta-data: %s',dst.Source{1},dst.MetaData);
            tablefigure(src,desc,dst);        
            src.Units = 'normalized';
            uicontrol('Parent',src,'Style','text',...
                       'Units','normalized','Position',[0.1,0.95,0.8,0.05],...
                       'String',['Case: ',dst.Description],'FontSize',10,...
                       'HorizontalAlignment','center','Tag','titletxt');
        end       
    end
end