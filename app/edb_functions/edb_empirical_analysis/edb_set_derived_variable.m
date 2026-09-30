function [var,plotxt] = edb_set_derived_variable(datadst,hydrodst,classdst,plotxt)
%
%-------function help------------------------------------------------------
% NAME
%   edb_set_derived_variables.m
% PURPOSE
%   set the derived variable based on user selection
% USAGE
%   edb_set_derived_variable(mobj)
% INPUTS
%   datadst - dstable of gross properties data
%   hydrodst - dstable of hyrdo-properties derived from gross properties
%   classdst - dstable of estuary classification
%   plotxt - struct for plotting labels
% OUTPUT
%   var - selected input variable
%   plotxt - struct for plotting labels
% NOTES
%   called from edb_get_variables
%   THIS IS RESEARCH CODE AND SHOULD NOT BE USED FOR GENERAL APPLICATIONS
%
% Author: Ian Townend
% CoastalSEA (c) Aug 2026
%--------------------------------------------------------------------------
%
    vardesc = {'mPr','Modified prism';...
               'mPrTr','Modified prism / Tidal range';...
               'mPrSb','Modified prism / Basin area';...
               'mSb','Modified basin area';...
               'mH', 'Modified hydraulic depth'
               'eD','Estimated central depth';...
               'eSfl','Estimated Flat area';...
               'eVfl','Estimated Flat volume';...
               'eH','Estimated depth';...
               'eVlw','Estimated Channel volume';...
               'eVlw','Estimated Channel volume (Dronkers)';...
               'LW','Width Convergence length';...
               'LA','Area Convergence length'};
    % varnames = {'mPr','mPrTr','mPrSb','mSb','eSfl','eVfl','eH','eVlw','d-a','La'};
    promptxt = sprintf('Select %s',plotxt.promptxt);
    idv = listdlg("ListString",vardesc(:,2),"PromptString",promptxt,...
                  'SelectionMode','single','ListSize',[200,180],...
                  'Name','EDBtools');
    if isempty(idv), var = []; plotxt = []; return; end 
    plotxt.name = vardesc{idv,1};

    switch vardesc{idv,2}
        case 'Modified prism'     
            % mprism = modifiedPrism(datadst,hydrodst,classdst,1);
            [mprism,isobs] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});
            if isempty(mprism), var = []; return; end
            var = mprism;
            plotxt.label = 'Modified prism (m^3)';
            if isobs
                plotxt.label = 'Modified prism-using obs (m^3)';  
            end

        case 'Modified prism / Tidal range'
            % mprism = modifiedPrism(datadst,hydrodst,classdst,0);
            [var,isobs] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{2,2});
            if isempty(var), return; end     
            plotxt.label = 'Modified prism / Tidal range (m^2)';  
            if isobs
                plotxt.label = 'Modified prism / Tidal range using obs (m^2)';  
            end

        case 'Modified prism / Basin area'
            % mprism = modifiedPrism(datadst,hydrodst,classdst,1);
            mprism = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});
            if isempty(mprism), var = []; return; end
            var = mprism./datadst.Smhw;
            plotxt.label = 'Modified prism / Basin area (m)';

        case 'Modified basin area'  
            %returns Slw=LW/Lambda*Shw
            [var,idh] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{4,2});     
            plotxt.label = 'Modified Basin area (m^2)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);

        case 'Modified hydraulic depth'
            [mprism,~] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});
            if isempty(mprism), var = []; return; end
            V = mprism;

            [sprism,idh] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});
            if isempty(sprism), var = []; return; end
            S = sprism./datadst.TidalRange; 
            var = V./S;
            plotxt.label = 'Modified hydraulic depth (m)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);

        case 'Central depth'
             var = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{5,2}); 
            plotxt.label = 'Estimated central depth (m)' ;           
           
        case 'Estimated Flat area'
            [Slw,idh] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{4,2}); 
            var = datadst.Smhw-Slw;
            var(var<=0) = NaN;
            plotxt.label = 'Estimated Flat area (m^2)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);
        case'Estimated Flat volume'
            [Slw,idh] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{4,2}); 
            Sfl = datadst.Smhw-Slw;
            Sfl(Sfl<=0) = NaN;
            alp = getalpha_flat(datadst,classdst);
            % alp = ones(size(Sfl))*0.435;
            % for i=1:numel(alp)
            %     if any(strcmp(classdst.Country{i},{'England','Wales','Scotland'}))
            %         alp(i) = 0.79;
            %     elseif strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
            %                 strcmp(classdst.GeomorType{i},'Tidal flat')
            %         alp(i) = 2.014-0.195*log10(datadst.Smhw(i));
            %         %alp(i) = 0.53;
            %     end
            % end
            var = (1-alp).*Sfl.*datadst.TidalRange; %scale coefficient, alpha_fl, used to get proportion
            plotxt.label = 'Estimated Flat volume (m^3)' ;
            plotxt = setVarName(plotxt,hydrodst,idh);
        case 'Estimated depth'
            promptxt = {'Depth scaling coefficient'};
            inp = inputdlg(promptxt,'Depth',1,{'1'});
            if isempty(inp), return; end
            Dfact = str2double(inp{1});
            var = Dfact*datadst.TidalRange;
            plotxt.label = 'Estimated depth (m)';  
        case 'Estimated Channel volume'
            answer = questdlg('Option','Vlw','mPr','Slw','mPr-aSlw','mPr');
            switch answer
                case 'mPr'
                    [var,~] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});                  
                case 'Slw'
                    [Slw,~] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{4,2});
                    mprism = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});
                    Shw = datadst.Smhw;
                    alp = getalpha_flat(datadst,classdst);
                    amp = datadst.TidalRange/2;
                    mc = (1-2*alp); mc(mc<0) = 0;
                    var = mprism-amp.*(Slw+mc.*(Shw-Slw));
                case 'mPr-aSlw'
                    [Slw,~] = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{4,2});           
                    Smt = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{2,2});

                    mprism = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{1,2});
                    a = datadst.TidalRange/2;
                    var = mprism-a.*(Slw+Smt)/2;
            end
            var(var<=0) = NaN;
            plotxt.name =sprintf('%s-%s',plotxt.name,answer);
            plotxt.label = 'Estimated Channel volume (m^3)';

        case 'Estimated Channel volume (Dronkers)'
            promptxt = {'Dronkers gamma:'};
            inp = inputdlg(promptxt,'Empirical',1,{'1.1'});  
            hm = datadst.Vmtl./datadst.Smtl;
            amp = datadst.TidalRange/2;
            r = zeros(size(hm));
            for i=1:length(hm)
                r(i,1) = hypsometry_exponent(hm(i),amp(i),str2double(inp{1}));
            end
            var = datadst.Vmtl./(r.*hm).*(r.*hm-amp).^r;
            var(var<0) = NaN;
            plotxt.name =sprintf('%s-%s',plotxt.name,'gamma');
            plotxt.label = 'Estimated Channel volume (m^3)';
        case 'Width Convergence length'
            var = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{12,2});
            plotxt.label = 'Width convergence length';
            
        case 'Area Convergence length'
            var = edb_modified_variable_functions(datadst,hydrodst,...
                                                classdst,vardesc{13,2});
            plotxt.label = 'Area convergence length';
        otherwise            
            var = hydrodst.(hydrodst.VariableNames{idv}); 
            plotxt.label = hydrodst.VariableLabels{idv};
    end      
end

%%
function plotxt = setVarName(plotxt,hydrodst,idh)
    %if varname already set add hydraulic depth used for independent
    %variable
    if isfield(plotxt,'varname')
        plotxt.name =sprintf('%s (%s)',plotxt.name,hydrodst.VariableNames{idh});
    end
end

%%
function alp = getalpha_flat(datadst,classdst)
    Smhw = datadst.Smhw;
    alp = ones(size(Smhw))*0.435;
    for i=1:numel(alp)
        if any(strcmp(classdst.Country{i},{'England','Wales','Scotland'}))
            alp(i) = 0.79;
        elseif strcmp(classdst.GeomorType{i},'Tidal inlet') || ...
                    strcmp(classdst.GeomorType{i},'Tidal flat')
            alp(i) = 2.014-0.195*log10(datadst.Smhw(i));
            %alp(i) = 0.53;
        end
    end
end