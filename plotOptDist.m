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
                plotOptDist( XTrace, varDef, setup, figRef, group, weight )
            
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

% get dimensions
[nObs, nVar] = size( XTrace );


% extract only the active variables
varDef = varDef( activeVarDef(varDef) );
if nVar ~= length( varDef )
    error('The number optimizable variables (varDef) does not match the XTrace');
end

if setup.showPlots
    [ plotRows, plotCols ] = sqdim( nVar );
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

if nargin < 6
    weight = ones( nObs, 1 ); %default
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
if setup.useSubPlots

end


for i = 1:nVar
    
    varName = XTrace.Properties.VariableNames{i};
    
    if strcmpi( varDef(i).Type, 'categorical' )
        
        % categorical variable
        
        % applies weights
        
              
        % count the frequencies for the ith variable
        cTable = groupcounts( XTrace, i );
        
        % identify and record highest frequency
        [ topFreq, topLoc ] = max( cTable.GroupCount );
        XOptimum.(varName)(1) = cTable.(varName)(topLoc);
        XFreq(1,i) = topFreq/nObs;        
    
        if setup.showPlots
            if setup.useSubPlots
                figure( figRef );
                subplot( plotRows, plotCols, i );
            else
                figure( figRef(i) );
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
                               'Width', 0.1*XFitBorder, ...
                               'Frequency', weight );                
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
                subplot( plotRows, plotCols, i );
            else
                figure( figRef(i) );
            end
            if nGroups == 1
                plotPDF( YAll, varDef(i), XFit, YTotal );
            else
                plotLayeredPDF( XTrace, varDef(i), YTotal );
            end
        end
        
        
    end
        
end

XOptimum = XOptimum( :, 1:end-1 );
XFreq = XFreq( :, 1:end-1 );

end



function plotFreq( X, varDef )
 
    colourRGB = getColours;
    nCol = size( colourRGB, 1 );
    
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
    ytickformat( '%1.3f' );
    
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
                            'Width', 0.1*XFitBorder );                
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
