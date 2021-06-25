% ************************************************************************
% Function: plotOptDist
% Purpose:  Plot the parameter distributions from an optimisation trace.
%           At the same time, identify the peak distibution values.
%           For categorical variables it is the value with the highest
%           frequency. For continuous variables in the highest peak of a 
%           probability density function.
%
%
% Parameters:
%
%           XTrace:             table logging the optima recorded by
%                               smOptimiser
%
%           varDef:             variable definitions - a cell array of
%                               optimizableVariables
%
%           setup               options
%               .showPlots:     whether to plot distributions
%                               (default = false)
%               .useGroups:     whether to use grouping in plots
%                               (default = false)
%
%           figRef:             cell array of figure handles (optional)
%
%           group:              group identifiers (optional)
%
%
% Output:
%           XOptimum:        optimal parameters in same table format
%           XFreq:           frequency optimal parameters appears
%                            or the probability density if continuous
%           figRef:          figure handles
%
% ************************************************************************

function [ XOptimum, XFreq, figRef ] = ...
                plotOptDist( XTrace, varDef, setup, figRef, group )
            
% parse arguments
if nargin < 2
    error('Insufficient arguments');
end

if nargin < 3
	setup.notSpecified = true;
end


% set option defaults where required
if isfield( setup, 'showPlots' )
    if ~islogical( setup.showPlots )
        error('Options: showPlots must be Boolean.');
    end
else
    setup.showPlots = true; % default
end

if isfield( setup, 'useSubPlots' )
    if ~islogical( setup.showPlots )
        error('Options: useSubPlots must be Boolean.');
    end
else
    setup.useSubPlots = true; % default
end

if isfield( setup, 'useGroups' )
    if ~islogical( setup.showPlots )
        error('Options: useGroups must be Boolean.');
    end
else
    setup.useGroups = false; % default
end

if ~isfield( setup, 'layout' )
    setup.layout = 'square'; % default
end

if ~isfield( setup, 'transform' )
    setup.transform = true; % default
end

if ~isfield( setup, 'compact' )
    setup.compact = false; % default
end


% get dimensions
[nObs, nVar] = size( XTrace );


if setup.transform
    if isfield( setup, 'descr' ) && ...
            isfield( setup, 'fcn' ) && ...
            isfield( setup, 'bounds' )
        % extend varDef to include these fields
        varDef = extendVarDef( varDef, setup );
    else
        % some requisite fields are missing
        error('Insufficient fields for plot transformation: descr, fcn, bounds.');
    end 
end

% extract only the active variables
varDef = varDef( activeVarDef(varDef) );
if nVar ~= length( varDef )
    error('The number optimizable variables (varDef) does not match the XTrace');
end

if setup.showPlots
    
    % setup the layout of the plots
    switch setup.layout
        case 'square'
            [ plotRows, plotCols ] = sqdim( nVar );
            setup.position = 1:nVar;
        case 'vertical'
            plotRows = nVar;
            plotCols = 1;
            setup.position = 1:nVar;
        case 'horizontal'
            plotRows = 1;
            plotCols = nVar;
            setup.position = 1:nVar;
        case 'vertical-adaptive'
            if ~isfield( setup, 'position' )
                error('No positioning list included within setup for vertical-adaptive');
            end
            plotRows = length( setup.position );
            plotCols = 1;
            setup.position = setup.position( setup.position~=0 );
        otherwise
            error('Unrecognised setup.layout');
    end
    
    if isempty( figRef )
        % setup figures - one time only
        if setup.useSubPlots
            figRef = figure;
        else
            figRef = gobjects( nVar, 1 );
            for i = 1:nVar
                figRef(i) = figure;
            end   
        end
    end
end

if nargin < 5 || isempty( group )
    group = ones( nObs, 1 ); % default
end

% identify unique group identifiers
groupID = unique( group );
nGroups = length( groupID );

% append group variable to table
XTrace.groupVar = group;

% create empty optimum table using first row to get matching format
XOptimum = XTrace(1,:); % (the actual values with be updated)
XFreq = zeros( 1, size(XOptimum,2) );

nPts = 401;

for i = 1:nVar
    
    varName = XTrace.Properties.VariableNames{i};
    if setup.showPlots
        k = setup.position(i); % subplot/figure ID
    end
        
    if strcmpi( varDef(i).Type, 'categorical' )
        
        % categorical variable       
              
        % count the frequencies for the ith variable
        cTable = groupcounts( XTrace, i );
        
        % identify and record highest frequency
        [ topFreq, topLoc ] = max( cTable.GroupCount );
        XOptimum.(varName)(1) = cTable.(varName)(topLoc);
        XFreq(1,i) = topFreq/nObs;        
    
        if setup.showPlots
            if setup.useSubPlots
                figure( figRef );
                subplot( plotRows, plotCols, k );
            else
                figure( figRef(k) );
            end
            if nGroups == 1
                plotFreq( XTrace, varDef(i), setup.compact );
            else
                plotLayeredFreq( XTrace, varDef(i) );
            end
        end
        
    else
        
        % numeric variable (real/integer)
                
        % define range - must be extended
        XFitBorder = 0.5*( varDef(i).Range(2) - varDef(i).Range(1) );
        XFitMin = varDef(i).Range(1) - XFitBorder;
        XFitMax = varDef(i).Range(2) + XFitBorder;

        XFit = linspace( XFitMin, XFitMax, nPts )';
        
        % determine overall PDF
        YPDF = fitdist( XTrace.(varName), 'Kernel', ...
                               'Kernel', 'Normal', ...
                               'Width', 0.2*XFitBorder );                
        YAll = pdf( YPDF, XFit );
        YTotal = sum( YAll );

        % identify and record highest frequency
        [ topFreq, topLoc ] = max( YAll );
        XOptimum.(varName)(1) = XFit( topLoc );
        if strcmpi( varDef(i).Type, 'integer' )
            XOptimum.(varName)(1) = round( XOptimum.(varName)(1) );
        end
        XFreq(1,i) = topFreq/YTotal;        
    
        if setup.showPlots
            if setup.useSubPlots
                figure( figRef );
                subplot( plotRows, plotCols, k );
            else
                figure( figRef(k) );
            end
            if nGroups == 1
                plotPDF( YAll, varDef(i), XFit, YTotal, setup.compact );
            else
                plotLayeredPDF( XTrace, varDef(i), YTotal );
            end
        end
        
        
    end
        
end

XOptimum = XOptimum( :, 1:end-1 );
XFreq = XFreq( :, 1:end-1 );

end


function plotFreq( X, varDef, isCompact )
 
    % set colour
    colour = [0 0.4470 0.7410];
    highlight = [0.4940 0.1840 0.5560];
    
    % set plot attributes
    attr = setPlotAttr( varDef );
    
    nCat = length( varDef.Range );
    
    % insert all categories at the beginning to ensure all are present
    XInsert = repelem( X(1,:), nCat, 1 );
    for i = 1:nCat
        XInsert.(varDef.Name)(i) = varDef.Range{i};
    end
        
    % count the number of models for ith var, grouped by fold
    cTable = groupcounts( [X; XInsert], varDef.Name );
    
    % sort into standard order by adding numeric category
    cTable.level = zeros( height(cTable), 1 );
    for i = 1:height(cTable)
        cTable.level(i) = find( cTable.(varDef.Name)(i)==varDef.Range );
    end
    cTable = sortrows( cTable, 'level' );

    % extract the totals remembering that extras were added
    c = cTable.GroupCount-1;

    % convert to percentages
    cPct = 100*c./sum( c, 'all' );
    
    % separate the category with the highest frequency
    [~, top] = max( cPct );
    cPct = [ cPct zeros(length(cPct), 1) ];
    cPct( top, : ) = [ 0 cPct( top, 1 ) ];
       
    % now plot the chart
    barObj = bar( cPct, 'Stacked', ...
                        'FaceAlpha', 0.2, ...
                        'FaceColor', 'flat', ...
                        'LineWidth', 1 );
                                          
    % highlight category with highest frequency

    barObj(1).FaceAlpha = 0.2;
    barObj(1).CData = colour;
    barObj(1).EdgeColor = colour;
    
    barObj(2).FaceAlpha = 1;
    barObj(2).CData = highlight;
    barObj(2).EdgeColor = colour;
    
    % add labels
    if isCompact
        
        % only use initials
        nLabels = length( varDef.Range );
        labels = strings( nLabels, 1 );
        for i = 1:nLabels
            labels(i) = initials( varDef.Range{i} );
        end
        fontSize = 6;
        axWidth = 0.5;
        axYLabel = 'Proportion';
        
    else
        
        labels = varDef.Range;
        fontSize = 8;
        axWidth = 1;
        axYLabel = 'Proportion (%)';

    end
    
    xticklabels( labels );
    xlabel( attr.XLabel );   
    ylabel( axYLabel );
    
    % finish formatting
    set( gca, 'Box', false' );
    set( gca, 'TickDir', 'out' );
    set( gca, 'LineWidth', axWidth );
    set( gca, 'FontName', 'Arial' );
    set( gca, 'FontSize', fontSize );
    
    drawnow;
    
end



function plotLayeredFreq( X, varDef )
 
    colourRGB = getColours;
    nCol = size( colourRGB, 1 );
    
    % set plot attributes
    attr = setPlotAttr( varDef );
    
    uniqueGroups = unique(X.groupVar);
    nGroups = length( uniqueGroups );
    nCat = length( varDef.Range );
    
    % insert all categories at the beginning to ensure all are present
    XInsert = repelem( X(1,:), nCat*nGroups, 1 );
    for i = 1:nCat
        for j = 1:nGroups
            XInsert.(varDef.Name)( (i-1)*nGroups+j ) = varDef.Range{i};
            XInsert.groupVar( (i-1)*nGroups+j ) = uniqueGroups(j);
        end
    end
        
    % count the number of models for ith var, grouped by fold
    cTable = groupcounts( [X; XInsert], {varDef.Name, 'groupVar'} );
    
    % sort into standard order by adding numeric category
    cTable.level = zeros( height(cTable), 1 );
    for i = 1:height(cTable)
        cTable.level(i) = find( cTable.(varDef.Name)(i)==varDef.Range );
    end
    cTable = sortrows( cTable, 'level' );

    % extract the totals remembering that extras were added
    c = cTable.GroupCount-1;

    % convert to percentages
    cPct = 100*c./sum( c, 'all' );
    
    % reshape the array for a stacked bar chart
    cPct = reshape( cPct, nGroups, nCat )';
    
    % now plot the chart
    barObj = bar( cPct, 'Stacked', 'LineWidth', 1 );
    for i = 1:nGroups
        barObj(i).FaceColor = colourRGB( mod(i-1,nCol)+1, : );
    end

    xticklabels( varDef.Range );
    xlabel( attr.XLabel );  
    ylabel( 'Proportion (%)' );
        
    drawnow;
    
end


function plotPDF( Y, varDef, XFit, YTotal, isCompact )

    % set colour
    colour = [0 0.4470 0.7410];
    highlight = [0.4940 0.1840 0.5560];
    
    % set plot attributes
    attr = setPlotAttr( varDef );
    
    % transform X
    XPlot = attr.XFcn( XFit );
    
    % plot the probability density function
    % fill the area so reverse X and Y are needed
    Y = 1000*Y/YTotal;
    XRev = [ XPlot; flipud(XPlot) ];
    YRev= [ Y; -0.1*ones(length(Y),1) ];
    
    fill( XRev, YRev, colour, ...
                      'FaceAlpha', 0.2, ...
                      'EdgeColor', colour, ...
                      'LineWidth', 1 );
    
    % highlight peak position
    hold on;
    [ ~, peakID ] = max(Y);
    XPeak = XPlot( peakID );
    if isCompact
        
        plot( [XPeak, XPeak], [0, Y(peakID)], ...
                'Color', highlight, 'LineWidth', 1 );
        fontSize = 6;
        axWidth = 0.5;
        axYLabel = 'Density';
    
    else     
        plot( [XPeak, XPeak], [0, Y(peakID)], ...
                    'Color', highlight, 'LineWidth', 2 );
        peakLabelX = XPlot( peakID+5 );
        peakLabelY = 1.8;
        switch varDef.Type
            case 'integer'
                peakLabel = num2str( XPeak, '%1.0f' );
            case 'real'
                peakLabel = num2str( XPeak, '%1.2f' );
        end
        text( peakLabelX, peakLabelY, peakLabel, ...
                    'FontName', 'Arial', ...
                    'FontSize', 8 );
        fontSize = 8;
        axWidth = 1;
        axYLabel = 'Prob. Density \times10^3';
                
    end
                  
    % set limits
    xlim( attr.XLim );
    ylim( [0, 20] );
        
    % label axes
    xlabel( attr.XLabel );
    ylabel( axYLabel );
    
    set( gca, 'Box', false' );
    set( gca, 'TickDir', 'out' );
    set( gca, 'LineWidth', axWidth );
    set( gca, 'FontName', 'Arial' );
    set( gca, 'FontSize', fontSize );
    
    drawnow;

end


function plotLayeredPDF( X, varDef, YTotal )

    colourRGB = getColours;
    nCol = size( colourRGB, 1 );
    
    nPts = 201;

    XPlot = linspace( varDef.Range(1), varDef.Range(2), nPts )';
    XRev = [ XPlot; flipud(XPlot) ];
    XFitBorder = 0.25*(varDef.Range(2)-varDef.Range(1));

    Y0 = zeros( length(XPlot), 1 );
    
    groupLabels = unique( X.groupVar );
    nObs = size( X, 1 );

    for j = 1:length( groupLabels )
        % select fold data for ith variable
        grpRows = (X.groupVar==groupLabels(j));
        XSub = X.(varDef.Name)( grpRows );
        YProp = sum( grpRows )/nObs;

        % compute probability density function
        YPDF = fitdist( XSub , 'Kernel', ...
                            'Kernel', 'Normal', ...
                            'Width', 0.2*XFitBorder );                
        Y = pdf( YPDF, XPlot )*YProp/YTotal;

        % draw shaded area
        YRev= [ Y+Y0; flipud(Y0) ];
        fill( XRev, YRev, colourRGB( mod(j-1,nCol)+1,:), 'LineWidth', 1 );
        hold on;

        % set new baseline for next loop
        Y0 = Y0+Y;

    end
    hold off;
    
    % set limits
    xlim( varDef.Range );
    xlabel( varDef.Name );
    
    % label vertical axis
    ylabel( 'Probability Density' );
    ytickformat( '%1.3f' );
    
    drawnow;
        
end
     

function colourRGB = getColours

    % colours from SAS
    colourSAS = [ {'#B22222'}, {'#1E90FF'}, {'#696969'}, {'#00BFFF'}, ...
                    {'#FF1493'}, {'#9400D3'}, {'#00CED1'}, ...
                    {'#2F4F4F'}, {'#483D8B'}, {'#8FBC8F'} ];
    
    nColours = length( colourSAS );
    colourRGB = zeros( nColours, 3 );
    for i = 1:length( colourSAS )
        colourRGB( i, : ) = hex2rgb( colourSAS{i} );
    end 

end








