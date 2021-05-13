% ************************************************************************
% Function: identifyOptimum
% Purpose:  Identifies the optimum  from an optimisation trace.
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
%           opt                 options
%               .nLast:         number of observations to include from
%                               the end of the each trace grouping;
%                               if 0 then include all observations
%                               (default = 0)
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
                identifyOptimum( XTrace, varDef, opt, figRef, group )
            
% parse arguments
if nargin < 2
    error('Insufficient arguments');
end

if nargin < 3
	opt.notSpecified = true;
end


% set option defaults where required
if isfield( opt, 'nLast' )
    if opt.nLast <= 0 || isinteger( opt.nLast )
        error('Options: nLast must be a positive integer.');
    end
else
    opt.nLast = 0; % default
end

if isfield( opt, 'showPlots' )
    if ~islogical( opt.showPlots )
        error('Options: showPlots must be Boolean.');
    end
else
    opt.showPlots = false; % default
end

if isfield( opt, 'useGroups' )
    if ~islogical( opt.showPlots )
        error('Options: useGroups must be Boolean.');
    end
else
    opt.useGroups = false; % default
end

% get dimensions
[nObs, nVar] = size( XTrace );

if opt.showPlots && isempty( figRef )
    % setup figures
    if opt.useSubPlots
        figure;
        [ plotRows, plotCols ] = sqdim( nVar );
        for i = 1:nVar
            figRef(i) = subplot( plotRows, plotCols, i );
        end
    else
        figRef = gobjects( nVar, 1 );
        for i = 1:nVar
            figRef(i) = figure;
        end   
    end
end

if nargin < 5
    group = zeros( nObs, 1 ); % default
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
if opt.useSubPlots

end

for i = 1:nVar
    
    varName = XTrace.Properties.VariableNames{i};
    
    if strcmpi( varDef(i).Type, 'categorical' )
        
        % categorical variable
              
        % count the frequencies for the ith variable
        cTable = groupcounts( XTrace, i );
        
        % identify and record highest frequency
        [ topFreq, topLoc ] = max( cTable.GroupCount );
        XOptimum.(varName)(1) = cTable.(varName)(topLoc);
        XFreq(1,i) = topFreq/nObs;        
    
        if opt.showPlots
            if isa( figRef(i), 'matlab.ui.Figure' )
                figure( figRef(i) );
            else
                subplot( figRef(i) );
            end
            plotFreq( XTrace, varDef(i) );
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
                               'Width', 0.1*XFitBorder );                
        YAll = pdf( YPDF, XFit );
        YTotal = sum( YAll );

        % identify and record highest frequency
        [ topFreq, topLoc ] = max( YAll );
        XOptimum.(varName)(1) = XFit( topLoc );
        XFreq(1,i) = topFreq/YTotal;        
    
        if opt.showPlots
            if isa( figRef(i), 'matlab.ui.Figure' )
                figure( figRef(i) );
            else
                subplot( figRef(i) );
            end
            if nGroups == 1
                plotPDF( YAll, varDef(i), ...
                            XFit, YTotal );
            else
                plotLayeredPDF( XTrace, varDef(i), ...
                            XFit, YTotal );
            end
        end
        
        
    end
        
end

XOptimum = XOptimum( :, 1:end-1 );

end


function plotFreq( X, varDef )
 
    colourRGB = getColours;

    nGroups = length( unique(X.groupVar) );

    % count the number of models for ith var, grouped by fold
    cTable = groupcounts( X, {varDef.Name, 'groupVar'} );

    % extract the totals
    c = cTable.GroupCount;

    % convert to percentages
    cPct = 100*c./sum( c, 'all' );
    
    % first add any missing values from full range
    varMiss = setdiff( categorical(varDef.Range), cTable.(varDef.Name) );
    if ~isempty( varMiss )
        varMissID = find( varMiss==varDef.Range );
        for i = varMissID(1):varMissID(end)
            if i < length(varDef.Range)
                % shift rows down
                cPct( i+1:end+1, : ) = cPct( i:end, : );
            end
            % insert blank row
            cPct( i, : ) = zeros( 1, nGroups );
        end
    end
    
    % reshape the array for a stacked bar chart
    c = reshape( c, nGroups, length(c)/nGroups )';
    
    % now plot the chart
    barObj = bar( cPct, 'Stacked', 'LineWidth', 1.5 );
    nColours = min( length(barObj), length(colourRGB) );
    for i = 1:nColours
        barObj(i).FaceColor = colourRGB( i, : );
    end

    xticklabels( varDef.Range );
    ylabel( 'Proportion (%)' );
        
    drawnow;
    
end


function plotPDF( Y, varDef, XFit, YTotal )
    
    % plot the probability density function
    Y = Y/YTotal;
    plot( XFit, Y, 'k-', 'LineWidth', 1.5 );
    
    % set limits
    xlim( varDef.Range );
    xlabel( varDef.Name );
        
    % label vertical axis
    ylabel( 'Probability Density' );
    ytickformat( '%1.2f' );
    
    drawnow;

end


function plotLayeredPDF( X, varDef, XFit, YTotal )

    colourRGB = getColours;
    nPts = length( XFit );

    XPlot = linspace( varDef.Range(1), varDef.Range(2), nPts )';
    XRev = [ XPlot; flipud(XPlot) ];
    XFitBorder = 0.25*(varDef.Range(2)-varDef.Range(1));

    Y0 = zeros( length(XPlot), 1 );
    
    groupLabels = unique( X.groupVar );
    nObs = size( X, 1 );

    hold on;
    for j = 1:length( groupLabels )
        % select fold data for ith variable
        grpRows = (X.groupVar==groupLabels(j));
        XSub = X.(varDef.Name)( grpRows );
        YProp = sum( grpRows )/nObs;

        % compute probability density function
        YPDF = fitdist( XSub , 'Kernel', ...
                            'Kernel', 'Normal', ...
                            'Width', 0.1*XFitBorder );                
        Y = pdf( YPDF, XFit )*YProp/YTotal;

        % draw shaded area
        YRev= [ Y+Y0; flipud(Y0) ];            
        fill( XRev, YRev, colourRGB(j,:), 'LineWidth', 1 );

        % set new baseline for next loop
        Y0 = Y0+Y;

    end
    hold off;
    
    % set limits
    xlim( varDef.Range );
    xlabel( varDef.Name );
    
    % label vertical axis
    ylabel( 'Probability Density' );
    ytickformat( '%1.2f' );
    
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
