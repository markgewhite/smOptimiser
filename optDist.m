% ************************************************************************
% Script:   optDist.m
% Purpose:  Generate a plot of the distribution of optima
%
%
% ************************************************************************

clear;

method = 'smOptimiser';

optimizer.initMaxLoss = 100; 
optimizer.maxTries = 50;
optimizer.tolPSO = 0.01;
optimizer.tolFMin = 0.001;
optimizer.maxIter = 10000;
optimizer.quasiRandom = false;

nRepeats = 40;
optimizer.nFit = 10; 
optimizer.nSearch = 20; 
optimizer.prcMaxLoss = 25;
optimizer.constrain = true;
optimizer.porousness = 0.5;
optimizer.window = 2*optimizer.nSearch;
optimizer.sigmaLB = 0.2;
optimizer.sigmaUB = 1.0;
optimizer.verbose = 0;
optimizer.showPlots = true;

optimizer.showPlots = true;
optimizer.useSubPlots = true;


resolution = 0.1;
nInterTrace = fix( 0.5*optimizer.nFit );



[ objFn, varDef ] = setupObjFn( 'MultiDimTest5G' );

% obtain series of optima for the same problem

nParams = length( varDef );

optTrace = setupOptTable( varDef, nRepeats*nInterTrace );
optimum = setupOptTable( varDef, nRepeats );
peak = zeros( nRepeats, nParams );

c = 0;
groups = zeros( nRepeats*nInterTrace, 1 );
weights = zeros( nRepeats*nInterTrace, 1 );
outputFigures = [];
for i = 1:nRepeats

    switch method
        case 'Bayesopt'
            output = bayesopt( objFn, varDef, ...
                        'MaxObjectiveEvaluations', ...
                                optimizer.nOuter*optimizer.nInner/2, ...
                        'PlotFcn', [], ...
                        'Verbose', 0 );
            optTrace( (i-1)*nInterTrace+1:i*nInterTrace, : ) ...
                        = output.XAtMinObjective( end-nInterTrace+1:end, :);
                    
        case 'smOptimiser'
            [ ~, ~, optOutput, srchOutput ] = smOptimiser( ...
                                            objFn, varDef, optimizer );
            optTrace( (i-1)*nInterTrace+1:i*nInterTrace, : ) ...
                        = optOutput.XTrace( end-nInterTrace+1:end, :);
                    
    end
          
    [optimum(i,:), peak(i,:), outputFigures] = ...
                        plotOptDist( ...
                                optTrace(1:i*nInterTrace,:), ...
                                varDef, ...
                                optimizer, ...
                                outputFigures );
    
end



