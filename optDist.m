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
optimizer.verbose = 0;
optimizer.quasiRandom = false;

optimizer.nFit = 40; 
optimizer.nSearch = 10; 
optimizer.prcMaxLoss = 25;
optimizer.constrain = true;
optimizer.porousness = 0.5;

optimizer.showPlots = true;
optimizer.useSubPlots = true;

nRepeats = 10;
resolution = 0.1;
nInterTrace = fix( 0.25*optimizer.nOuter );



[ objFn, varDef ] = setupObjFn( 'MultiDimTest5' );

% obtain series of optima for the same problem

nParams = length( varDef );

optTrace = setupOptTable( varDef, nRepeats*nInterTrace );
optimum = setupOptTable( varDef, nRepeats );

c = 0;
groups = zeros( nRepeats*nInterTrace, 1 );
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
            [ ~, ~, optOutput ] = smOptimiser( objFn, varDef, optimizer );
            optTrace( (i-1)*nInterTrace+1:i*nInterTrace, : ) ...
                        = optOutput.XTrace( end-nInterTrace+1:end, :);
                    
    end
       
    [optimum(i,:), ~, outputFigures] = ...
        identifyOptimum(    optTrace(1:i*nInterTrace,:), ...
                            varDef, optimizer, outputFigures );
    
end



