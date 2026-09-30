function [var,plotxt] = edb_set_input_variable(datadst,hydrodst,plotxt)
%
%-------function help------------------------------------------------------
% NAME
%   edb_set_input_variables.m
% PURPOSE
%   set the input variable based on user selection
% USAGE
%   edb_set_input_variable(mobj)
% INPUTS
%   datadst - dstable of gross properties data
%   hydrodst - dstable of hyrdo-properties derived from gross properties
%   plotxt - struct for plotting labels
% OUTPUT
%   var - selected input variable
%   plotxt - struct for plotting labels
% NOTES
%   called from edb_get_variables
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
    datadesc = datadst.VariableDescriptions;
    hydrodesc = hydrodst.VariableDescriptions;
    derdesc = {'Sfl','Intertidal Area';...
               'Vfl','Intertidal Volume';...
               'Hfl','Intertidal Depth';...
               'Vbox','Intertidal Box';...
               'Sfl/(Shw+Slw)','Relative tidal flat area';...
               'a/h','Amplitude / depth ratio'}';
    vardesc =[datadesc,hydrodesc,derdesc(2,:)];
    promptxt = sprintf('Select %s',plotxt.promptxt);
    idv = listdlg("ListString",vardesc,"PromptString",promptxt,...
                  'SelectionMode','single','ListSize',[200,420],...
                  'Name','EDBtools');
    if isempty(idv), var = []; plotxt = []; return; end  
    
    switch vardesc{idv}
        case 'Intertidal Area'
            var = datadst.Smhw-datadst.Smlw; 
            plotxt.label = 'Intertidal area (m^2)' ;
        case 'Intertidal Volume'
            var = datadst.Vmhw-datadst.Vmlw-datadst.Smlw.*datadst.TidalRange; 
            var(var<0) = NaN;
            plotxt.label = 'Intertidal volume (m^3)' ;
        case 'Intertidal Depth'
            Sfl = datadst.Smhw-datadst.Smlw; 
            Vfl = datadst.Vmhw-datadst.Vmlw-datadst.Smlw.*datadst.TidalRange; 
            Vfl(Vfl<0) = NaN;
            var = Vfl./Sfl;
            plotxt.label = 'Intertidal depth (m)' ;
        case 'Intertidal Box'
            var = datadst.Smhw.*datadst.TidalRange;
            plotxt.label = 'Intertidal box - 2a.Sfl (m)' ;
        case 'Relative tidal flat area'
            var = (datadst.Smhw-datadst.Smlw)./(datadst.Smhw+datadst.Smlw);
            plotxt.label = 'Relative tidal flat area (-)' ;
        case 'Amplitude / depth ratio'
            var = datadst.TidalRange./2./hydrodst.Hmtl;
            plotxt.label = 'Amplitude / Depth ratio' ;
        case hydrodesc
            var = hydrodst.(hydrodst.VariableNames{idv-length(datadesc)}); 
            plotxt.label = hydrodst.VariableLabels{idv-length(datadesc)};        
        otherwise
            var = datadst.(datadst.VariableNames{idv}); 
            plotxt.label = datadst.VariableLabels{idv};  
    end
    varnames = [datadst.VariableNames,hydrodst.VariableNames,derdesc(1,:)];                
    plotxt.name = varnames{idv}; 
end