% ************************************************************************
% Function: smOptimiser
% Purpose:  Finds the global optimum of an observed noisy objective 
%           function. A Bayesian surrogate model is constructed from 
%           observations of a specified function. A random search makes
%           those observations, the extent of which is progressively
%           constrained. The observations must fall within a region
%           parameter space where the emerging surrogate model estimates
%           the function to be below a specified threshold, which is 
%           gradually lowered. Through multiple observations the Bayesian 
%           surrogate model becomes more representative of the long-run 
%           behaviour of the objective function. After a specified number 
%           of observations, the Particle Swarm global optimiser finds the
%           global optimum. 
%
%
% Parameters:
%
%           objFn:              objective function
%
%           paramDef:           objective function's parameter definitions
%                               based on the same format: optimizervariable
%                               used by bayesopt
%
%           setup:              optimiser's setup
%               .nFit:          number of model fits (default = 20)
%               .nSearch:       number of observations before next fit
%                               optimum (default = 20)
%               .maxTries:      maximum number of times to try a random
%                               choice of parameter values that satisfies
%                               the constraint (default = 1000)
%               .porousness:    factor governing how 'porous' the maxLoss
%                               is - the more porous the more likely the
%                               search will try a point that is above
%                               the limit in case that estimate is wrong
%                               (optional; default = 0.5)
%               .window:        number of recent observations to include
%                               when determining the current typical
%                               range of the objective function
%                               (optional; default = 2*nSearch)
%               .cap:           cap on the objective function's value
%                               in case it sometimes returns extreme values
%                               - the cap is intended to prevent unstable
%                               behaviour of the surrogate model
%                               (optional; default = infinity [ie no cap])
%               .sigmaLB:       noise lower bound for the surrogate model
%                               (optional; default = 0)
%               .sigmaUB:       noise upper bound for the surrogate model
%                               (optional; default = Inf0)
%               .verbose:       output level: (optional; default = 1)
%                                   0 = no output; 1 = commandline output
%               .quasiRandom:   whether to use quasi-random search instead
%                               of a pseudo-random one 
%                               (optional; default = false)
%               .tolPSO:        function minimum tolerance for PSO
%                               (optional; default = 0.001)
%               .maxIterPSO:     maximum number of PSO search iterations
%                               (optional; default = 1000)
%
%           data:               data if required for the objective function
%                               (optional)
%
%           options:            options structure if required for the
%                               objective function (optional)
%
% Output:
%           optimum:            optimal parameters for the objective function
%           model:              Bayesian surrogate model structure
%           opt:                optimisation record structure (PSO)
%           srch:               random search record sructure
%
% ************************************************************************

function [ optimum, model, opt, srch ] = ...
                    smOptimiser( objFn, paramDef, setup, data, options )


% parse arguments
if nargin < 3
    error('Minimum of three arguments not specified.');
end

if isfield( setup, 'nFit' )
    if setup.nFit <= 0 || isinteger( setup.nFit )
        error('Setup: nFit must be a positive integer.');
    end
else
   setup.nFit = 100; % default
end

if isfield( setup, 'nSearch' )
    if setup.nSearch <= 0 || isinteger( setup.nSearch )
        error('Setup: nSearch must be a positive integer.');
    end
else
   setup.nSearch = 20; % default
end

if isfield( setup, 'maxTries' )
    if setup.maxTries <= 0 || isinteger( setup.maxTries )
        error('Setup: maxTries must be a positive integer.');
    end
else
   setup.maxTies = 1000; % default
end

if ~isfield( setup, 'tolPSO' )
   setup.tolPSO = 0.001; % default
end

if ~isfield( setup, 'maxIterPSO' )
   setup.maxIterPSO = 1000; % default
end

if ~isfield( setup, 'porousness' )
   setup.porousness = 0.5; % default
end

if ~isfield( setup, 'window' )
   setup.window = setup.nSearch*2; % default
end

if ~isfield( setup, 'verbose' )
   setup.verbose = 1; % default
end

if ~isfield( setup, 'constrain' )
   setup.constrain = 1; % default
end

if ~isfield( setup, 'quasiRandom' )
   setup.quasiRandom = false; % default
end

if ~isfield( setup, 'cap' )
   setup.cap = Inf; % default
end

if ~isfield( setup, 'sigmaLB' )
   setup.sigmaLB = 0; % default
end

if ~isfield( setup, 'sigmaUB' )
   setup.sigmaUB = Inf; % default
end


setup.noObjOptions = (nargin < 5);
setup.noObjData = (nargin < 4);

if setup.verbose > 0
    setup.useSubPlots = true;
    figDist = [];
    figSearch = [];
    figPerf = [];
end

% identify only the active variables requiring optimisation
paramDef = paramDef( activeVarDef(paramDef) );
nParams = length( paramDef );
   

% add extra definitions (for speed)
paramInfo.name = cell( 1, nParams );
paramInfo.varType = cell( 1, nParams );
paramInfo.isCat = false( 1, nParams );
paramInfo.doRounding = false( 1, nParams );
paramInfo.nLevels = zeros( 1, nParams );
paramInfo.psoLB = zeros( 1, nParams );
paramInfo.psoUB = zeros( 1, nParams );
for i = 1:nParams

    v = setup.activeVar(i);
    paramInfo.name{i} = paramDef(i).Name;
    switch paramDef(i).Type
        
        case 'categorical'
            paramInfo.varType{i} = 'categorical';
            paramInfo.isCat(i) = true;
            paramInfo.doRounding(i) = true;
            paramInfo.nLevels(i) = length( paramDef(i).Range );
            paramInfo.psoLB(i) = 0.5;
            paramInfo.psoUB(i) = paramInfo.nLevels(i)+0.49;

        case 'integer'
            paramInfo.varType{i} = 'double';
            paramInfo.isCat(i) = false;
            paramInfo.doRounding(i) = true;
            paramInfo.nLevels(i) = paramDef(i).Range(2)- ...
                                        paramDef(i).Range(1)+1;
            paramInfo.psoLB(i) = setup.bounds{v}(1);
            paramInfo.psoUB(i) = setup.bounds{v}(2);
            
        case 'real'
            paramInfo.varType{i} = 'double';
            paramInfo.isCat(i) = false;
            paramInfo.doRounding(i) = false;
            paramInfo.psoLB(i) = setup.bounds{v}(1);
            paramInfo.psoUB(i) = setup.bounds{v}(2);
            
    end

end                       

% initialisation
srch.XTrace = table( ...
                'Size', [setup.nFit*setup.nSearch, nParams], ...
                'VariableTypes', paramInfo.varType, ...
                'VariableNames', paramInfo.name );
srch.XTraceIndex = zeros( setup.nFit*setup.nSearch, nParams );
srch.YTrace = zeros( setup.nFit*setup.nSearch, 1 );
srch.objFnTimeTrace = zeros( setup.nFit*setup.nSearch, 1 );
srch.delta = zeros( setup.nFit*setup.nSearch, 1 );
srch.nTries = zeros( setup.nFit*setup.nSearch, 1 );

opt.XTrace = table( ...
                'Size', [setup.nFit, nParams], ...
                'VariableTypes', paramInfo.varType, ...
                'VariableNames', paramInfo.name );
opt.XTraceIndex = zeros( setup.nFit, nParams );
opt.EstYTrace = zeros( setup.nFit, 1 );
opt.EstYCITrace = zeros( setup.nFit, 1 );
opt.ObsYTrace = zeros( setup.nFit, 1 );
opt.NoiseTrace = zeros( setup.nFit, 1 );
opt.maxLossTrace = zeros( setup.nFit, 1 );

opt.fitTimeTrace = zeros( setup.nFit, 1 );
opt.psoTimeTrace = zeros( setup.nFit, 1 );

model = [];
optionsPSO = optimoptions('particleswarm', ...
                            'Display', 'None', ...
                            'FunctionTolerance', setup.tolPSO, ...
                            'MaxIterations', setup.maxIter );
optimumR = zeros( 1, nParams);

if setup.quasiRandom
    % generate a quasi-random sequence with required dimensions
    rndSeq = sobolset( nParams, 'Skip', 1000, 'Leap', 0);
    rndSeq = scramble( rndSeq, 'MatousekAffineOwen' );
    rndQ = qrandstream( rndSeq );
else
    rndQ = 0;
end

opt.maxLossTrace(1) = Inf;
c = 0; 
w = setup.window; 

for k = 1:setup.nFit

    for j = 1:setup.nSearch
        
        obs = NaN;
        secondTry = false;
        while isnan( obs )
        
            % determine the random parameters
            if j > 1 || k == 1 || secondTry
                % random search
                [ params, indices, delta, nTries ] = randomParams( ...
                                    paramDef, paramInfo, model, ...
                                    srch.YTrace( max(c-w+1,1):c ), ...
                                    opt.maxLossTrace( max(k-1,1) ), ...
                                    setup.porousness, ...
                                    setup.maxTries, rndQ );     
            else
                % parameters at estimated optimum
                params = opt.XTrace( k-1, : );
                indices = opt.XTraceIndex( k-1, : );

            end

            % run the model for this set of parameters
            tic;
            if setup.noObjData && setup.noObjOptions
                obs = objFn( params );
            elseif setup.noObjOptions
                obs = objFn( params, data );
            else
                obs = objFn( params, data, options );
            end
            secondTry = true;
            
        end

        % record observation
        c = c+1;
        srch.objFnTimeTrace( c ) = toc;
        srch.YTrace( c ) = min( obs, setup.cap );
        srch.XTrace( c, : ) = params;
        srch.XTraceIndex( c, : ) = indices;
        srch.delta( c ) = delta;
        srch.nTries( c ) = nTries;
        if j == 1 && k > 1
            % record observation to compare with estimated value
            opt.ObsYTrace( k-1 ) = obs;
        end
        
    end

    
    
    % fit the GP model to the observations
    tic;
    model = fitSurrogateModel(  model, paramInfo, ...
                                srch.XTraceIndex( 1:c, : ), ...
                                srch.YTrace( 1:c ), ...
                                setup.sigmaLB );
                            
    if model.Sigma > setup.sigmaUB
        % refit enforcing a constant sigma so that outliers are not ignored
        % note: lower bound limit is already enforced in fitrgp
        fixedSigma = min( model.Sigma, setup.sigmaUB );
        model = fitSurrogateModel(  model, paramInfo, ...
                                    srch.XTraceIndex( 1:c, : ), ...
                                    srch.YTrace( 1:c ), ...
                                    setup.sigmaLB, ...
                                    fixedSigma );
    end
    
    opt.NoiseTrace( k ) = model.Sigma;
    opt.fitTimeTrace( k ) = toc;
    
    
    % find the global optimum with Particle Swarm Optimisation
    tic;
    
    objFcn = @(p) roundParamsFn( model, p, paramInfo.isCat );

    optimum = particleswarm(    objFcn, ...
                                nParams, ...
                                paramInfo.psoLB, ...
                                paramInfo.psoUB, ...
                                optionsPSO );

    % enforce rounding of categorical or integer parameters
    optimumR( paramInfo.doRounding ) = round( optimum( paramInfo.doRounding ) );
    optimumR( ~paramInfo.doRounding ) = optimum( ~paramInfo.doRounding );

    opt.XTrace( k, : ) = convParams( optimumR, paramDef, paramInfo );  
    opt.XTraceIndex( k, : ) = optimumR;
    [ opt.EstYTrace( k ), opt.EstYCITrace( k ) ] = predict( model, optimumR );
    
    opt.psoTimeTrace( k ) = toc;

    
    
    if setup.constrain
        % restrict search to loss less than a progressively reducing
        alpha = max( (1 - 2*k/setup.nFit), 0);
        opt.maxLossTrace( k ) = ...
            max( min(srch.YTrace( 1:c)), opt.EstYTrace(k) ) + ...
                            alpha*std( srch.YTrace( max(c-w+1,1):c) );
    end
    
    % make interim reports
    if setup.verbose > 0
        disp(['Surogate Model: Loss = ' num2str( opt.EstYTrace(k) ) ...
                    ' +/- ' num2str( opt.EstYCITrace(k) ) ...
                    '; noise = ' num2str( opt.NoiseTrace(k) )] );
    end
    if setup.verbose > 1
        figPerf = plotOptPerf( srch, opt, figPerf );
    end
    if setup.verbose > 2
        figSearch = plotOptSearch( srch.XTraceIndex, opt.XTraceIndex, ...
                                    paramDef, figSearch );
    end
    if setup.verbose > 3
        [ opt.XDistPeak( k, : ), ~, figDist ] = plotOptDist( ...
                         opt.XTrace( 1:k, : ), ...
                         paramDef, setup, figDist );
    end


        
end

% finally check on the accuracy of the final prediction
params = opt.XTrace( k, : );
if setup.noObjData && setup.noObjOptions
    obs = objFn( params );
elseif setup.noObjOptions
    obs = objFn( params, data );
else
    obs = objFn( params, data, options );
end

opt.ObsYTrace( k ) = min( obs, setup.cap );

            
end



function [ p, pIndex, delta, nTries ] = randomParams( pDef, pInfo, ...
                                        model, YTrace, ...
                                        maxLoss, porousness, ...
                                        maxTries, rndQ )

    nVar = length( pDef );
    pIndex = zeros( 1, nVar );
    
    useQuasiRandomSeq = isa( rndQ, 'qrandstream' );
    useGPModel = isa( model, 'RegressionGP' );
    
    if useGPModel
        % calculate width of acceptance probability drop-off
        delta = porousness*std( YTrace );
    else
        delta = 0;
    end

    inRange = false;
    nTries = 0;
    while ~inRange

        if useQuasiRandomSeq
            % generate quasi-random set of numbers
            r = qrand( rndQ );
        else
            % generate pseudo-random set of numbers
            r = rand( nVar );
        end
        
        % randomly select the parameter values
        % only categorical parameters are granular
        % numerical parameters are real or integer       
        for i = 1:nVar
            switch pDef(i).Type
                case 'categorical'
                    pIndex(i) = rndCat( pInfo.nLevels(i), r(i) );
                case 'integer'
                    pIndex(i) = rndInt( pInfo.psoLB(i), ...
                                         pInfo.psoUB(i), r(i) );
                case 'real'
                    pIndex(i) = rndReal( pInfo.psoLB(i), ...
                                         pInfo.psoUB(i), r(i) );
            end               
        end

        if useGPModel
            % model exists (after first iteration)
            % get prediction of what this model error would be
            estLoss = predict( model, pIndex );
            if estLoss < maxLoss
                inRange = true;
            else
                % compute probability of accepting params
                % based on a normal distribution
                pAccept = exp(-0.5*((estLoss-maxLoss)/delta)^2);
                inRange = rand<pAccept;
            end

        else
            % no objective model yet (first iteration)
            inRange = true;
        end
        
        nTries = nTries+1;
        if mod( nTries, maxTries )==0
            % double the probability acceptance width
            % to increase chances of finding an acceptable point
            delta = delta*2;
        end
    
    end       
    
    % generate table from indices
    % this is done outside the search loop because 
    % the 'categorical' function is time consuming
    for i = 1:nVar
        switch pDef(i).Type
            case 'categorical'
                p.(pDef(i).Name) = categorical( pDef(i).Range( pIndex(i) ) );
            case 'integer'
                p.(pDef(i).Name) = pIndex(i);
            case 'real'
                p.(pDef(i).Name) = pIndex(i);
        end
    end               
    p = struct2table( p );
    
end


function i = rndCat( range, rnd )

% Generate a random integer in the range 1..rng

i = round( range*rnd-0.5)+1;

end


function r = rndInt( lower, upper, rnd )

% Generate a random real in the range lower..upper

r = round( lower+(upper-lower)*rnd );

end


function r = rndReal( lower, upper, rnd )

% Generate a random real in the range lower..upper

r = lower+(upper-lower)*rnd;

end



function model = fitSurrogateModel( prevModel, var, X, Y, sigmaLB, sigma )

fixSigma = (nargin == 6);
if ~fixSigma
    sigma = 0.5;
end

if isempty( prevModel ) || fixSigma
    % first with no initial hyperparameters
    model = fitrgp(  ...
                X, ...
                Y, ...
                'CategoricalPredictors', var.isCat, ...
                'BasisFunction', 'Constant', ... 
                'KernelFunction', 'ARDMatern52', ...
                'Standardize', false, ...
                'Sigma', sigma, ...
                'SigmaLowerBound', sigmaLB, ...
                'ConstantSigma', fixSigma );

else
    % use previously fitted hyperparameters as initial values
    % which speeds up the fitting considerably

    % check first if the number of predictors has changed
    % as with categorical variables there can be more dummy variables
    nPredictors = numPredictors( X, var.isCat );
    if nPredictors == ...
            length( prevModel.KernelInformation.KernelParameters )-1

        model = fitrgp(  ...
                X, ...
                Y, ...
                'CategoricalPredictors', var.isCat, ...
                'BasisFunction', 'Constant', ... 
                'KernelFunction', 'ARDMatern52', ...
                'Standardize', false, ...
                'Sigma', prevModel.Sigma, ...
                'SigmaLowerBound', sigmaLB, ...
                'Beta', prevModel.Beta, ...
                'KernelParameters', prevModel.KernelInformation.KernelParameters );

    else
        % cannot use the previous kernel parameters
        model = fitrgp(  ...
                X, ...
                Y, ...
                'CategoricalPredictors', var.isCat, ...
                'BasisFunction', 'Constant', ... 
                'KernelFunction', 'ARDMatern52', ...
                'Standardize', false, ...
                'Sigma', prevModel.Sigma, ...
                'SigmaLowerBound', sigmaLB, ...
                'Beta', prevModel.Beta );

    end
end



end



function obj = roundParamsFn( model, Xnumeric, isCat )

% Intermediate objective function to perform rounding (where required)
% for categorical or integer variables
% Particle Swarm Optimisation only works in real variables 

X( isCat ) = round( Xnumeric( isCat ) );
X( ~isCat ) = Xnumeric( ~isCat );

obj = predict( model, X );

end



function X = convParams( Xnumeric, pDef, pInfo )

% convert Particle Swarm variables back to model parameters

for i = 1:length( Xnumeric )
    
    if pInfo.isCat(i) 
        X.(pDef(i).Name) = categorical( pDef(i).Range( Xnumeric(i) ) );
    else
        X.(pDef(i).Name) = Xnumeric(i);
    end
    
end

X = struct2table( X );

end


function nPred = numPredictors( data, isCat )

if sum( isCat ) > 1
    nCat = size( dummyvar( data(:,isCat) ), 2 );
else
    nCat = 0;
end
nNotCat = length( isCat ) - sum( isCat );

nPred = nCat + nNotCat;

end
