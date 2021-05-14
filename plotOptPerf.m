% ************************************************************************
% Function: plotOptPerf
% Purpose:  Plot the traces of the optimisation performance.
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

function figRef = plotOptPerf( search, opt, figRef )

nSearch = length( search.objFnTime );
nFit = size( opt.fitTime, 1 );
nStep = nSearch / nFit;

nObs = find( opt.fitTime==0, 1 )-1;
if isempty( nObs )
    nObs = length( opt.fitTime );
end

if isempty( figRef )
    figRef = figure;
else
    figure( figRef );
end

% plot objective execution time
subplot( 2, 2, 1 );
plot( search.objFnTime( 1:nObs*nStep, 1 ), 'LineWidth', 2 );
hold on;

% plot fitting execution time
plot( nStep*(1:nObs), opt.fitTime( 1:nObs ), 'LineWidth', 2 );

% plot PSO execution time
plot( nStep*(1:nObs), opt.psoTime( 1:nObs ), 'LineWidth', 2 );

hold off;
xlim( [0, nSearch] );
xlabel( 'Iterations' );
ylabel( 'Execution Time' );

% plot model noise
subplot( 2, 2, 2 );
plot( nStep*(1:nObs), opt.noise( 1:nObs ), 'LineWidth', 2 );
hold on;

% plot model confidence level
plot( nStep*(1:nObs), opt.modelSD( 1:nObs ), 'LineWidth', 2 );

hold off;
xlim( [0, nSearch] );
xlabel( 'Iterations' );
ylabel( 'Uncertainty' );


% plot objective function output
subplot( 2, 2, 3 );
plot( search.YTrace( 1:nObs*nStep ), 'x' );
hold on;

% plot surrogate model prediction
plot( nStep*(1:nObs), opt.EstYTrace( 1:nObs ), 'LineWidth', 2 );

hold off;
xlim( [0, nSearch] );

yMax = ceil( prctile( search.YTrace(1:nObs*nStep), 80) );
yMin = floor( prctile( search.YTrace(1:nObs*nStep), 0) );
ylim( [yMin, yMax] );
xlabel( 'Iterations' );
ylabel( 'Function Value' );   


drawnow;

end
        

