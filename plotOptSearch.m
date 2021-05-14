% ************************************************************************
% Function: plotOptSearch
% Purpose:  Plot the traces of the optimisation search along with
%           the trace of the estimated optimum trace.
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
%           figRef:             figure handle (optional)
%
%
% Output:
%           figRef:          figure handles
%
% ************************************************************************

function figRef = plotOptSearch( XSearch, XOptima, varDef, figRef )


[ nSearch, nVar ] = size( XSearch );
nOptima = size( XOptima, 1 );
nStep = nSearch / nOptima;

nObs = find( sum( XOptima, 2 )==0, 1 )-1;

varDef = varDef( activeVarDef(varDef) );

if isempty( figRef )
    figRef = figure;
else
    figure( figRef );
end

[ plotRows, plotCols ] = sqdim( nVar );


for i = 1:nVar
    
    subplot( plotRows, plotCols, i );
    
    % plot the search points
    plot( XSearch( 1:nObs*nStep, i ), 'x' );
    
    hold on;
    
    % plot the optimum line
    plot( nStep*(1:nObs), XOptima( 1:nObs, i ), 'LineWidth', 2 );
    
    hold off;
    
    xlim( [0, nSearch] );
    xlabel( 'Iterations' );
    
    ylabel( varDef(i).Name );
    
end

drawnow;

end
        

