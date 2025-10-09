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
%            Variables include: 'a','L','Rsq','Le','Xo','Vo','emean','estd'
%            UserData holds table with: 'Start-X','End_X','L_obs'
% NOTES
%    selected case must have variables that use the ZM SeaZone data set
%    conventions, with variables named:
%    'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW'
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

    %check that selected data has the required variables (all variables in
    %the dst array should have the same names)
    idv = contains(var,dst(1).VariableNames);
    if all(idv,'all')
        %full dataset
    elseif any(idv,'all')
        %sub-set of variables available
        missingvar = sprintf('%s ',var{~idv});
        warndlg(sprintf('The following variables are missing or misspelt: %s', missingvar))
    else
        warndlg(sprintf('Convergence analysis requires variables:\nhLW, hMT, hHW, wLW, wM, wHW, aLW, aMT, aHW'));
        return        
    end

    a = zeros(nrec,3,3); L = a; Rsq = a; emean = a; estd = a; Xo = a; 
    Vo = a; Le = a; 
    rownames{nrec,1} = [];
    rangetable = emptyTable();
    for i=1:nrec        
        d = dst(i);
        x = d.Dimensions.X;
        rownames{i} = d.Description;
        [n,m] = edb_convergence_limits(x,d,var);
        t1 = table(x(n),x(m),x(end),'RowNames',rownames(i),...
                             'VariableNames', {'Start-X','End_X','L_obs'});
        rangetable = [rangetable;t1]; %#ok<AGROW>

        for j=1:size(var,1)
            for k=1:size(var,2)
                y = d.(var{j,k});
                [a(i,j,k),b,Rsq(i,j,k),~,~,~] = regression_model(x(n:m)-x(n),y(n:m),'Exponential');
                if isinf(Rsq(i,j,k)), Rsq(i,j,k) = 0; end
                L(i,j,k) = 1/b;
                Xo(i,j,k) = x(n);                
                Vo(i,j,k) = y(n);
                Le(i,j,k) = x(m)-x(n);
                emean(i,j,k) = mean(y(n:m),'omitnan');
                estd(i,j,k) = std(y(n:m),'omitnan');
            end
        end
    end

    dsp = getDSproperties;
    cnvdst = dstable(a,L,Rsq,Le,Xo,Vo,emean,estd,'RowNames',rownames,...
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
        'Name',{'a','L','Rsq','Le','Xo','Vo','emean','estd'},...
        'Description',{'Scale parameter','Convergence length',...
                       'Coefficient of determination','Channel length',...
                       'Mouth distance','Mouth value','Mean value','Std.dev.value'},...
        'Unit',{'','m','-','m','m','','',''},...
        'Label',{'Scale parameter','Convergence length',...
                       'Coefficient of determination','Channel length',...
                       'Mouth distance','Mouth value','Mean value','Std.dev.value'},...
        'QCflag',repmat({'analysis'},1,8)); 
    dsp.Row = struct(...
        'Name',{'Location'},...
        'Description',{''},...
        'Unit',{'-'},...
        'Label',{'Location'},...
        'Format',{''});        
    dsp.Dimensions = struct(...    
        'Name',{'CSVar','WL'},...
        'Description',{'Cross-section variable','Tidal level'},...
        'Unit',{'-','-'},...
        'Label',{'Cross-section variable','Tidal level'},...
        'Format',{'',''});   
end

%%
function T = emptyTable()
    %create an empty table for the ranges used
    % Define number of rows (zero for empty), variable types, and names
    sz = [0 3];  % 0 rows, 3 variables
    varTypes = {'double', 'double', 'double'};
    varNames = {'Start-X', 'End_X',  'L_obs'};
    
    % Create the empty table
    T = table('Size', sz, 'VariableTypes', varTypes, 'VariableNames', varNames);
end

