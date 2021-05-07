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
%               .nOuter:        number of outer iterations (default = 100)
%               .nInner:        after every nInner iterations make
%                               observation at the previously estimated
%                               optimum (default = 20)
%               .maxTries:      maximum number of times to try a random
%                               choice of parameter values that satisfies
%                               the constraint (default = 20)
%               .initMaxLoss:   initial maximum objective function loss
%                               (default = 1E6) rance for Particle Swarm
%                               Optimisation (optional; default = 1E-3)
%               .tolPSO         function minimum tolerance for PSO
%                               (optional; default = 0.001)
%               .maxIterPSO     maximum number of PSO search iterations
%                               (optional; default = 1000)
%               .prcMaxLoss     percentile of observations for maxLoss
%                               (optional; default = 100)
%               .verbose        output level: (optional; default = 1)
%                                   0 = no output; 1 = commandline output
%
% Output:
%           optimum:        optimal parameters for the objective function
%           model:          Bayesian surrogate model structure
%           opt:            optimisation record structure (PSO)
%           search:         random search record sructure
%
% ************************************************************************

function [ optimum, model, opt, search ] = smOptimiser( objFn, paramDef, setup )


% parse arguments
if nargin ~= 3
    error('Three arguments not specified.');
end

if isfield( setup, 'nOuter' )
    if setup.nOuter <= 0 || isinteger( setup.nOuter )
        error('Setup: nOuter must be a positive integer.');
    end
else
   setup.nOuter = 100; % default
end

if isfield( setup, 'nInner' )
    if setup.nInner <= 0 || isinteger( setup.nInner )
        error('Setup: nInner must be a positive integer.');
    end
else
   setup.nInner = 20; % default
end

if isfield( setup, 'maxTries' )
    if setup.maxTries <= 0 || isinteger( setup.maxTries )
        error('Setup: maxTries must be a positive integer.');
    end
else
   setup.maxTies = 20; % default
end

if ~isfield( setup, 'initMaxLoss' )
   setup.maxTies = 1E6; % default
end

if ~isfield( setup, 'tolPSO' )
   setup.tolPSO = 0.001; % default
end

if ~isfield( setup, 'maxIterPSO' )
   setup.maxIterPSO = 1000; % default
end

if ~isfield( setup, 'prcMaxLoss' )
   setup.prcMaxLoss = 100; % default
end

if ~isfield( setup, 'porousness' )
   setup.porousness = 0.5; % default
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


nParams = length( paramDef );

% add extra definitions (for speed)
paramInfo.name = cell( 1, nParams );
paramInfo.varType = cell( 1, nParams );
paramInfo.isCat = false( 1, nParams );
paramInfo.doRounding = false( 1, nParams );
paramInfo.nLevels = zeros( 1, nParams );
paramInfo.lowerBound = zeros( 1, nParams );
paramInfo.upperBound = zeros( 1, nParams );
for i = 1:nParams

    paramInfo.name{i} = paramDef(i).Name;
    switch paramDef(i).Type
        
        case 'categorical'
            paramInfo.varType{i} = 'categorical';
            paramInfo.isCat(i) = true;
            paramInfo.doRounding(i) = true;
            paramInfo.nLevels(i) = length( paramDef(i).Range );
            paramInfo.lowerBound(i) = 0.5;
            paramInfo.upperBound(i) = paramInfo.nLevels(i)+0.49;

        case 'integer'
            paramInfo.varType{i} = 'double';
            paramInfo.isCat(i) = false;
            paramInfo.doRounding(i) = true;
            paramInfo.nLevels(i) = paramDef(i).Range(2)- ...
                                        paramDef(i).Range(1)+1;
            paramInfo.lowerBound(i) = paramDef(i).Range(1);
            paramInfo.upperBound(i) = paramDef(i).Range(2);
            
        case 'real'
            paramInfo.varType{i} = 'double';
            paramInfo.isCat(i) = false;
            paramInfo.doRounding(i) = false;
            paramInfo.lowerBound(i) = paramDef(i).Range(1);
            paramInfo.upperBound(i) = paramDef(i).Range(2);
            
    end

end                       

% initialisation
search.XTrace = table( ...
                'Size', [setup.nOuter*setup.nInner, nParams], ...
                'VariableTypes', paramInfo.varType, ...
                'VariableNames', paramInfo.name );
search.XTraceIndex = zeros( setup.nOuter*setup.nInner, nParams );
search.YTrace = zeros( setup.nOuter*setup.nInner, 1 );

opt.XTrace = table( ...
                'Size', [setup.nOuter, nParams], ...
                'VariableTypes', paramInfo.varType, ...
                'VariableNames', paramInfo.name );
opt.XTraceIndex = zeros( setup.nOuter, nParams );
opt.EstYTrace = zeros( setup.nOuter, 1 );
opt.YCITrace = zeros( setup.nOuter, 1 );
opt.noise = zeros( setup.nOuter, 1 );
opt.modelSD = zeros( setup.nOuter, 1 );

model = 0;
optionsPSO = optimoptions('particleswarm', ...
                            'Display', 'None', ...
                            'FunctionTolerance', setup.tolPSO, ...
                            'MaxIterations', setup.maxIter );
optimumR = zeros( 1, nParams);

if setup.quasiRandom
    % generate a quasi-random sequence with required dimensions
    rndSeq = haltonset( nParams, 'Skip', 1000, 'Leap', 100);
    rndSeq = scramble( rndSeq, 'RR2' );
    rndQ = qrandstream( rndSeq );
else
    rndQ = 0;
end

% start with the initial specified maximum
maxLoss = setup.initMaxLoss;
% full iteration counter
c = 0; 

for k = 1:setup.nOuter

    for j = 1:setup.nInner
        
        % determine the random parameters
        if j > 1 || k == 1
            % random search
            [ params, indices ] = randomParams( ...
                                paramDef, paramInfo, model, ...
                                search.YTrace( 1:c ), ...
                                maxLoss, setup.porousness, ...
                                setup.maxTries, rndQ );     
        else
            % parameters at estimated optimum
            params = opt.XTrace( k-1, : );
            indices = opt.XTraceIndex( k-1, : );

        end
    
        % run the model for this set of parameters
        obs = objFn( params );

        % record observation
        c = c+1;
        search.YTrace( c ) = obs;
        search.XTrace( c, : ) = params;
        search.XTraceIndex( c, : ) = indices;
        
    end

    
    
    % fit the GP model to the observations
    tic;
    if k == 1
        % first with no initial hyperparameters
        model = fitrgp(  ...
                    search.XTraceIndex( 1:c, : ), ...
                    search.YTrace( 1:c ), ...
                    'CategoricalPredictors', paramInfo.isCat, ...
                    'BasisFunction', 'Constant', ... 
                    'KernelFunction', 'ARDMatern52', ...
                    'Standardize', false );
    else
        % use previously fitted hyperparameters as initial values
        % which speeds up the fitting considerably
        model = fitrgp(  ...
                    search.XTraceIndex( 1:c, : ), ...
                    search.YTrace( 1:c ), ...
                    'CategoricalPredictors', paramInfo.isCat, ...
                    'BasisFunction', 'Constant', ... 
                    'KernelFunction', 'ARDMatern52', ...
                    'Standardize', false, ...
                    'Sigma', model.Sigma, ...
                    'Beta', model.Beta, ...
                    'KernelParameters', model.KernelInformation.KernelParameters );
    end
    
    % find the global optimum with Particle Swarm Optimisation
    objFcn = @(p) roundParamsFn( model, p, paramInfo.isCat );

    optimum = particleswarm(    objFcn, ...
                                nParams, ...
                                paramInfo.lowerBound, ...
                                paramInfo.upperBound, ...
                                optionsPSO );

    optimumR( paramInfo.doRounding ) = round( optimum( paramInfo.doRounding ) );
    optimumR( ~paramInfo.doRounding ) = optimum( ~paramInfo.doRounding );

    opt.XTrace( k, : ) = convParams( optimumR, paramDef, paramInfo );  
    opt.XTraceIndex( k, : ) = optimumR;
    opt.noise( k ) = model.Sigma;
    [ opt.EstYTrace( k ), opt.modelSD( k ) ] = predict( model, optimum );

    
    if setup.verbose > 0
        disp(['Particle Swarm Optimum = ' num2str( optimumR ) ...
            '; Surogate Model: Loss = ' num2str( opt.EstYTrace(k) ) ...
                    ' +/- ' num2str( opt.YCITrace(k) ) ...
                    '; noise = ' num2str( opt.noise(k) )] );
    end
    
    if setup.constrain
        % restrict search to loss less than a
        % progressively reducing proportion of previous minimum
        alpha = setup.prcMaxLoss*(1 - k/setup.nOuter);
        maxLoss = prctile( search.YTrace(1:c), alpha );
    end
        
end

            
end



function [ p, pIndex ] = randomParams( pDef, pInfo, ...
                                        model, YTrace, ...
                                        maxLoss, porousness, ...
                                        maxTries, rndQ )

    nVar = length( pDef );
    pIndex = zeros( 1, nVar );
    
    useQuasiRandomSeq = isa( rndQ, 'qrandstream' );
    useGPModel = isa( model, 'RegressionGP' );
    
    if useGPModel
        % calculate width of acceptance probability drop-off
        sigma = porousness*std( YTrace );
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
                    pIndex(i) = rndInt( pInfo.nLevels(i), r(i) );
                    p.(pDef(i).Name) = categorical( ...
                                            pDef(i).Range( pIndex(i) ) );
                case 'integer'
                    pIndex(i) = rndInt( pInfo.nLevels(i), r(i) );
                    p.(pDef(i).Name) = pIndex(i);
                case 'real'
                    pIndex(i) = rndReal( pInfo.lowerBound(i), ...
                                         pInfo.upperBound(i), r(i) );
                    p.(pDef(i).Name) = pIndex(i);
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
                pAccept = exp(-0.5*((estLoss-maxLoss)/sigma)^2);
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
            sigma = sigma*2;
        end
    
    end       
    
    p = struct2table( p );
    
end


function i = rndInt( range, rnd )

% Generate a random integer in the range 1..rng

i = round( range*rnd-0.5)+1;

end


function r = rndReal( lower, upper, rnd )

% Generate a random real in the range lower..upper

r = lower+(upper-lower)*rnd;

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


