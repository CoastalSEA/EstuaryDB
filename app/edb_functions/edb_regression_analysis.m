function cnvdst = edb_regression_analysis(dst)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_regression_analysis.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_regression_analysis(dst)
% INPUTS
%   dst - selected dataset to use for analysis
% OUTPUT
%   cnvdst - table of convergence properties for estuary data set
% NOTES
%    selectd case must have variables that use the ZM SeaZone data set
%    conventions, with variables named:
%    'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'
% SEE ALSO
%   EstuaryDB, called from edb_user_tools
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
% 
    var = {'wLW','wMT','wHW';'aLW','aMT','aHW';'hLW','hMT','hHW'};    
	nrec = length(dst);
    a = zeros(nrec,3,3); L = a; Rsq = a; emean = a; estd = a; Vo = a; Le = a; 
    rownames{nrec,1} = [];
    for i=1:nrec        
        d = dst(i);
        x = d.xCh;  
        rownames{i} = d.Description;
        for j=1:3
            for k=1:3
                y = d.(var{j,k});
                [a(i,j,k),b,Rsq(i,j,k),~,~,~] = regression_model(x,y,'Exponential');
                if isinf(Rsq(i,j,k)), Rsq(i,j,k) = 0; end
                L(i,j,k) = 1/b;
                Vo(i,j,k) = y(1);
                Le(i,j,k) = x(find(y>0,1,'last'))-x(1);
                emean(i,j,k) = mean(y,'omitnan');
                estd(i,j,k) = std(y,'omitnan');
            end
        end
    end

    dsp = getDSproperties;
    cnvdst = dstable(a,L,Rsq,Le,Vo,emean,estd,'RowNames',rownames,...
                                                    'DSproperties',dsp);
    cnvdst.Dimensions.Var = ["Width","Area","Depth"];
    cnvdst.Dimensions.WL = ["LW","MT","HW"];
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
