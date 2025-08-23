function cnvdst = edb_convergence_analysis(dst)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_convergence_analysis.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_convergence_analysis(dst)
% INPUTS
%   dst - selected dataset to use for analysis
% OUTPUT
%   cnvdst - table of convergence properties for estuary data set
% NOTES
%    selectd case must have variables that use the ZM SeaZone data set
%    conventions, with variables named:
%    'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'
% SEE ALSO
%   EstuaryDB, called from edb_user_tools. edb_convergence_plots.
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
% 
    var = {'aLW','aMT','aHW';...
           'wLW','wMT','wHW';...
           'hLW','hMT','hHW'};    
	nrec = length(dst);
    a = zeros(nrec,3,3); L = a; Rsq = a; emean = a; estd = a; Vo = a; Le = a; 
    rownames{nrec,1} = [];
    rangetable = emptyTable();
    for i=1:nrec        
        d = dst(i);
        x = d.Dimensions.X;
        rownames{i} = d.Description;
        [n,m] = edb_convergence_limits(x,d,var);
        t1 = table(x(n),x(m),x(end),'RowNames',rownames(i),...
                             'VariableNames', {'Start-X','End_X','Lobs'});
        rangetable = [rangetable;t1]; %#ok<AGROW>

        for j=1:3
            for k=1:3
                y = d.(var{j,k});
                [a(i,j,k),b,Rsq(i,j,k),~,~,~] = regression_model(x(n:m)-x(n),y(n:m),'Exponential');
                if isinf(Rsq(i,j,k)), Rsq(i,j,k) = 0; end
                L(i,j,k) = 1/b;
                Vo(i,j,k) = y(n);
                Le(i,j,k) = x(find(y>0,1,'last'))-x(n);
                emean(i,j,k) = mean(y(n:m),'omitnan');
                estd(i,j,k) = std(y(n:m),'omitnan');
            end
        end
    end

    dsp = getDSproperties;
    cnvdst = dstable(a,L,Rsq,Le,Vo,emean,estd,'RowNames',rownames,...
                                                    'DSproperties',dsp);
    cnvdst.Dimensions.Var = ["Area","Width","Depth"];
    cnvdst.Dimensions.WL = ["LW","MT","HW"];
    cnvdst.Source = 'edb_convergence_analysis';
    cnvdst.MetaData = 'Along-channel convergence at LW, MT and HW';
    cnvdst.UserData = rangetable;       %unused 
end

%%
function dsp = getDSproperties()
    %define a dsproperties struct and add the model metadata
    dsp = struct('Variables',[],'Row',[],'Dimensions',[]); 
    %define each variable to be included in the data table and any
    %information about the dimensions. dstable Row and Dimensions can
    %accept most data types but the values in each vector must be unique
    
    %struct entries are cell arrays and can be column or row vectors
    dsp.Variables = struct(...                      
        'Name',{'a','L','Rsq','Le','Vo','emean','estd'},...
        'Description',{'Scale parameter','Convergence length',...
                       'Coefficient of determination','Channel length',...
                       'Mouth value','Mean value','Std.dev.value'},...
        'Unit',{'','','','','','',''},...
        'Label',{'Scale parameter','Convergence length',...
                       'Coefficient of determination','Channel length',...
                       'Mouth value','Mean value','Std.dev.value'},...
        'QCflag',repmat({'analysis'},1,7)); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{''},...
        'Unit',{'-'},...
        'Label',{'Location'},...
        'Format',{''});        
    dsp.Dimensions = struct(...    
        'Name',{'Var','WL'},...
        'Description',{'Variable','Tidal level'},...
        'Unit',{'-','-'},...
        'Label',{'Variable','Tidal level'},...
        'Format',{'',''});   
end

%%
function T = emptyTable()
    %create an empty table for the ranges used
    % Define number of rows (zero for empty), variable types, and names
    sz = [0 3];  % 0 rows, 3 variables
    varTypes = {'double', 'double', 'double'};
    varNames = {'Start-X', 'End_X',  'Lobs'};
    
    % Create the empty table
    T = table('Size', sz, 'VariableTypes', varTypes, 'VariableNames', varNames);
end

