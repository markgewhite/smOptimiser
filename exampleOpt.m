% ************************************************************************
% Script:   exampleOpt.m
% Purpose:  Demonstrates using smOptimiser to find the global optimum of
%           an example function. Shows how to setup the relevant variables
%
%
% ************************************************************************

clear;

method = 'smOptimiser';

% optimiser setup

optSetup.nFit = 20;
optSetup.nSearch = 20;
optSetup.initMaxLoss = 100; 
optSetup.maxTries = 100;
optSetup.tolPSO = 0.01;
optSetup.tolFMin = 0.001;
optSetup.maxIter = 10000;
optSetup.prcMaxLoss = 50;


% parameter definitions


[ objFn, varDef ] = setupObjFn( 'Example' );


switch method
    
    case 'Bayesopt'
        % baseline using Bayesian optimiser
        optimum0 = bayesopt( objFn, varDef, ...
                            'MaxObjectiveEvaluations', ...
                            optSetup.nOuter*optSetup.nInner );

    case 'smOptimiser'
        % surrogate model optimiser
        [optimum, model, opt, search] = ...
                            smOptimiser( objFn, varDef, optSetup );

end
