function junk()
     figure('Name','Hypsometry','Tag','PlotFig')
    % Layout
    t = tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');
    
    % --- Tile 1 ---
    ax1 = nexttile;
    p1 = plot(ax1, 1:10, rand(1,10), 'DisplayName','Series A'); hold(ax1,'on');
    p2 = plot(ax1, 1:10, rand(1,10), 'DisplayName','Series B');
    pHelper = yline(ax1, 0, '--', 'DisplayName','zero');
    pHelper.Annotation.LegendInformation.IconDisplayStyle = 'off'; % exclude
    setTileLegend(ax1, 'northeast');
    
    % --- Tile 2 ---
    ax2 = nexttile;
    q1 = plot(ax2, 1:10, rand(1,10), 'r', 'DisplayName','Red');
    setTileLegend(ax2, 'best');
    
    % --- Tile 3 ---
    ax3 = nexttile;
    s1 = scatter(ax3, 1:10, rand(1,10), 36, 'filled', 'DisplayName','Points');
    setTileLegend(ax3, 'best');
    
    % --- Tile 4 ---
    ax4 = nexttile;
    bar(ax4, [1 3 2; 2 1 3], 'DisplayName','Bars');
    setTileLegend(ax4, 'best');
    
    % --- Later updates that WON'T break legends ---
    % Add a new line to tile 1; it won't auto-appear (legend is frozen)
    plot(ax1, 1:10, rand(1,10), 'k', 'DisplayName','Series C');
    % Manually refresh tile 1 legend to include it (exclusions preserved)
    setTileLegend(ax1, 'northeast');
    
    % Replace tile 2 content completely; legend remains until we refresh
    cla(ax2);
    plot(ax2, 1:10, cumsum(randn(1,10)), 'g', 'DisplayName','Green');
    setTileLegend(ax2, 'best');
end

function setTileLegend(ax, loc)
    if nargin < 2, loc = 'best'; end
    % Collect only legend-worthy objects from THIS axes
    h = collectLegendObjects(ax);

    % Create/update legend on this axes only
    lgd = legend(ax, h, 'Location', loc);

    % Freeze to avoid “disappearing” on redraws
    lgd.AutoUpdate = 'off';
end

function h = collectLegendObjects(ax)
    % Start from the axes’ children to avoid cross-axes leakage
    ch = ax.Children; % top -> bottom order (newest first)

    % Keep only objects with DisplayName and not explicitly excluded
    keep = false(size(ch));
    for k = 1:numel(ch)
        hasName = isprop(ch(k), 'DisplayName') && ~isempty(ch(k).DisplayName);
        % Safe guard: Annotation/LegendInformation exists on HG objects
        excl = false;
        if isprop(ch(k), 'Annotation') && ~isempty(ch(k).Annotation)
            li = ch(k).Annotation.LegendInformation;
            excl = strcmp(li.IconDisplayStyle, 'off');
        end
        keep(k) = hasName && ~excl;
    end

    % Keep creation order (oldest first) for intuitive legend ordering
    ch = flipud(ch);           % oldest first
    keep = flipud(keep);
    h = ch(keep);
end


