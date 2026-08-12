function hf = edb_hypsometry_models(mobj)                       
%
%-------function help------------------------------------------------------
% NAME
%   edb_hypsometry_models.m
% PURPOSE
%   functions to fit non-linear functions to the surface area or width
%   hypsometry datasets. NB requires the Statistics and Machine Learning Toolbox
% USAGE
%   edb_hypsometry_models(mobj)
% INPUTS
%   mobj - ModelUI instance
% OUTPUT
%   hf - figure handle to plot of the hyspometry and fitted models
% NOTES
%    called as part of EstuaryDB App.
% SEE ALSO
%   EstuaryDB and edb_form_plots
%
% Author: Ian Townend
% CoastalSEA (c) Sept 2025
%--------------------------------------------------------------------------
%
    if ~license('test','Statistics_Toolbox')
        warndlg('Statistics and Machine Learning Toolbox needed for Hypsometry models');
        return;
    end

    answer = questdlg('Data type','Hypsometry','Surface area','Width','Surface area');
    
    if isempty(answer)
        return;
    elseif strcmp(answer,'Surface area')
        hf = model_surfaceArea(mobj);
    else
        hf = model_Width(mobj);
    end
end

%%
function hf = model_surfaceArea(mobj)
    %fit models to selected surface area dataset
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select Surface area dataset:');
    if isempty(cobj), return; end
    datasets = fields(cobj.Data);
    datasets = datasets(contains(datasets,'Surface'));
    if isempty(datasets), getdialog('No Surface area data'); return; end
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
    end
    dst = cobj.Data.(datasets{idd});
    [var,z] = edb_derived_hypsprops(dst,datasets{idd},'Sa'); %get S and V

    %plot labels, plots of data and models
    ptxt = struct('var1','S','vardesc1','Surface area (m^2)','var2','V',...
                  'vardesc2','Volume (m^3)','xlabel','Surface area & Volume',...
                  'title',sprintf('Hypsometry for %s',dst.Description));
    hf = addPlots(cobj,z,var,ptxt);
end

%%
function hf = model_Width(mobj)
    %fit models to selected width dataset
    cobj = selectCaseObj(mobj.Cases,[],{'EDBimport'},'Select Along-Channel dataset:');
    if isempty(cobj), return; end
    datasets = fields(cobj.Data);
    datasets = datasets(contains(datasets,'Width'));
    idd = 1;
    if length(datasets)>1
        idd = listdlg('PromptString','Select table:','ListString',datasets,...
                            'SelectionMode','single','ListSize',[160,200]);
    end
    
    dst = cobj.Data.(datasets{idd});
    [var,z,x] = edb_derived_hypsprops(dst,datasets{idd},'W'); %get W and A

    %select cross-section to use
    inp = listdlg("PromptString",'Select section to use','Name','Width',...
                  'SelectionMode','single','ListString',string(x));
    if isempty(inp), inp = 1; end
    var.W = var.W(inp,:)';
    var.A = var.A(inp,:)';

    %plot labels, plots of data and models
    ptxt = struct('var1','W','vardesc1','Width (m)','var2','A',...
                  'vardesc2','Cross-sectional area (m^2)','xlabel',...
                  'Width & CSA','title',...
                  sprintf('Hypsometry for %s (section at %d from mouth)',...
                  dst.Description,x(inp)));
    hf = addPlots(cobj,z,var,ptxt);
end

%%
function hf = addPlots(cobj,z,var,ptxt)
    %plot the source data and add selected model fits to the plot
    tlevels = [];
    %add spring tide levels and mtl to a plot (y-axis must be elevations)    
    if ~isempty(cobj.TidalProps)        
        tlevels = cobj.TidalProps;   
    end

    %non-dimensionalise the variables
    
    if isempty(tlevels)
        warndlg('Not tidal data available. Using maximum z value to scale')
        inp = inputdlg('Tidal amplitude','Tide',1,string(max(z))); 
        if isempty(inp), hf = []; return; else; WL.HW = str2double(inp{1}); end
        WL.LW = -WL.HW;
        WL.MT = 0;        
    else
        if width(tlevels)==9        %HAT,MHHW,MHW,MLWW,MTL,MHLW,MLW,MLLW,LAT
            idx = [2,5,8];     
        elseif width(tlevels)==3    %HW,MTL,LW
            idx = 1:3;         
        else                        %any eg: HAT,MHWS,MHWN,MTL,MLWN,MLWS,LAT
            nrec = width(tlevels);
            idx = 1:nrec;       
            idx = [2,round(median(idx)),idx(end-1)];  %offset if nrec even
        end     
        WL.HW = tlevels.DataTable{1,idx(1)};
        WL.LW = tlevels.DataTable{1,idx(3)};
        WL.MT = WL.LW+(WL.HW-WL.LW)/2;
        % tr = tlevels.DataTable{1,1}-tlevels.DataTable{1,3};
        % znorm = tr;        
    end

    maxvar1 = interp1(z,var.(ptxt.var1),WL.HW);     %Smx or Wmx at z=+a
    maxvar2 = interp1(z,var.(ptxt.var2),WL.HW);     %Vmx or Amx at z=+a

    %remove data above highwater
    idx = z>WL.HW;
    z(idx) = [];  var.(ptxt.var1)(idx) = [];   var.(ptxt.var2)(idx) = [];
    %remove negligable areas 
    idv = var.(ptxt.var1)<1;
    z(idv) = [];  var.(ptxt.var1)(idv) = [];   var.(ptxt.var2)(idv) = [];
    WL.zm = min(z);

    znorm = (WL.HW-WL.zm);
    zr = (z-WL.zm)/znorm;                           %relative elevation    
    fact = [WL.HW,WL.zm,maxvar1,maxvar2];           %ratio of Vmx/Smx or Amx/Wmx
    var.v1r = var.(ptxt.var1)/maxvar1;  %relative S or W
    var.v2r = var.(ptxt.var2)/maxvar2;  %relative V or A
    %adjust tide levels to relative elevations
    tfunc = @(x) (x-WL.zm)/znorm;
    tlevels = varfun(tfunc,tlevels);  %calls function in dstable

    [hf,sp] = plotHypsometry(zr,var,ptxt,tlevels);

    %add fit lines for selected non-linear regression model
    ok = 0;
    while ok<1
        modelist = {'Power law','Logisitc','Modified Strahler','Boon (1975)','CKFA form'};
        inp = listdlg('PromptString','Select model to add','Name','Model',...
                      'SelectionMode','single','ListSize',[160,100],...
                      'ListString',modelist);
        if isempty(inp), ok = 1; continue; end
        [mdl,mfunc] = getModel(zr,var,WL,modelist{inp},ptxt);
        [sp,fit(:,1),fit(:,2)] = plotModel(sp,zr,mdl,mfunc,modelist{inp},fact);

        if length(sp)==4   %add error plots
            sp = plotErrors(sp,zr,var,fit,ptxt,modelist{inp});
        end
    end    
end
%%
function [hf,sp] = plotHypsometry(z,var,ptxt,tlevels)
    %create figure with source data
    hf = figure('Name','Hypsometry','Tag','PlotFig','Units','Normalized',...
                'Position',[0.28 0.50 0.38 0.30]);
    answer = questdlg('Plot errors?','Hypsometry','Yes','No','Yes');
    if strcmp(answer,'Yes')
        hf.Position = [0.28 0.20 0.38 0.60];
        t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
    else
        t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
    end

    sp(1) = nexttile(t);
    plot(sp(1),var.v1r,z,'DisplayName',ptxt.vardesc1,'ButtonDownFcn',@godisplay)
    if ~isempty(tlevels)
        edb_plot_tidelevels(sp(1),tlevels,false); %exclude labels from legend
    end 
    xlabel(ptxt.vardesc1)
    ylabel('Relative elevation')
    set_tile_legend(sp(1),'southeast') 

    sp(2) = nexttile(t);
    plot(sp(2),var.v2r,z,'DisplayName',ptxt.vardesc2,'ButtonDownFcn',@godisplay)
    if ~isempty(tlevels)
        edb_plot_tidelevels(sp(2),tlevels,false); %exclude labels from legend
    end 
    xlabel(ptxt.vardesc2)
    set_tile_legend(sp(2),'southeast')  

    if strcmp(answer,'Yes')
        %add empty plot tiles with tide levels and zero x grid line
        sp(3) = nexttile(t);         
        p3 = plot(sp(3),[0,0],ylim,':k');
        sp(3).XLim = [-0.2, 0.2];
        p3.Annotation.LegendInformation.IconDisplayStyle = 'off'; 
        if ~isempty(tlevels)
            edb_plot_tidelevels(sp(3),tlevels,false); %exclude labels from legend
        end 
        xlabel('Relative error (obs-fit)')
        ylabel('Relative elevation')
        %set_tile_legend(sp(3),'southeast') 

        sp(4) = nexttile(t);         
        p4 = plot(sp(4),[0,0],ylim,':k');
        sp(4).XLim = [-0.2, 0.2];
        p4.Annotation.LegendInformation.IconDisplayStyle = 'off'; 
        if ~isempty(tlevels)
            edb_plot_tidelevels(sp(4),tlevels,false); %exclude labels from legend
        end 
        xlabel('Relative error (obs-fit)')
        %set_tile_legend(sp(4),'southeast') 
    end
    sgtitle(ptxt.title)
end

%%
function [mdl,mfunc] = getModel(zr,var,param,model,ptxt)
    %add the selected model to the plot and return the model fit parameters
    % zr = relative elevation
    idx = 2:length(zr);

    switch model
        case 'Power law'
            % s' = q.(z')^v and: b(1) = v, b(2) = q
            mfunc = @(b,z) b(2).*z.^b(1);
            n = 2;
        case 'Logisitc'            
            % s' = 1/(1+q.exp(-k.z'))^v and: b(1) = v, b(2) = q, b(3) = k
            mfunc = @(b,z) 1./(1+b(2).*exp(-b(3).*(z))).^b(1);
            n = 3;
        case'Modified Strahler'
            % s' = (z')^v/((z')^v.(1-q)+q) and: b(1) = v, b(2) = q
            G = @(b,z) b(3).*z.^b(1);
            mfunc = @(b,z) G(b,z)./(G(b,z).*(1-b(2))+b(2));
            n = 3;
        case 'Boon (1975)'  %only applies between high and low water
            % s' = q.(1-(1-z')^v/((1-z')^v.(1-q)+q)and: b(1) = v, b(2) = q
            G = @(b,z) (1-z).^(1./b(1));
            mfunc = @(b,z) b(2).*(1-G(b,z))./(G(b,z).*(1-b(2))+b(2));
            n = 2;
        case 'CKFA form'
            param = CKFAparameters(zr,var,param,'v1r');
            if isempty(param), mdl = []; mfunc = []; return; end 
            mfunc = @(b,z) CKFAform(b,z,param);
            n = 2;
            beta0 = [2,param.Le/2];
            opts = optimset('TolFun',1e-12,'TolX',1e-12);
            % [mdl,resnorm] = lsqcurvefit(mfunc,beta0,zr,var.v1r,[0,param.Le/100],[2,param.Le],options);
            % return;
            %**************************************************************
            %currently this return a reasonable fit but the values of the
            %fit coefficients n and Lw are nonsensical. There may be a
            %problem is the non-dimesionalisation of along-channel length
            %which is then used in the integration to get S
            %**************************************************************
    end
    % Initial guesses for [v, q, k]
    % beta0 = ones(1,n);
    % Fit the model
    tbl = table(zr, var.v1r);
    mdl = fitnlm(tbl(idx,:),mfunc,beta0);  %remove zr=0 (first row in table) 
    display(mdl)                                       %for Strahler model to converge
end

%%
function param = CKFAparameters(zr,var,param,ptxt)
    %param contains WL data: HW,MT,LW, 
    %Add additional parameters needed for CKFA model
    answer = inputdlg({'Depth at head','Estuary length'},'CKFA',1,{'1','10000'});
    if isempty(answer), param = []; return; end 
    param.dh = str2double(answer{1});
    param.Le = str2double(answer{2});
    param.x = (1:1000:param.Le)';

    amp = (param.HW-param.LW)/2;    
    z0 = (param.LW+amp);
    dm = z0-param.zm-amp;
    znorm = 2*amp+dm;  

    param.zlw = dm/znorm;
    param.Slwr = interp1(zr,var.(ptxt),param.zlw);
    param.Shwr = 1;

    Ld = -param.Le/log(-amp/param.zm);
    param.dn = dm*exp(-param.x/Ld)/znorm;
   
    param.amp = amp/znorm;
    param.z0 = (amp+dm)/znorm;

    % figure; plot(var.(ptxt),zr)
    % hold on
    % plot(xlim,[1,1]*param.zlw)
    % plot(xlim,[1,1]*param.z0)
    % hold off
end

%%
function mfunc = CKFAform(b,zc,p)
    %define the CKFA form model using surfacae area hypsometry

    z = zc';
    %Wlwm = @(b) p.Slwr/b(2)/(1-exp(-p.Le/b(2)));
    %Wmtl(b) = @(b) Smt/b(2)/(1-exp(-Le/b(2)));
    %Whwm = @(b) p.Shwr/b(2)/(1-exp(-p.Le/b(2)));
    %Wlw = @(b) Wlwm(b)*exp(-p.x/b(2));
    %Wmt = @(b) Wmtl(b)*(exp(-x/b(2));
    Wlw = @(b) p.Slwr*exp(-p.x/b(2));
    Whw = @(b) 1*exp(-p.x/b(2));
    Lstar = @(b) (Whw(b)-Wlw(b))/2.57;

    nx = length(p.x);
    ychannel = @(b,z) diag(Wlw(b))*(1 + (1./p.dn)*(z-p.zlw)).^(1/b(1));    
    ylower = @(b,z) Lstar(b)*(1+(z-p.z0)/p.amp) + Wlw(b);
    yupper = @(b,z) Lstar(b)*(1+asin((z-p.z0)/p.amp)) + Wlw(b);
    Y = @(b,z) real(ychannel(b,z).*repmat(z<p.zlw,nx,1)+...
                       ylower(b,z).*repmat(z>=p.zlw & z<p.z0,nx,1)+...
                                       yupper(b,z).*repmat(z>=p.z0,nx,1));
    % yy = Y(b,z);
    % [X,Z] = meshgrid(p.x,z);
    % figure('Tag','PlotFig');
    % surf(X,yy',Z)
   
    mfunc = trapz(p.x,Y(b,z),1)';
    mfunc = mfunc/max(mfunc);
    mfunc(mfunc<0) = 0;
    % figure('Tag','PlotFig');
    % plot(mfunc,z)
end

%%
function [sp,S_fit,V_fit] = plotModel(sp,zr,mdl,mfunc,model,fact)
    %add the selcted model to the plot
    % Extract fitted parameters
    % if contains(model,'CKFA')
    %     params = mdl;
    % else
    %     params = mdl.Coefficients.Estimate;
    % end
    params = mdl.Coefficients.Estimate;

    txt = sprintf('Fitted parameters:\n');
    for i = 1:length(params)
        txt = sprintf('%sb%d = %.4f\n',txt,i,params(i));
    end
    fprintf(txt);
    
    % Plot fit
    S_fit = mfunc(params, zr);

    hold(sp(1),'on')
    plot(sp(1),S_fit,zr,'--','DisplayName',model,'ButtonDownFcn',@godisplay)
    hold(sp(1),'off')
    set_tile_legend(sp(1),'southeast')
    
    %conpute the volume or csa hypsometry. Convert Sr or Wr to actuals to
    %do the integration to avoid scaling issues
    znorm = fact(1)-fact(2);
    z = zr*znorm+fact(2);
    S = S_fit*fact(3);
    V_fit = cumtrapz(z,S);
    V_fit = V_fit/max(V_fit);

    %plot results
    hold(sp(2),'on')
    plot(sp(2),V_fit,zr,'--','DisplayName',model,'ButtonDownFcn',@godisplay)
    hold(sp(2),'off')
    set_tile_legend(sp(2),'southeast')
end

%%
function sp = plotErrors(sp,z,var,fit,ptxt,model)
    %generate figure of errors as a function of elevation
    errS = var.(ptxt.var1)-fit(:,1);
    errV = var.(ptxt.var2)-fit(:,2);

    hold(sp(3),'on')
    plot(sp(3),errS,z,'DisplayName',model,'ButtonDownFcn',@godisplay)
    hold(sp(3),'off')
    set_tile_legend(sp(3),'southeast');
    drawnow expose

    hold(sp(4),'on')
    plot(sp(4),errV,z,'DisplayName',model,'ButtonDownFcn',@godisplay)
    hold(sp(4),'off')
    set_tile_legend(sp(4),'southeast');
end

