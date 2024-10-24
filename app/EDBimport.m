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
        function obj = EDBimport()                
            %class constructor
            formatfile = obj.setFileFormat;
            if isempty(formatfile), return; end
            obj.DataFormats = {'muiUserData',formatfile};
            obj.idFormat = 1;
            defaults= {'on','*.txt; *.csv; *.xlsx;*.xls;*.jpg'};
            promptxt = {'MultiSelect (on or off):','File types:'};
            answer = inputdlg(promptxt,'File spec',1,defaults);
            if isempty(answer)
                obj.FileSpec = defaults;
            else
                obj.FileSpec = answer;
            end 
        end
    end
%%
%--------------------------------------------------------------------------
%   functions to read data from file and load as a dstable
%   data formats are defined in the format files
%--------------------------------------------------------------------------
    methods  (Static)
        function obj = loadData(muicat,classname,newflg)
            %load user data set from one or more files
            % mobj - handle to modelui instance 
            % classname - name of class being loaded
            % newflag - in call from addData to indicate use of existing
            %           record
            if nargin<3
                newflg = 'Yes';
            end
            obj = EDBimport;
            if isempty(obj.DataFormats), return; end

%             %get file format from class definition        
%             idf = getFileFormatID(obj,muicat);  %existing uses of format            
%             if strcmp(newflg,'Yes') || isempty(idf) || length(idf)>1
%                 %no format set or multiple formats set, so get selection
%                 ok = setFileFormatID(obj);
%                 if ok<1, return; end
%             else
%                 obj.idFormat = idf;             %use existing format
%             end
            
            [fname,path,nfiles] = getfiles('MultiSelect',obj.FileSpec{1},...
                'FileType',obj.FileSpec{2},'PromptText','Select file(s):');
            if ~iscell(fname)
                fname = {fname};   %single select returns char
            end
         
            funcname = 'getData';
            hw = waitbar(0, 'Loading data. Please wait');  
% 
%             %load file and create master collection which can
%             %have multiple profiles (ie locations saved as id_rec)            
%             for jf=1:nfiles
%                 filename = [path fname{jf}];
%                 [newdata,ok] = callFileFormatFcn(obj,funcname,obj,filename);
%                 if ok<1 || isempty(newdata), continue; end
%                 
%                 %newdst is a struct of dstables with profile_id as the fieldname
%                 profid = fieldnames(newdata);
%                 idx = strcmp(muicat.Catalogue.CaseClass,classname);
%                 existprofs = muicat.Catalogue.CaseDescription(idx);
%                 %loop round and add each profile as a new record
%                 for ip=1:length(profid)
%                     anest = newdata.(profid{ip}); %dstable of profile data
%                     %if the profile does not exist save as new record                    
%                     if isempty(existprofs) || ...
%                                         all(~strcmp(existprofs,profid{ip}))
%                         %cumulative list of files names used to load data
%                         anest.Source{jf} = filename;             
%                         %add first data set to empty classobj, or
%                         %add new profile to classobj                        
%                         setDataSetRecord(obj,muicat,anest,'data',profid(ip),true);
%                         obj = ctBeachProfileData;
%                         obj.idFormat = idf;    
%                     else
%                         %profile exists - add data to existing record
%                         classrec = find(strcmp(existprofs,profid{ip})); 
%                         localObj = muicat.DataSets.(classname)(classrec);                        
%                         localObj = addBPdataFile(localObj,anest);                       
%                         updateCase(muicat,localObj,classrec,false);
%                     end  
%                 end
%                 clear existprofs newdata anest profid
%                 waitbar(jf/nfiles)
%             end




            %read data files and concatanate the data
            filename = [path fname{1}];
            [dst,ok] = callFileFormatFcn(obj,funcname,obj,filename,[]);
            if ok<1 || isempty(dst), return; end
            for jf=2:nfiles
                filename = [path fname{jf}];
                [dst,ok] = callFileFormatFcn(obj,funcname,obj,filename,dst);
                if ok<1 || isempty(dst), continue; end
                waitbar(jf/nfiles)
            end
            %add new dstable to class obj                        
            setDataSetRecord(obj,muicat,dst,'data');
            close(hw);
            if nfiles>1
                getdialog(sprintf('Data loaded in class: %s',classname)); 
            end

        end

    end

%%
    methods 
        function tabPlot(obj,src)
            %generate plot for display on Q-Plot tab
            funcname = 'getPlot';
            dst = obj.Data.Dataset;
            [var,ok] = callFileFormatFcn(obj,funcname,dst,src);
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