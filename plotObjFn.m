% ************************************************************************
% Function: plotObjFn
% Purpose:  Plot the objective function at a given position in
%           parameter space varying one, two or three parameters.
%
%
% Parameters:
%
%           XTrace:             table logging the optima recorded by
%                               smOptimiser
%
%
%           figRef:             figure handle (optional)
%
%
% Output:
%           figRef:          figure handles
%
% ************************************************************************

function figRef = plotObjFn( XOptimum, models, setup, ...
                             activeVar, plotVar, figRef )

        
% defaults
if ~isfield( setup, 'overlapFactor' )
    setup.overlapFactor = 0.75; % default
end

if ~isfield( setup, 'contourStep' )
    setup.contourStep = 0.2; % default
end

if ~isfield( setup, 'contourType' )
    setup.contourType = 'Lines'; % default
end

if ~isfield( setup, 'transform' )
    setup.transform = true; % default
end

if ~isfield( setup, 'layout' )
    setup.layout = 'square'; % default
end

if isfield( setup, 'useSubPlots' )
    if ~islogical( setup.showPlots )
        error('Options: useSubPlots must be Boolean.');
    end
else
    setup.useSubPlots = true; % default
end

% switch to the requested optimizable variables
varDef = switchActiveVarDef( setup.varDef, activeVar );

% add extra fields if transformation required
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

% select the appropriate XTrace fields to match
XOptimum = retainActiveVar( XOptimum, varDef );

% shortlist to only active variables
varDef = varDef( activeVarDef(varDef) );

% back-transform the XOptimum table into indices
XOptimum = varDefIndex( XOptimum, varDef );
nVar = size( XOptimum, 2 );

if nVar ~= length( varDef )
    error('The number optimizable variables (varDef) does not match the XOptimum.');
end



% setup the layout of the plots
nPlots = length( plotVar );
switch setup.layout
    case 'square'
        [ plotRows, plotCols ] = sqdim( nPlots );
    case 'vertical'
        plotRows = nPlots;
        plotCols = 1;
    case 'horizontal'
        plotRows = 1;
        plotCols = nPlots;
end

if isempty( figRef )
    % setup figures - one time only
    if setup.useSubPlots
        figRef = figure;
    else
        figRef = gobjects( nPlots, 1 );
        for i = 1:nPlots
            figRef(i) = figure;
        end   
    end
end

%  other initialisation
nModels = length( models );

% optimal Y predictions and confidence interval
YHatOpt = zeros( 1, nModels );
YHatOptCI = zeros( 1, nModels );

YNoise = zeros( 1, nModels );

% plot the objective function for each variable
for i = 1:nPlots
    
    % set the parameter than will be varied (others held constant)
    k = plotVar(i);
    
    % get a mesh of X points in original and transformed scales
    [ XFit, XPlot, XLim ] = fineMesh( varDef(k) );
    nPts = length( XFit );
    
    % create the full predictor table (index representation)
    X = repmat( XOptimum, nPts, 1 );

    % replace the i-th column with the XFit mesh
    X(:,k) = XFit;
    
    % init Y predictions for variation in X in one dimension across models
    YHat = zeros( nPts, nModels );
    YHatCI = zeros( nPts, nModels );
    
    % predict the objective function using all models
    for j = 1:nModels
        [ YHat(:,j), YHatCI(:,j) ] = predict( models{j}, X );
        [ YHatOpt(j), YHatOptCI(j) ] = predict( models{j}, XOptimum );
        YNoise(1,j) = models{j}.Sigma;
    end
    
    % aggregate predictions based on the median to avoid outlier influence
    YHatBag = mean( YHat, 2 );
    YHatCIBag = sqrt( sum( YHatCI.^2, 2 ) )/nModels;
    YHatOptBag = mean( YHatOpt );
    YHatOptCIBag = sqrt( sum( YHatOptCI.^2 ) )/nModels;
    YNoiseBag = sqrt( sum( YNoise.^2 ) )/nModels;
    
    % prepare the figure or subplot
    if setup.useSubPlots
        figure( figRef );
        subplot( plotRows, plotCols, i );
    else
        figure( figRef(i) );
    end
    
    % plot the surrogate function
    plotFn( XPlot, YHatBag, YHatCIBag, YNoiseBag, varDef(k) );

end


end




function [ XFit, XPlot, limPlot ] = fineMesh( varDef )

% create fine mesh for a given variable
% for the original ranges
% and for the index representation
nMesh = 201;

attr = setPlotAttr( varDef );

% limFit = varDef.Range; % round( attr.XLim );

if strcmp( varDef.Type, 'categorical' )

    limFit = [ 1 length(varDef.Range) ];
    limPlot = limFit;
    XFit = twice( limFit(1):limFit(2), 0 )';
    
    XPlot = twice( limFit(1):limFit(2), 0.5 )';

else

    limFit = varDef.Range;
    limPlot = attr.XFcn( limFit );

    hFit = ( limFit(2)-limFit(1) )/(nMesh-1);
    XFit = (limFit(1):hFit:limFit(2))';
    
    hPlot = ( limPlot(2)-limPlot(1) )/(nMesh-1);
    XPlot = (limPlot(1):hPlot:limPlot(2))';

end

end



function pRef = plotFn( X, Y, YCI, YN, varDef )
                  
% set colour
colour = [0 0.4470 0.7410];
                    
% prepare the wrap-around X and Y points
XRev = [ X; flipud(X) ];
YCIRev = [ Y-YCI; flipud(Y+YCI) ];
YNRev = [ Y-YN; flipud(Y+YN) ];

% plot the confidence interval
pRef(2) = fill(  XRev, ...
                 YCIRev, ...
                 colour, ...
                 'EdgeColor', 'none', ...
                 'LineWidth', 1, ...
                 'FaceAlpha', 0.2, ...
                 'DisplayName', 'Confidence Limits' );

hold on;

% plot the noise
pRef(3) = fill(  XRev, ...
                 YNRev, ...
                 colour, ...
                 'EdgeColor', 'none', ...
                 'FaceAlpha', 0.2, ...
                 'DisplayName', 'Noise' );

         
% plot the bagged prediction
pRef(1) = plot(  X, ...
                 Y, ...
                 'Color', colour, ...
                 'LineWidth', 1, ...
                 'DisplayName', 'Surrogate Prediction' );
         
         
hold off;

% set the axes' limits and tick values
ylim( [3, 4.5] );
ytickformat('%1.1f')
ylabel( 'SM Loss (W\cdotkg^{-1})' );

ax = gca;

if strcmp( varDef.Type, 'categorical' )
    xlim( [varDef.Limits(1)+0.01, varDef.Limits(2)-0.01] );
    XTickNum = unique( round(X) );
    ax.XTick = XTickNum;
    xticklabels( varDef.Range );
else
    xlim( varDef.Limits );
end

xlabel( varDef.Descr );

ax.Box = false;
ax.TickDir = 'out';
ax.LineWidth = 1;
ax.FontName = 'Arial';
ax.FontSize = 8;

drawnow;
         
end


 

