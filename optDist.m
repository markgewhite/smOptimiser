% ************************************************************************
% Script:   optDist.m
% Purpose:  Generate a plot of the distribution of optima
%
%
% ************************************************************************

clear;

method = 'smOptimiser';

optSetup.initMaxLoss = 100; 
optSetup.maxTries = 50;
optSetup.tolPSO = 0.01;
optSetup.tolFMin = 0.001;
optSetup.maxIter = 10000;
optSetup.verbose = 0;
optSetup.quasiRandom = false;

optSetup.nOuter = 20; 
optSetup.nInner = 40; 
optSetup.prcMaxLoss = 25;
optSetup.constrain = true;
optSetup.porousness = 0.5;

nRepeats = 10;
resolution = 0.1;
nInterTrace = fix( 0.25*optSetup.nOuter );


[ objFn, varDef ] = setupObjFn( 'MultiDimTest5' );

% obtain series of optima for the same problem

nParams = length( varDef );

optTrace = zeros( nRepeats*nInterTrace, nParams );
pRange = 0:resolution:180;
yPDF = zeros( length(pRange), nParams );

figure;
c = 0;
for i = 1:nRepeats

    switch method
        case 'Bayesopt'
            output = bayesopt( objFn, varDef, ...
                        'MaxObjectiveEvaluations', ...
                                optSetup.nOuter*optSetup.nInner/2, ...
                        'PlotFcn', [], ...
                        'Verbose', 0 );
            optTrace( i,: ) = table2array( output.XAtMinObjective );
        case 'smOptimiser'
            [ ~, ~, optOutput ] = smOptimiser( objFn, varDef, optSetup );
            optTrace( (i-1)*nInterTrace+1:i*nInterTrace, : ) ...
                        = optOutput.XTraceIndex( end-nInterTrace+1:end, :);
    end
    
    for j = 1:nParams
        pdist = fitdist( optTrace( 1:i*nInterTrace, j ) , ...
                            'Kernel', 'Kernel', 'Normal' );
        yPDF(:,j) = pdf( pdist, pRange );
        yPDF(:,j) = yPDF(:,j)./sum( yPDF(:,j) );
        
        plot( pRange, yPDF(:,j), 'LineWidth', 1 );
        hold on;
    end
    hold off;
    xlabel( 'Parameter' );
    ylabel( 'Probability Density' );
    drawnow;
    

end

disp(['Percentile MaxLoss = ' num2str(optSetup.prcMaxLoss)]);
disp(['Porousness = ' num2str(optSetup.porousness)]);
for j = 1:nParams
    [pks, locs ] = findpeaks( yPDF(:,j), 'MinPeakProminence', 0.0002 );
    disp(['Parameter ' num2str(j) ': ' ...
          ': Loc = ' num2str( pRange(locs) ) ...
          '; Peak = ' num2str( pks' ) ]);
end

