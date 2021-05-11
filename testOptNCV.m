% ************************************************************************
% Script:   testOptNCV.m
% Purpose:  Tested the nested cross validation optimiser
%
%
% ************************************************************************

clear;

nInnerLoop = 10;
nOuterLoop = 10;

kInnerFolds = 2;
kOuterFolds = 10;


nObs = 100;

options.optimizer.initMaxLoss = 100; 
options.optimizer.maxTries = 50;
options.optimizer.tolPSO = 0.01;
options.optimizer.tolFMin = 0.001;
options.optimizer.maxIter = 10000;
options.optimizer.verbose = 0;
options.optimizer.quasiRandom = false;

options.optimizer.nFit = 40; 
options.optimizer.nSearch = 10; 
options.optimizer.prcMaxLoss = 25;
options.optimizer.constrain = true;
options.optimizer.porousness = 0.5;

options.optimizer.showPlots = true;
options.optimizer.useSubPlots = true;

options.optimizer.nRepeats = 2;
options.optimizer.nInterTrace = fix( 0.25*options.optimizer.nFit );


partitioning.doControlRandomisation = false;
partitioning.randomSeed = 0;
partitioning.iterations = 1;
partitioning.kFolds = 10;
partitioning.split = [ 0.70, 0.0, 0.30 ];
partitioning.trainSubset = 'Full';
partitioning.testSubset = 'Full';

options.part.inner = partitioning;
options.part.inner.iterations = nInnerLoop;
options.part.inner.kFolds = kInnerFolds;

options.part.select = partitioning;
options.part.select.method = 'KFoldSubject';
options.part.select.iterations = nOuterLoop;

options.part.outer = partitioning;
options.part.outer.iterations = nOuterLoop;




[ objFn, varDef ] = setupObjFn( 'Averager' );

data.outcome = 10*rand( nObs, 1 ).^2;
data.subject = (1:nObs)';
data.test.extras = rand( nObs, 1 );


[ optima, valRMSE ] = smOptimiserNCV( objFn, varDef, ...
                          options.optimizer, ...
                          data, ...
                          options );
                      



