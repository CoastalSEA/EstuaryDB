classdef EDBimport < muiDataSet                          
%
%-------class help---------------------------------------------------------
% NAME
%   EDBimport.m
% PURPOSE
%   Class to import a spreadsheet table or Matlab table, adding the results
%    to dstable and a record in a dscatlogue (as a property of muiCatalogue)
% USAGE
%   obj = EDBimport.loadData(muicat,
% SEE ALSO
%   uses dstable and dscatalogue
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%    
    properties  
        %inherits Data, RunParam, MetaData and CaseIndex from muiDataSet
    end
    
    methods 
        function obj = EDBimport()                
            %class constructor
        end
    end
%%    
    methods (Static)
        function loadData(muicat)
            %read and load a data set from a file
            obj = EDBimport;  
            [newdst,fname] = EDBimport.loadFile();
            if isempty(newdst), return; end

            promptxt = 'Provide a short description of the sources used for the data';
            answer = inputdlg(promptxt,'EDBimport',1);

            if isa(newdst,'struct')
                dsetnames = fieldnames(newdst);
                for j=1:length(dsetnames)
                    dst = dsetnames{j};
                    newdst.(dst) = EDBimport.updateDSproperties(newdst.(dst)); 
                    newdst.(dst).Source{1} = fname;
                    newdst.(dst).MetaData = answer{1};
                end
            else
                newdst = EDBimport.updateDSproperties(newdst);            
                %assign metadata about data
                newdst.Source{1} = fname;
                newdst.MetaData = answer{1};
            end
            %setDataRecord classobj, muiCatalogue obj, dataset, classtype
            setDataSetRecord(obj,muicat,newdst,'data');           
        end 

%%
function [newdst,fname] = loadFile()    
            [fname,path,~] = getfiles('FileType','*.mat; *.txt; *.xlsx',...
                                           'PromptText','Select file to load');
            if fname==0, newdst = []; return; end
            [~,~,ext] = fileparts(fname);

            if strcmp(ext,'.mat')
                %load data from an existing Matlab dstable or table
                inp = load([path,fname]);
                tablename = fieldnames(inp);
                intable = inp.(tablename{1});
                if isa(intable,'table')                              
                    rownames = intable.Properties.RowNames;
                    newdst = dstable(intable,'RowNames',rownames);
                else
                    newdst = inp.(tablename{1});
                end
            elseif strcmp(ext,'.txt')
                %read a text file with the row names defined in the first
                %column and the variable names defined in the first row
                intable = readtable([path,fname],'FileType','text',...
                     'ReadRowNames',true,'ReadVariableNames',true,...
                     'VariableNamingRule','preserve');
                rownames = intable.Properties.RowNames;
                newdst = dstable(intable,'RowNames',rownames);
            else
                %load data from an Excel spreadsheet
                newdst = readspreadsheet([path,fname],true); %return a dstable
            end
        end

%%
        function dst = updateDSproperties(dst)
            %prompt user to edit the variable and row definitions
            aa = dst.DSproperties;               
            vardef = getDSpropsStruct(aa,2);
            vardef.Variables.QCflag = 'none';
            vardef.Row.Format = '''';
            setDefaultDSproperties(aa,...
                        'Variables',vardef.Variables,'Row',vardef.Row);
            dst.DSproperties = setDSproperties(aa);

            %add data type to format
            varnames = dst.VariableNames;
            for i=1:length(varnames)
                value = dst.(varnames{i})(1);
                if isdatetime(value) || isduration(value)
                    dtype = value.Format;
                else
                    dtype = getdatatype(value);                    
                end
                dst.VariableQCflags{i} = dtype{1};
            end
        end

    end   
%%
    methods
        function addData(obj,classrec,~,muicat) 
            %add additional data to an existing user dataset
            datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
            dst = obj.Data.(datasetname);      %selected dstable
            [newdst,fname] = EDBimport.loadFile();
            if isempty(newdst), return; end

            rowvar = questdlg('Add rows or variables?','Add data','Rows','Variables','Quit','Rows');

            if strcmp(rowvar,'Quit')
                return;
            elseif strcmp(rowvar,'Rows')
                dst = vertcat(dst,newdst);
            else
                dst = horzcat(dst,newdst);
            end
            
            %assign metadata about data
            nfile = length(dst.Source);
            dst.Source{nfile+1} = fname;
            
            obj.Data.(datasetname) = dst;  
            updateCase(muicat,obj,classrec);
        end   
        
%%
        function deleteData(obj,classrec,~,muicat)
            %delete variable or rows from a dataset
            datasetname = getDataSetName(obj); %prompts user to select dataset if more than one
            dst = obj.Data.(datasetname);      %selected dstable

            rowvar = questdlg('Add rows or variables?','Add data','Rows','Variables','Quit','Rows');
            if strcmp(rowvar,'Quit')
                return;
            elseif strcmp(rowvar,'Rows')
                %select variable to use
                delist = dst.DataTable.Properties.RowNames; %get char row names
                promptxt = 'Select rows'; 
                att2use = 1;
                if length(delist)>1
                    [att2use,ok] = listdlg('PromptString',promptxt,...
                                     'Name','Delete data','SelectionMode','multiple',...
                                     'ListSize',[250,100],'ListString',delist);
                    if ok<1, return; end  
                end
                %delete selected variables
                dst = removerows(dst,att2use);  %delete selected rows   
            else                
                %select variable to use
                delist = dst.VariableNames;
                promptxt = 'Select Variable'; 
                att2use = 1;
                if length(delist)>1
                    [att2use,ok] = listdlg('PromptString',promptxt,...
                                     'Name','Delete data','SelectionMode','multiple',...
                                     'ListSize',[250,100],'ListString',delist);
                    if ok<1, return; end  
                end
                %delete selected variables
                dst = removevars(dst,delist(att2use));  %delete selected rows
            end
           
            obj.Data.(datasetname) = dst;            
            updateCase(muicat,obj,classrec);
        end        

%%
        function tabPlot(obj,src)
            %generate plot for display on Q-Plot tab
            tabcb  = @(src,evdat)tabPlot(obj,src);
            ax = tabfigureplot(obj,src,tabcb,false);            
            %get data for variable and dimensions x,y,t
            datasetname = getDataSetName(obj);
            dst = obj.Data.(datasetname);
            %--------------------------------------------------------------
            if strcmp(datasetname,'Images')
                img = dst.image;
                location = dst.RowNames;
                idv = listdlg('PromptString','Select estuary:',...
                           'SelectionMode','single',...
                           'ListString',location);
                imshow(img{idv});
            else
                vardesc = dst.VariableDescriptions;
                idv = listdlg('PromptString','Select variable:',...
                               'SelectionMode','single',...
                               'ListString',vardesc);
                if isempty(idv), return; end

                if size(dst.DataTable{1,1},2)>1
                    idx = listdlg('PromptString','Select X-variable:',...
                               'SelectionMode','single',...
                               'ListString',vardesc);
                    if isempty(idv), return; end
                    vectorplot(obj,ax,dst,idv,idx);
                else
                    scalarplot(obj,ax,dst,idv);
                end
            end
        end    

%%
        function vectorplot(~,ax,dst,idv,idx)
            %plot selected variable for all locations
            location = dst.RowNames;
            var = dst.(dst.VariableNames{idv});
            Xvar = dst.(dst.VariableNames{idx});
            hold on
            for i=1:size(var,1)
                pvar = var(i,:)/max(var(i,:));   
                xvar = Xvar(i,:)/max(Xvar(i,:));
                p1 = plot(ax,xvar,pvar,'DisplayName',location{i});
                p1.ButtonDownFcn = {@godisplay};
            end
            hold off
            xlabel(sprintf('Normalised %s',dst.VariableLabels{idx}))
            ylabel(sprintf('Normalised %s',dst.VariableLabels{idv}))
            title(dst.Description)
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plot  
        end

%%
        function scalarplot(~,ax,dst,idv)
            %plot selected variable as function of location
            location = dst.RowNames;
            rn = categorical(location,location);
            x = dst.DataTable{:,idv};
            if iscell(x) && ischar(x{1})                   
                x = categorical(x,'Ordinal',true);    
                cats = categories(x);
                x = double(x); %convert categorical data to numerical
            else
                cats = [];
            end
            %option to plot alphabetically or in index order
            answer = questdlg('Sort x?','Index','Alphabetical','Unsorted','Index');
            [rn,x] = sortXdata(rn,x,answer);
            
            %bar plot of selected variable
            bar(ax,rn,x);          
            title (dst.Description);
            if ~isempty(cats)
                yticks(1:length(cats));
                yticklabels(cats);
            end
            xlabel(dst.RowLabel)
            ylabel(dst.VariableLabels{idv})
            answer = questdlg('Linear or Log y-axis?','Qplot','Linear','Log','Linear');
            if strcmp(answer,'Log')
                ax.YScale = 'log';
            end
            ax.Color = [0.96,0.96,0.96];  %needs to be set after plot  
        end
%%
        function [rn,x]  = sortXdata(~,dst,rn,x,answer)
            %function to sort x-axis data to required order
            if strcmp(answer,'Index')
                
            elseif strcmp(answer,'Alphabetical')  
    
            end
        end
    end
end