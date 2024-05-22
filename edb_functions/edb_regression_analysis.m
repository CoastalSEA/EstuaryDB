function cnvdst = edb_regression_analysis(obj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_regression_analysis.m
% PURPOSE
%   user functions to do additional analysis on data loaded in EstuaryDB
% USAGE
%   edb_regression_analysis(obj)
% INPUTS
%   obj - selected case to use for plot
% OUTPUT
%   cnvdst - table of convergence properties for estuary data set
% NOTES
%    selectd case must have variables that use the ZM SeaZone data set
%    conventions, with variables named:
%    'hLW','hMT','hHW','wLW','wMT','wHW','aLW','aMT','aHW','xCh'
% SEE ALSO
%   EstuaryDB
%
% Author: Ian Townend
% CoastalSEA (c) May 2024
%--------------------------------------------------------------------------
%
    dst = obj.Data.Data;    
    rownames = dst.RowNames;

    var = {'wLW','wMT','wHW';'aLW','aMT','aHW';'hLW','hMT','hHW'};
    nrec = length(rownames);
    a = zeros(nrec,3,3); L = a; Rsq = a; emean = a; estd = a; Vo = a; Le = a; 
    
    for i=1:nrec
        d = getDSTable(dst,'RowNames',rownames(i));
        x = d.xCh;      
        for j=1:3
            for k=1:3
                y = d.(var{j,k});
                [a(i,j,k),b,Rsq(i,j,k),~,~,~] = regression_model(x,y,'Exponential');
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
    cnvdst.Dimensions.Var = {'Width','Area','Depth'};
    cnvdst.Dimensions.WL = {'LW','MT','HW'};
    cnvdst.Description = dst.Description;
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
