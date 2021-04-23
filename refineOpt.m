% ************************************************************************
% Script:   refineOpt.m
% Purpose:  Refine (optimise) smOptimiser to maximise its effectiveness
%
%
% ************************************************************************

clear;

optimiser = @testOptimiser; % or @testBayesopt

% parameter definitions

optDef(1) = optimizableVariable( 'nInner', ...
        [2 50], ...
        'Type', 'integer', 'Transform', 'log', 'Optimize', false );
    
optDef(2) = optimizableVariable( 'prcMaxLoss', ...
        [10 100], ...
        'Type', 'integer', 'Optimize', false );
    
optDef(3) = optimizableVariable( 'constrain', ...
        [0 1], ...
        'Type', 'integer', 'Optimize', false );
    
optDef(4) = optimizableVariable( 'nOuter', ...
        [1 15], ...
        'Type', 'integer', 'Optimize', true );
    
    
bayesopt( optimiser, optDef, ...
                    'MaxObjectiveEvaluations', 50, ...
                    'ExplorationRatio', 10 );

    
        
        
function err = testBayesopt( v )

[ objFn, varDef ] = setupObjFn( 'MultiDimTest' );

output = bayesopt( objFn, varDef, ...
            'MaxObjectiveEvaluations', v.nOuter*5, ...
            'PlotFcn', [], ...
            'Verbose', 0 );

optimum = table2array( output.XAtMinObjective );
        
err = sqrt( sum( optimum-104.5987 ).^2 );

end


function err = testOptimiser( v )

optSetup.initMaxLoss = 100; 
optSetup.maxTries = 20;
optSetup.tolPSO = 0.01;
optSetup.tolFMin = 0.001;
optSetup.maxIter = 10000;
optSetup.verbose = 0;

optSetup.nOuter = v.nOuter; % fix( 100/v.nInner);
optSetup.nInner = 120; % v.nInner;
optSetup.prcMaxLoss = 100;
optSetup.constrain = 1; % v.constrain;

[ objFn, varDef ] = setupObjFn( 'MultiDimTest' );

optimum = smOptimiser( objFn, varDef, optSetup );

err = sqrt( sum( optimum-104.5987 ).^2 );

end


