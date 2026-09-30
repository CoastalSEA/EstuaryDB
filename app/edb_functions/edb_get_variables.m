function [depvar,indvar,plotxt] = edb_get_variables(datadst,hydrodst,classdst)
%
%-------function help------------------------------------------------------
% NAME
%   edb_get_variables.m
% PURPOSE
%   Functions to derive datasets related to estuary hydraulic properties such
%   as hydraulic depths, prism etc.
% USAGE
%   [depvar,indvar,plotxt] = edb_get_variables(data,hydro,eclass,plotxt)                                                         
% INPUTS
%   datadst  - dstable of gross properties data
%   hydrodst - dstable of hyrdo-properties derived from gross properties
%   classdst - dstable of estuary classification
% OUTPUT
%   depvar - selected dependent variable
%   indvar - selected independent variable
%   plotxt - struct for plotting labels
% NOTES
%   called from EstuaryDB option edb_user_tools>edb_empirical_props 
%   or theedb_user_bespoke_tools options for edb_ukdb__analytical_solutions, 
%   abd edb_ukws__analytical_solutions
%
% Author: Ian Townend
% CoastalSEA (c) Oct 2024
%--------------------------------------------------------------------------
%
    answer = questdlg('Single or complex variable','Empirical','Single','Complex','Single');
    %select variables to plot
    plotxt.promptxt = '';
    if strcmp(answer,'Single')
        %use observed values as the dependent variable and either 
        %hydraulic or derived values as the indpendent variable
        [depvar,indvar,plotxt] = singleVariables(datadst,hydrodst,classdst,plotxt);
        if isempty(indvar), return; end
    else
        %use more than one variable to define dependent and/or
        %independent variables e.g. as ratios.
        [depvar,indvar,plotxt] = complexVariables(datadst,hydrodst,classdst,plotxt);
        if isempty(indvar), return; end
    end
end

%%
function [depvar,indvar,plotxt] = singleVariables(datadst,hydrodst,classdst,plotxt)
    %use observed values as the dependent variable     
    plotxt.promptxt = 'Dependent (y) variable';
    [depvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt);
    if isempty(depvar), indvar = []; return; end 
    plotxt.ylabel = plotxt.label;
    plotxt.varname = plotxt.name;

    %use either hydraulic or derived values as the indpendent variable
    plotxt.promptxt = 'Independent (x) variable';
    [indvar,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt);        
    if isempty(indvar), return; end   
    plotxt.xlabel = plotxt.label;
    plotxt.varname = [plotxt.varname,' (',plotxt.name,')'];

    %add cases description to title
    plotxt.title = datadst.Description;
end

%%
function [depvar,indvar,plotxt] = complexVariables(datadst,hydrodst,classdst,plotxt)
    %use more than one variable to define dependent and/or independent
    %variables e.g. as ratios.
    depvar = []; indvar = [];
    promptxt = @(X) sprintf('%s\n(Quit for 1)',X);
    plotxt.promptxt = promptxt('Nominator for Dependent (y) variable');
    [varn,plotxtn] = getVariable(datadst,hydrodst,classdst,plotxt);
    %if isempty(plotxtn), return; end  %user selected Quit

    plotxt.promptxt = promptxt('Denominator for Dependent (y) variable');
    [vard,plotxtd] = getVariable(datadst,hydrodst,classdst,plotxt);

    if isempty(varn) && isempty(vard)
        return;
    elseif isempty(varn)
        depvar = 1./vard;
        plotxt.ylabel = ['1 / ',plotxtd.label];
        plotxt.varname = ['1 / ',plotxtd.name];
    elseif isempty(vard)
        depvar = varn;
        plotxt.ylabel = plotxtn.label;
        plotxt.varname = plotxtn.name;
    else
        depvar = varn./vard;
        plotxt.ylabel = [plotxtn.label,' / ',plotxtd.label];
        plotxt.varname = [plotxtn.name,'/',plotxtd.name];
    end
    
    %now get independent variable
    plotxt.promptxt = promptxt('Nominator for Independent (x) variable');
    [varn,plotxtn] = getVariable(datadst,hydrodst,classdst,plotxt);

    plotxt.promptxt = promptxt('Denominator for Independent (x) variable');
    [vard,plotxtd] = getVariable(datadst,hydrodst,classdst,plotxt);

    if isempty(varn) && isempty(vard)
                return;
    elseif isempty(varn)
        indvar = 1./vard;
        plotxt.xlabel = ['1 / ',plotxtd.label];
        plotxt.varname = [plotxt.varname,' (1/',plotxtd.name,')'];
    elseif isempty(vard)
        indvar = varn;
        plotxt.xlabel = plotxtn.label;
        plotxt.varname = [plotxt.varname,' (',plotxtn.name,')'];
    else
        indvar = varn./vard;
        plotxt.xlabel = [plotxtn.label,' / ',plotxtd.label];
        plotxt.varname = [plotxt.varname,' (',plotxtn.name,'/',plotxtd.name,')'];
    end
    %add cases description to title
    plotxt.title = datadst.Description;
end

%%
function [var,plotxt] = getVariable(datadst,hydrodst,classdst,plotxt)
    %select either a data variable or a derived variable
    promptxt = sprintf('Select %s:',plotxt.promptxt);
    answer = questdlg(promptxt,'Variable','Input','Derived','Quit','Input');
    if strcmp(answer,'Input')
        %select variable from input data set
        [var,plotxt] = edb_set_input_variable(datadst,hydrodst,plotxt);        
    elseif strcmp(answer,'Derived')
        %select variable from derived data set or create new variable       
        [var,plotxt] = edb_set_derived_variable(datadst,hydrodst,classdst,plotxt);
    else
        var = []; plotxt = [];
    end
end