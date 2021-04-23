% ************************************************************************
% Script:   optDist.m
% Purpose:  Generate a plot of the distribution of optima
%
%
% ************************************************************************

clear;

method = 'smOptimiser';

optSetup.initMaxLoss = 100; 
optSetup.maxTries = 20;
optSetup.tolPSO = 0.01;
optSetup.tolFMin = 0.001;
optSetup.maxIter = 10000;
optSetup.verbose = 0;

optSetup.nOuter = 5; 
optSetup.nInner = 5; 
optSetup.prcMaxLoss = 100;
optSetup.constrain = 1; 

[ objFn, varDef ] = setupObjFn( 'MultiDimTest' );

% obtain series of optima for the same problem

nParams = length( varDef );

optTrace = zeros( 100, nParams );
pRange = 0:180;

figure;

for i = 1:100*2

    switch method
        case 'Bayesopt'
            output = bayesopt( objFn, varDef, ...
                        'MaxObjectiveEvaluations', ...
                                optSetup.nOuter*optSetup.nInner/2, ...
                        'PlotFcn', [], ...
                        'Verbose', 0 );
            optTrace( i,: ) = table2array( output.XAtMinObjective );
        case 'smOptimiser'
            optTrace( i,: ) = smOptimiser( objFn, varDef, optSetup );
    end
    
    for j = 1:nParams
        pdist = fitdist( optTrace( 1:i, j ) , 'Kernel', 'Kernel', 'Normal' );
        yPDF = pdf( pdist, pRange );
        yPDF = yPDF./sum(yPDF);
        
        plot( pRange, yPDF, 'LineWidth', 1 );
        hold on;
    end
    hold off;
    xlabel( 'Parameter' );
    ylabel( 'Probability Density' );
    drawnow;
    

end
