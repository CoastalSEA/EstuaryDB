classdef EDB_Probe < muiPlots

    %%TAKEN FROM EF_Probe AND STILL TO BE EDITED TO NEEDS OF EDB **********
%
%-------class help---------------------------------------------------------
% NAME
%   EDB_Probe.m
% PURPOSE
%   
% NOTES
%   inherits from muiPlots
%   uses muiPlots because outputs are mainly in the form of plots. Named
%   Probe so that it is distinct from Plots and PlotsUI so that the control
%   of UI and plot deletion (muiModelUI.clearDataUI) works.
% SEE ALSO
%   called from EDB_ProbeUI.m, which defines the selection and settings in
%   properties UIselection and UIsettings. Uses muiCatalogue to access
%   data. 
%
% Author: Ian Townend
% CoastalSEA (c) Feb 2024
%--------------------------------------------------------------------------
%
    properties (Transient)
        %inherits the following properties from muiPlots
        %Plot            %struct array for:
                         %   FigNum - index to figures created
                         %   CurrentFig - handle to current figure
                         %   Order - struct that defines variable order for
                         %           plot type options (selection held in Order)

        %ModelMovie      %store animation in case user wants to save
        %UIsel           %structure for the variable selection made in the UI
        %UIset           %structure for the plot settings made in the UI
        %Data            %data to use in plot (x,y,z)
        %TickLabels      %struct for XYZ tick labels
        %AxisLabels      %struct for XYZ axis labels
        %Legend          %Legend text
        %MetaData        %text summary of primary variable selection
        %Title           %Title text
        %Order           %order of variables for selected plot type
        %idxfig          %figure number of the current figure
    end
%%
    methods 
        function obj = EDB_Probe
            %types of plot avaiable based on number of dimensions
            obj.Plot.FigNum = [];
            obj.Plot.CurrentFig = [];  
            obj.Plot.Order = EDB_Probe.setVarOrder;
        end      
    end
%%    
    methods (Static)
        function getPlot(gobj,mobj)
            %get existing instance or create new class instance
            if isfield(mobj.mUI,'Probe') && isa(mobj.mUI.Probe,'EDB_Probe') 
                obj = mobj.mUI.Probe;    %get existing instance          
                clearPreviousPlotData(obj);
            else
                obj = EDB_Probe;                   %create new instance
            end

            obj.UIsel = gobj.UIselection;
            obj.UIset = gobj.UIsettings;

            %set the variable order for selected plot type
            obj.Order = obj.Plot.Order.(obj.UIset.callTab);
            
            switch obj.UIset.callTab
                case 'Along Channel'
                    addDefaultSelection(obj,'Chainage');
                case 'Summary Plots'
                    addDefaultSelection(obj,'All');
            end

            %get the data to be used in the plot
            ok = getPlotData(obj,mobj.Cases,'array');
            if ok<1, return; end %data not found
            isvalid = checkdimensions(obj);
            if ~isvalid, return; end
            
            if ~isempty(obj.UIset.Type) && strcmp(obj.UIset.Type.String,'User')
                user_plot(obj,mobj);  %pass control to user function
            else
                %generate the plot
                setPlot(obj,mobj);
            end
        end
    end

     %%   
    methods (Access=protected)
       function setPlot(obj,mobj)    
            %manage plot generation for different types and add/delete                   
            %get an existing figure of create a new one
            getFigure(obj); 
            obj.Plot.CurrentFig.Tag = 'ProbeFig';
            %call the specific plot type requested
            callPlotType(obj,mobj);
            %assign muiPlots instance to handle
            mobj.mUI.Probe = obj;
            if isvalid(obj.Plot.CurrentFig)
                obj.Plot.CurrentFig.Visible = 'on';
            end
       end   

%%
        function callPlotType(obj,mobj)
            %call the function specific to the selected plot type           
            switch obj.UIset.callTab        %call function based on Tab
                case 'Along Channel'
                    switch obj.UIset.callButton %and Tab Button used
                        case 'New'              %create new 2D plot
                            %check whether cartesian or polar plot
                            new2Dplot(obj);  
                        case 'Add'              %add variable to 2D plot
                            if strcmp(obj.UIset.Type,'bar')
                                addBarplot(obj);
                            else
                                add2Dplot(obj);
                            end
                        case 'Delete'           %delete variable from 2D plot                            
                            del2Dplot(obj);
                    end
                case 'Tidal Cycle'
                    switch obj.UIset.Type.String      %call function based on type
                        case 'X-T surf'                    
                            EFplot_xt(obj);
                        case 'Summary @ X'
                            EFplot_t(obj,mobj);
                        case 'Phase'
                            EFplot_phase(obj,mobj);
                        otherwise
                            warndlg('Could not find plot option in callPlotType');
                    end
                case 'Summary Plots'
                    switch obj.UIset.Type.String      %call function based on type
                        case 'Channel Average'                    
                            EFplot_xav(obj,mobj);
                        case 'Channel Net'
                            EFplot_xnet(obj,mobj);
                        case 'Channel Total'
                            EFplot_totals(obj,mobj);    
                        case 'Channel Gradient'
                            EFplot_grad(obj,mobj);
                        case 'Channel Components'
                            EFplot_copmonents(obj,mobj);
                        case 'Rates of Change'
                            EFplot_dedt(obj,mobj);                        
                        case 'Flood-Ebb'
                            EFplot_floodebb(obj,mobj);
                        case 'Most Probable'
                            EFplot_mostprop(obj,mobj)
                        otherwise
                            warndlg('Could not find plot option in callPlotType');
                    end
            end
        end
 %%
        function addDefaultSelection(obj,Prop)
            %add a selection that is included by default (eg time or
            %distance)
            obj.UIsel(2) = obj.UIsel(1);            
            obj.UIsel(1).xyz = [true false];
            obj.UIsel(2).xyz = ~obj.UIsel(1).xyz; %invert logical array

            if strcmp(Prop,'Time')
                obj.UIsel(2).variable = 1;
                obj.UIsel(2).property = 2;
                obj.UIsel(2).range = obj.UIsel(1).dims(1).value;
                obj.UIsel(2).desc = 'Time';                
                obj.UIsel(2).dims = struct('name','','value',[]);

            elseif strcmp(Prop,'Chainage')
                obj.UIsel(2).variable = 1;
                obj.UIsel(2).property = 2;
                obj.UIsel(2).range = obj.UIsel(1).dims(1).value;
                obj.UIsel(2).desc = 'Chainage';                
                obj.UIsel(2).dims = struct('name','','value',[]);

            elseif strcmp(Prop,'All')                
                obj.UIsel(3) = obj.UIsel(1);            
                obj.UIsel(1).xyz = [true false false];
                obj.UIsel(2).xyz = ~obj.UIsel(1).xyz; %invert logical array
                obj.UIsel(3).xyz = ~obj.UIsel(1).xyz; %invert logical array

                obj.UIsel(2).variable = 1;
                obj.UIsel(2).property = 2;
                obj.UIsel(2).range = obj.UIsel(1).dims(1).value;
                obj.UIsel(2).desc = 'Time';                
                obj.UIsel(2).dims = struct('name','','value',[]);

                obj.UIsel(3).variable = 1;
                obj.UIsel(3).property = 3;
                obj.UIsel(3).range = obj.UIsel(1).dims(2).value;
                obj.UIsel(3).desc = 'Chainage';                
                obj.UIsel(3).dims = struct('name','','value',[]);
            end
        end

%%
%--------------------------------------------------------------------------
% Functions for Along-channel analysis plots
%------------------------------------------------------------------------
        function EFplot_xav(obj,mobj)
            %plot along channel results for average values
            ax = setEFfigure(obj);

            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            x = obj.Data.X;
            range = range2var(obj.UIsel(3).range);
            t = seconds(obj.Data.T);
            delT = t(2)-t(1);                        %time step for integration
            T = t(end)-t(1);                         %interval to integrate over
            av_V = @(V) trapz(delT,abs(V),1)/T;      %calculate average over time
            [Evars,id] = varTimeIntegration(obj,mobj,delT,av_V);

            ACEdst = cobj.Data.AlongChannelEnergy;   
            %any subsampling defined by id struct is applied to variables
            Evars.Ebar = ACEdst.EbarW(id.dim{1});    %avearge tidal energy per unit width
            Evars.Fbar = ACEdst.FbarW(id.dim{1});    %average tidal energy flux per unit width
            Evars.EB = ACEdst.EbarCSA(id.dim{1});    %average tidal energy over cross-section
            Evars.FB = ACEdst.FbarCSA(id.dim{1});    %average tidal flux over cross-section

            ACHdst = cobj.Data.AlongChannelForm;
            Evars.CSA = ACHdst.Amtl(id.dim{1});  %cross-sectional area at mtl (m^2)
            Evars.W = ACHdst.Amtl(id.dim{1})./ACHdst.Hmtl(id.dim{1});  %width at mtl (m)

            props.xtxt='Distance from mouth (m)';
            %Plot elevations and velocity
            s1 = subplot(3,2,1,ax);
            cst_x_plot(cobj,s1,range)

            %Plot discharge, area and width
            s2 = subplot(3,2,2);

            vars = [Evars.CSA;Evars.Q;Evars.W];
            props.ytxt = {'Discharge & Area','Width'};
            props.legend = {'Area (m^2)','Discharge (m^3/s)','Width (m)'};
            props.style = {'-r','-b','-g'};          %use same line style for all plots
            props.title = 'Discharge, area and width';
            props.yyaxis = [true,true,false];        %true if variable added to left axis
            multi_line_plot(s2,x,vars',props)
            props.yyaxis = true;                     %reset to left axis only

            %Energy per unit width
            s3 = subplot(3,2,3);
            vars = [Evars.E;Evars.Et;Evars.Ebar];
            props.ytxt = 'Av energy (J/m^2 of bed)';
            props.legend = {'avE','avEt','Ebar'};
            props.title = 'Energy per unit width';
            multi_line_plot(s3,x,vars',props)
            
            %Flux per unit width
            s4 = subplot(3,2,4);
            vars = [Evars.FE;Evars.FEt;Evars.Fbar];
            props.ytxt = 'Av energy flux (W/m width)';
            props.legend = {'avFE','avFEt','Fbar'};
            props.title = 'Flux per unit width';
            multi_line_plot(s4,x,vars',props)

            %Energy over cross-section
            s5 = subplot(3,2,5);
            vars = [Evars.Eb;Evars.Ebt;Evars.EB];
            props.ytxt = 'Av energy (J/m length)';
            props.legend = {'avEb','avEbt','EB'};
            props.title = 'Energy over cross-section';
            multi_line_plot(s5,x,vars',props)

            %Flux over cross-section
            s6 = subplot(3,2,6);
            vars = [Evars.FEb;Evars.FEbt;Evars.FB];
            props.ytxt = 'Av energy flux (W)';
            props.legend = {'avFEb','avFEbt','FB'};
            props.title = 'Flux over cross-section';
            multi_line_plot(s6,x,vars',props)

        end
%%
        function EFplot_xnet(obj,mobj)
            %plot along channel results for net values
            ax = setEFfigure(obj);

            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            x = obj.Data.X;
            range = range2var(obj.UIsel(3).range);
            t = seconds(obj.Data.T);
            delT = t(2)-t(1);                %interval for integration
            net_V = @(V) trapz(delT,V,1);    %calculate net over time
            Evars = varTimeIntegration(obj,mobj,delT,net_V);
            
            props.xtxt='Distance from mouth (m)';
            %Plot elevations and velocity
            s1 = subplot(2,2,1,ax);
            cst_x_plot(cobj,s1,range)

             %Plot discharge, area and width
            s2 = subplot(2,2,2);
            vars = [Evars.Q;Evars.Qt-Evars.Qs];
            props.ytxt = {'Total discharge','Tidal discharge'};
            props.legend = {'Total discharge (m^3)','Tidal discharge (m^3)'};
            props.style = {'-r','-b'};          %use same line style for all plots
            props.title = 'Discharge, area and width';
            props.yyaxis = [true,false];     %true if variable added to left axis
            multi_line_plot(s2,x,vars',props)

            %Energy per unit width
            s3 = subplot(2,2,3);
            vars = [Evars.FE;Evars.FEt];
            props.ytxt = {'Total energy flux/unit width','Tidal energy flux/unit width'};
            props.legend = {'netFE','netFEt'};
            props.title = 'Net energy flux per unit width';
            multi_line_plot(s3,x,vars',props)

            %Flux over cross-section
            s4 = subplot(2,2,4);
            vars = [Evars.FEb;Evars.FEbt];
            props.ytxt = {'Total energy flux','Tidal energy flux'};
            props.legend = {'netFEb','netFEBt'};
            props.title = 'Net energy flux';
            multi_line_plot(s4,x,vars',props)   
        end
%%
        function EFplot_totals(obj,mobj)
            %plot estimates rate of change of energy based on difference between 
            %energy flux and energy dissipation results            
            x = obj.Data.X;
            [Evars,metatxt] = ef_totals(obj,mobj);
            if isempty(Evars)
                hfig = getFigureHandle(obj);
                delete(hfig);
                return; 
            end

            switch obj.UIset.callButton
                case 'New'
                    ax = setEFfigure(obj);
                    s1 = subplot(2,2,1,ax,'Tag','s1'); 
                    s2 = subplot(2,2,2,'Tag','s2');  
                    s3 = subplot(2,2,3,'Tag','s3');  
                    s4 = subplot(2,2,4,'Tag','s4');  
                case 'Add'
                    hfig = getFigureHandle(obj);
                    s1 = findobj(hfig.Children,'Tag','s1');
                    s2 = findobj(hfig.Children,'Tag','s2');
                    s3 = findobj(hfig.Children,'Tag','s3');
                    s4 = findobj(hfig.Children,'Tag','s4');
            end

            props.xtxt='Distance from mouth (m)';
            props.yyaxis = true;  %all variables added to left axis
            %top left: variable+smoothed+exponential
            subplot(s1);
            idexp = Evars.total_exp>max(Evars.mainvar);
            Evars.total_exp(idexp) = NaN;
            vars = [Evars.mainvar,Evars.smoothvar,Evars.total_linear,Evars.total_exp];
            props.ytxt = {metatxt.varlabel};
            props.legend = {metatxt.varname,'Smooth','Linear','Exponential'};
            props.style = {'-r','-b','--c','--m'};          %use same line style for all plots
            props.title = sprintf('Total variable %s',metatxt.varname);   
            props.ConstantLine.X = metatxt.fitdistance;
            props.ConstantLine.Y = [];
            multi_line_plot(s1,x,vars,props);

            %top right: gradient of variable   
            subplot(s2);
            vars = [Evars.gradient];
            props.ytxt = {'Gradient of variable'};
            props.legend = {sprintf('Gradient of %s',metatxt.varname)};
            props.title = sprintf('Gradient of %s',metatxt.varname);     
            props.ConstantLine.X = [];
            props.ConstantLine.Y = 0;
            multi_line_plot(s2,x,vars,props);

            props.ConstantLine = []; %reset to no line
            %bottom,left: factor variable+smoothed 
            subplot(s3);
            vars = [Evars.factor,Evars.smoothfact];
            props.ytxt = {metatxt.factlabel};
            props.legend = {metatxt.factname,'Smooth'};
            props.title = sprintf('Factor variable %s',metatxt.factname);            
            multi_line_plot(s3,x,vars,props);            

            %bottom right: gradient/factor   
            subplot(s4);
            vars = [Evars.gradfactored];
            props.ytxt = {sprintf('(d%s/dx) / %s',metatxt.varname,metatxt.factname)};
            props.legend = {metatxt.varname};
            props.title = 'Factored gradient';            
            multi_line_plot(s4,x,vars,props);
            hold(s4,'on')
            plot(s4,x,Evars.meangradfactored,'--k','DisplayName','Mean value');
            legend('Location','best')
            hold(s4,'off')
        end        
%%
        function EFplot_grad(obj,mobj)
            %plot flux gradient results
            x = obj.Data.X;
            [Evars,metatxt] = ef_gradients(obj,mobj);
            ax = setAxes(obj,Evars);
            if isempty(ax), return; end

            props.xtxt='Distance from mouth (m)';
            props.yyaxis = [true,false];  %gradient on right axis
            vars = [Evars.gradfactored,Evars.gradient];
            props.ytxt = {'Factored gradient - (dV/dx) / V','Gradient - dV/dx'};
            legtxt1 = sprintf('(d%s/dx) / %s',metatxt.varname,metatxt.factname);
            legtxt2 = sprintf('d%s/dx',metatxt.varname);                          
            props.legend = {legtxt1,legtxt2};
            props.style = {'-r','-b'};  
            props.ConstantLine.X = {[];NaN};
            props.ConstantLine.Y = {mean(Evars.gradfactored);NaN};

            props.ConstantLine.X = {NaN;[]};
            props.ConstantLine.Y = {NaN;mean(Evars.gradfactored)};      
            props.title = sprintf('Factored gradient for (d%s/dx) / %s',...
                                         metatxt.varname,metatxt.factname);            
            multi_line_plot(ax,x,vars,props); 
        end
%%
        function EFplot_copmonents(obj,mobj)
            %Plot the component contributions to the total, their sum and
            %the computed total.
            x = obj.Data.X;
            [Evars,meta] = ef_components(obj,mobj);
            ax = setAxes(obj,Evars); %traps case of Evars empty and deleted figure
            if isempty(ax), return; end

            if isfield(Evars,'Stokes')
                vars = [Evars.Total,Evars.River,Evars.Tidal,Evars.Stokes,Evars.SumRTS];
                props.legend = {'Total','River','Tidal','Stokes','Sum of components'};
                props.style = {'-r','-g','-b','-c','-.m'};
            else
                vars = [Evars.Total,Evars.River,Evars.Tidal,Evars.SumRTS];
                props.legend = {'Total','River','Tidal','Sum of components'};
                props.style = {'-r','-g','-b','-.m'};
            end 
            props.xtxt='Distance from mouth (m)';
            props.yyaxis = true;  %all variables added to left axis
            props.ytxt = {meta.ylabel};                     
            props.title = sprintf('Components for %s: %s',meta.Case,meta.summation); 
            multi_line_plot(ax,x,vars,props);            
        end
%%
        function EFplot_dedt(obj,mobj)
            %plot estimates rate of change of energy based on difference between 
            %energy flux and energy dissipation results 
            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            x = obj.Data.X;            
            [E,meta] = ef_dedt(obj,mobj);
            ax = setAxes(obj,E);
            if isempty(ax), return; end

            plot(x,E.dEdt,x,E.dEdts,x,E.dFdx,x,E.Eds,x,E.Ed0);
            hold on
            h1 = plot([0,x(end)],[0,0],'--k'); %zero line
            h1.Annotation.LegendInformation.IconDisplayStyle = 'off';  
            legend('dE//dt','dE//dts','dF//dx','\epsilon_ds','\epsilon_d0','Location','Best');
            titletxt = sprintf('%s: %s',cobj.Data.TidalCycleHydro.Description,...
                                                           meta.Selection);
            title(titletxt)
        end
%%
        function EFplot_floodebb(obj,mobj)
            %plot for along estuary values of flood and ebb
            x = obj.Data.X;
            [Evars,metatxt] = ef_flood_ebb(obj,mobj);
            ax = setAxes(obj,Evars);
            if isempty(ax), return; end
            
            idc = 1;
            mcolors = {'r','b','g','c','m'};
            mline = {'-','--','-.',':'};
            sty = @(idl,idc) sprintf('%s%s',mline{idl},mcolors{idc});
            hL = findobj(ax.Children,'Type','line');
            if ~isempty(hL)
                idc = 1+length(hL)/2;
            end

            props.xtxt='Distance from mouth (m)';
            props.yyaxis = true;              %set to left axis only
            vars = [Evars.flood,-Evars.ebb];
            props.ytxt = {metatxt.All.label};
            legtxt1 = sprintf('%s flood',metatxt.All.name);
            legtxt2 = sprintf('%s ebb',metatxt.All.name);                          
            props.legend = {legtxt1,legtxt2};
            props.style = {sty(1,idc),sty(2,idc)};  
            props.title = sprintf('Flood and Ebb %s',metatxt.All.name);            
            multi_line_plot(ax,x,vars,props); 
        end
%%
        function EFplot_mostprop(obj,mobj)
            %plot most probable differences results
            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            x = obj.Data.X;
            [Evars,metatxt] = ef_most_probable(obj,mobj);
            if ~isfield(Evars,'tidalmpc')
                delete(getFigureHandle(obj));
                return; 
            end

            switch obj.UIset.callButton
                case 'New'
                    ax = setEFfigure(obj);
                    s1 = subplot(2,1,1,ax,'Tag','s1'); 
                    s2 = subplot(2,1,2,'Tag','s2'); 
                case 'Add'
                    hfig = getFigureHandle(obj);
                    s1 = findobj(hfig.Children,'Tag','s1');
                    s2 = findobj(hfig.Children,'Tag','s2');
            end

            props.xtxt='Distance from mouth (m)';
            props.yyaxis = true;              %set to left axis only
            %top left: variable+smoothed+exponential
            subplot(s1);
            vars = [Evars.River,Evars.Tidal,Evars.rivermpc,Evars.tidalmpc,Evars.Total];
            props.ytxt = {metatxt.Tidal.label};                      
            props.legend = {'River','Tidal','River MPC','Tidal MPC','Total'};
            props.style = {'-c','-b','--m','-.m','-r'};
            props.title = sprintf('Most probable for %s',metatxt.Tidal.name);            
            multi_line_plot(s1,x,vars,props); 

            %bottom,left: factor variable+smoothed 
            subplot(s2);
            vars = [Evars.riverdiff,Evars.tidaldiff];
            props.ytxt = {metatxt.Tidal.label};                        
            props.legend = {'River','Tidal'};
            props.style = {'-g','-b'};
            props.title = 'Difference from most probable';  
            props.ConstantLine.X = [];
            props.ConstantLine.Y = 0;
            multi_line_plot(s2,x,vars,props);            

            annotxt = sprintf('%s\n%s',metatxt.tidaltxt,metatxt.rivertxt); 
            annotation('textbox',[.25 .3 .5 .1],'String',annotxt,...
                                          'FitBoxToText','on','FontSize',8)
            titletxt = sprintf('Energy flux for %s, L_x_o = %.0fm',...
                        cobj.Data.TidalCycleEnergy.Description,metatxt.Lex);
            sgtitle(titletxt)
        end
%%
%--------------------------------------------------------------------------
% Functions for X-T analysis plots
%--------------------------------------------------------------------------
        function EFplot_xt(obj)
            %plot results as x-t surface contour plot
            ax = setEFfigure(obj);
        
            x = obj.Data.X;
            t = hours(obj.Data.T);
            var = obj.Data.Y;
            tp = t/max(t);            %time steps for model (s)
            xp = x/max(x);            %distances from mouth  

            %check array dimension is not too large
            xint = length(x)-1;
            tint = length(t)-1;
            [xint,tint] = check_xyz_dims(xint,tint);
            [xq,tq,var] = muiPlots.reshapeXYZ(xp,tp,var,xint,tint);

            %plot figure and label
            contourf(ax,xq,tq,var)
            txtidx = regexp(obj.Legend,'(');
            title(['X-T surface for ',obj.Legend(1:txtidx-2)]);
            xlabel('Relative distance from mouth');
            ylabel('Phase in tidal cycle');
            
            %select color map to use and add colorbar
            cmap = cmap_selection; 
            if isempty(cmap), cmap = 'parula'; end
            colormap(cmap)
            c = colorbar('Location','Eastoutside');
            c.Label.String = obj.AxisLabels.Y;
        end

%%
        function EFplot_t(obj,mobj)
            %plot time series results at x
            [hpnl,hf] = setSliderFigure(obj,false);

            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            x = obj.Data.X;
            idx = 1;              %initial index of distance
            t = hours(obj.Data.T);
            sprops.tp = t/max(t);
            sprops.stype = 'Distance';
            sprops.panel = hpnl;
            sprops.cbfunc = 'updateCyclePlot';
            sprops.cbinput = '(lobj,vars,props)';
            txtidx = regexp(obj.Legend,'(');
            sprops.case = (obj.Legend(1:txtidx-2));
            
            %elevation, velocity, river flow
            dstH = cobj.Data.TidalCycleHydro;  
            subdst = getDSTable(dstH,'VariableNames',{'Elevation','TidalVel','RiverVel'});           
            if isfield(cobj.Data,'TidalCycleEnergy')
                %total energy, tidal energy, total energy flux, tidal energy
                %flux and total discharge
                dstE = cobj.Data.TidalCycleEnergy;
                edst = getDSTable(dstE,'VariableNames',{'E','Et','FE','FEt','Q'});
                subdst =  horzcat(edst,subdst);
            end

            if ~isprop(subdst,'Elevation')
                subdst = activatedynamicprops(subdst);
            end
            Evars = getPlotInput(obj,subdst,sprops,idx);
            sprops = setCyclePlot(obj,sprops);
            updateCyclePlot(obj,Evars,sprops)            
            
            setSlideControl(obj,hf,x,subdst,sprops); 
        end
%%
        function EFplot_phase(obj,mobj)
            %plot phase space results at x
            [hpnl,hf] = setSliderFigure(obj,false);

            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            dst = cobj.Data.TidalCycleEnergy;

            x = obj.Data.X;
            idx = 1;              %initial index of distance
            t = time2num(obj.Data.T);
            tint = length(t);     %time intervals around cycle for plot labels
            nint = floor(tint/9);
            sprops.intervals = 1:nint:tint;
            sprops.labels = string((0:1:length(sprops.intervals)-1)')';
            sprops.stype = 'Distance';           
            sprops.axes = axes('Parent',hpnl);
            sprops.cbfunc = 'setPhasePlot';
            sprops.cbinput = '(lobj,vars,props)';
            
            %total energy, tidal energy, total energy flux, tidal energy flux
            subdst = getDSTable(dst,'VariableNames',{'E','Et','FE','FEt'});
            Evars = getPlotInput(obj,subdst,sprops.stype,idx);
            Evars = normaliseInput(obj,Evars);
            setPhasePlot(obj,Evars,sprops);
            text(0.02,0.95,'Time markers are at T/10 intervals',...
                           'Units','normalized','Tag','Hold');

            txtidx = regexp(obj.Legend,'(');
            title(obj.Legend(1:txtidx-2));
            xlabel('Normalised Energy flux'); 
            ylabel('Normalised Tidal Energy or Total Energy');

            setSlideControl(obj,hf,x,subdst,sprops);
        end

%%
        function hm = setSlideControl(obj,hfig,svar,dst,sprops)
            %intialise slider to set different distance/time values   
            invar = struct('sval',[],'smin',[],'smax',[],'size', [],...
                           'callback','','userdata',[],'position',[],...
                           'stxext','','butxt','','butcback','');            
            invar.smin = min(svar);     %minimum slider value
            invar.smax = max(svar);     %maximum slider value
            invar.sval = invar.smin;    %initial value for slider 
            invar.callback = @(src,evt)updateSliderPlot(obj,sprops,src,evt); %callback function for slider to use
            invar.userdata = dst;       %pass userdata if required 
            invar.position = [0.15,0.008,0.60,0.04]; %position of slider
            invar.stext = [sprops.stype,' = ']; %text to display with slider value, if included          
            % invar.butxt =  'Save';    %text for button if included
            % invar.butcback = @(src,evt)saveanimation2file(obj.ModelMovie,src,evt); %callback for button
            hm = setfigslider(hfig,invar);   
            uicontrol('Parent',hfig,...
                    'Style','text','String',num2str(invar.smin),'Units','normalized',... 
                    'Position',[0.1,0.05,0.15,0.03],'Tag','LimitTxt');
            uicontrol('Parent',hfig,...
                    'Style','text','String',num2str(invar.smax),'Units','normalized',... 
                    'Position',[0.65,0.05,0.15,0.03],'Tag','LimitTxt');
        end  

%%
        function updateSliderPlot(obj,sprops,src,~)
            %use the updated slider value to adjust the CST or EF plot
            sldui = findobj(src.Parent,'Tag','figslider');
            dst = sldui.UserData;     %recover userdata

            if strcmp('Time',sprops.stype)
                svar = dst.RowNames;
                if isdatetime(svar)  || isduration(svar)
                    svar = time2num(svar);
                end
            else
                svar = dst.Dimensions.X;
            end

            %use slider value to find the nearest set of results
            stxt = findobj(src.Parent,'Tag','figsliderval');
            [~,idx] = min(abs(svar-src.Value));
            stxt.String = num2str(svar(idx));     %update slider text
        
            %figure axes and update plot
            Evars = getPlotInput(obj,dst,sprops.stype,idx);
            heq = str2func(['@',sprops.cbinput,[sprops.cbfunc,sprops.cbinput]]); 
            try
               heq(obj,Evars,sprops); 
            catch ME
                msg = sprintf('Unable to run function %s\nID: ',sprops.cbfunc);
                disp([msg, ME.identifier])
                rethrow(ME)                     
            end
        end
%%
        function setPanelFigureTitle(~,sprops)
            %add a title to a panelled figure      
            ha = annotation('textbox','string',sprops.case);
            ha.Units = 'normalized';
            ha.Position = [0, 0.84, 1, 0.16];
            ha.HorizontalAlignment = 'center';
            ha.VerticalAlignment = 'top';
        end

%%
        function Evars = getPlotInput(~,dst,stype,idx)
            %get input data to update plot based on slider index
            tint = height(dst);
            nvars = width(dst);
            varnames = dst.VariableNames;
            Evars = zeros(tint,nvars);
            for ivar=1:nvars
                 Evar = dst.(varnames{ivar});
                 if strcmp('Time',stype)
                    Evars(:,ivar) = Evar(idx,:);
                 else
                    Evars(:,ivar) = Evar(:,idx);
                 end
            end
        end

%%
        function Evars = normaliseInput(~,Evars)
            %normalise variables relative to max value
            nvars = size(Evars,2);
            for ivar=1:nvars            
                Evars(:,ivar) = Evars(:,ivar)/max(Evars(:,ivar));
            end
        end

        %%
        function [figax,hfig] = setEFfigure(obj)
            %get figure created using muiPlots.setFigure and add axes
            hfig = getFigureHandle(obj);
            figax = axes('Parent',hfig,'Tag','PlotFigAxes');
            hold(figax,'on')
        end


%%
        function ax = setAxes(obj,Evars)
            %delete figure if no data otherwise get plot axes
            if isempty(Evars)
                hfig = getFigureHandle(obj);
                delete(hfig);
                ax = []; return; 
            end

            switch obj.UIset.callButton
                case 'New'
                    ax = setEFfigure(obj);
                case 'Add'
                    hfig = getFigureHandle(obj);
                    ax = findobj(hfig.Children,'Type','axes');
            end
        end
%%
        function [hpnl,hfig]= setSliderFigure(obj,istitle)
            %get figure created using muiPlots.setFigure and add panel with 
            %space for slider below and title above (optional)
            % istitle - flag to include space for title above panel
            if istitle
                pnlpos = [0,0.08,1,0.84];
            else
                pnlpos = [0,0.08,1,0.92];
            end
            hfig = getFigureHandle(obj);
            hpnl = uipanel('Units','normalized','Position',pnlpos,...
                                                        Tag='SliderPanel');
        end
    end
%%

    methods
        function sprops = setCyclePlot(~,sprops)
            %construct plot of time series results at x
            tp = sprops.tp;
            
            s(1) = subplot(3,1,1,'Parent',sprops.panel);
            h1 = plot(tp,zeros(size(tp)),':g');
            h1.Annotation.LegendInformation.IconDisplayStyle = 'off'; 
            yyaxis left
            ylabel('Elevation')
            yyaxis right
            ylabel('Velocity')
            xlabel('Phase in tidal period');
            legend('Location','Best','Color','none');
            
            s(2) = subplot(3,1,2);
            yyaxis left
            ylabel('Energy')
            yyaxis right
            ylabel('Discharge')
            xlabel('Phase in tidal period');
            legend('Location','Best','Color','none');
            
            s(3) = subplot(3,1,3);
            h2 = plot(tp,zeros(size(tp)),':g');
            h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
            ylabel('Energy Flux')
            xlabel('Phase in tidal period');             
            legend('Location','Best','Color','none');
            
            sgtitle(sprops.case,'FontSize',12)
            sprops.axes = s;
        end
        
%%
        function updateCyclePlot(~,Evars,sprops)
            %update plot lines only
            s = sprops.axes;
            tp = sprops.tp;
            
            subplot(s(1))
            fa = findobj(s(1),'Tag','Update'); delete(fa)  
            yyaxis left
            hold on
            plot(tp,Evars(:,6),'-r','DisplayName','Elevation (mAD)','Tag','Update');
            hold off
            yyaxis right
            hold on
            plot(tp,Evars(:,7)+Evars(:,8),'-.b','DisplayName','Velocity (m/s)','Tag','Update'); %NB this excludes the Stokes term
            hold off
            
            subplot(s(2))
            yyaxis left
            fa = findobj(s(2),'Tag','Update'); delete(fa)   
            hold on
            plot(tp,Evars(:,2),'-r','DisplayName','Energy (J/m^2)','Tag','Update');            
            plot(tp,Evars(:,1),'--m','DisplayName','Tidal Energy (J/m^2)','Tag','Update');   
            hold off
            yyaxis right
            hold on
            plot(tp,Evars(:,5),'-.g','DisplayName','Discharge (m^3/s)','Tag','Update'); 
            hold off
            
            subplot(s(3))
            fa = findobj(s(3),'Tag','Update'); delete(fa) 
            hold on
            plot(tp,Evars(:,4).*(abs(Evars(:,4))>0.1),'-r','DisplayName','Energy flux (W/m)','Tag','Update');
            plot(tp,Evars(:,3).*(abs(Evars(:,3))>0.1),'--m','DisplayName','Tidal energy flux (W/m)','Tag','Update');
            hold off
        end

%%
        function setPhasePlot(obj,Evars,sprops)
            %construct phase plot based on selected x value. Called
            %initially for x=0 and then based on slider value
            ax = sprops.axes;
            fa = findobj(ax,'Tag','Update');
            delete(fa)
            hold(ax,'on')
            Evars = normaliseInput(obj,Evars);
            in = sprops.intervals;
            t_lab = sprops.labels;
            plot(ax,Evars(:,4),Evars(:,2),'-r','DisplayName','FE-E(tidal)','Tag','Update');
            plot(ax,Evars(:,3),Evars(:,1),'--b','DisplayName','FE-E(total)','Tag','Update');
            t_fhp = Evars(in,4); t_hp = Evars(in,2);
            text(t_fhp,t_hp, t_lab,'Color','r','Tag','Update', ...
                                      'BackgroundColor','w','FontSize',8);
            t_fep = Evars(in,3); t_ep = Evars(in,1);
            text(t_fep,t_ep, t_lab,'Color','b','Tag','Update', ...
                                      'BackgroundColor','w','FontSize',8);
            legend('Location','Best','Color','none');
            hold(ax,'off')
        end

%%
        function [Evars,id] = varTimeIntegration(obj,mobj,delT,anonEqn) %#ok<INUSD> %used in anonymous equation
            %assign time summary of variable (average, net sum, etc)
            % anoneqn - anonymous equation to be used to derive Evars
            % Evars - struct of energy and energy flux variables
            cobj = getCase(mobj.Cases,obj.UIsel(1).caserec);
            dst = cobj.Data.TidalCycleEnergy;
            varnames = cobj.Data.TidalCycleEnergy.VariableNames;
            %attributes do not change and can be defined from by any variable
            [attribnames,~,~] = getVarAttributes(dst,obj.UIsel(1).variable);
            [id,~] = getSelectedIndices(mobj.Cases,obj.UIsel(1),dst,attribnames);

            for i=1:length(varnames)
                %to use getProperty would need to reset variable range for
                %each variable. uset getData instead.
                obj.UIsel(1).variable = i;                
                varis = getData(dst,id.row,i,id.dim);
                if obj.UIsel(1).scale>1 && obj.UIsel(1).property==1  %apply selected scaling to variable
                    usescale = obj.UIset.scaleList{obj.UIsel(1).scale};
                    dim = 2; %scale along channel values
                    varis = {scalevariable(varis{1},usescale,dim)};
                end
                Evars.(varnames{i}) = anonEqn(varis{1}(id.row,:));
            end

%             Evars.Et = anonEqn(dst.Et);    %tidal energy per unit width
%             Evars.E = anonEqn(dst.E);      %energy per unit width
%             Evars.FEt = anonEqn(dst.FEt);  %tidal energy flux per unit width
%             Evars.FE = anonEqn(dst.FE);    %energy flux per unit width
%             Evars.Ebt = anonEqn(dst.Ebt);  %tidal energy over cross-section
%             Evars.Eb = anonEqn(dst.Eb);    %energy over cross-section
%             Evars.FEbt = anonEqn(dst.FEbt);%tidal energy flux over cross-section
%             Evars.FEb = anonEqn(dst.FEb);  %energy flux over cross-section 
%             Evars.Q = anonEqn(dst.Q);      %total discharge: river and tide (m^3/s) 
%             Evars.Qt = anonEqn(dst.Qt);    %tidal discharge: river and tide (m^3/s)
%             Evars.Qs = anonEqn(dst.Qs);    %Stokes discharge: river and tide (m^3/s)            
        end
    end
%%
%--------------------------------------------------------------------------
% Static EDB_Probe functions
%--------------------------------------------------------------------------
    methods(Static, Access=protected)
        function varorder = setVarOrder()
            %struct that holds the order of the variables for different
            %plot types        
            varnames = {'Along Channel','Tidal Cycle','Summary Plots'};
            %types of plot in 2,3 and 4D            
            d2 = {'Y','X'};
            %d3 = {'Z','X','Y'};
            %types of animaton in 2,3 and 4D        
            t2 = {'Y','T','X'};
            %t3 = {'Z','T','X','Y'};
            varorder = table(d2,t2,t2,'VariableNames',varnames);
        end


    end
end