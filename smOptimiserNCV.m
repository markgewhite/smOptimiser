% ************************************************************************
% Function: smOptimiserNCV
% Purpose:  Finds the global optimum using a nested cross validation
%           framework. The outer level is partitioned using a K-fold
%           design. Each training partition is then used by the 
%           smOptimiser. The result of that optimisation in then
%           used to evaluate the objective function with the validation
%           set. The procedure repeats for each data split.
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
%           setup               optimiser's setup
%               .nFit:          number of model fits (default = 100)
%               .nSearch:       number of observations before next fit
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
%
% Output:
%           optTrace:           optimal parameters in same table format
%           valResult:          validation results
%
% ************************************************************************


function output = smOptimiserNCV( ...
                                objFcn, paramDef, setup, data, options )

% partition the data (outer)
% (valSelect is the reverse of trnSelect since no test data)
trnSelect = partitionData(     (1:setup.nObs)', ...
                               setup.subjects, ...
                               setup.partitioning );

% shorthand
nOuter = setup.partitioning.iterations;
nInner = setup.nFit;
nSearch = setup.nSearch;
nRepeats = setup.nRepeats;
nInter = setup.nInterTrace;
nParams = length( activeVarDef(paramDef) );

% initialise tables for recording optimisations
srch.XTrace = setupOptTable( paramDef, nOuter*nRepeats*nInner*nSearch );
srch.XTraceIndex = zeros( nOuter*nRepeats*nInner*nSearch, nParams );
srch.YTrace = zeros( nOuter*nRepeats*nInner*nSearch, 1 );
srch.ObjFnTimeTrace = zeros( nOuter*nRepeats*nInner*nSearch, 1 );

opt.XTrace = setupOptTable( paramDef, nOuter*nRepeats*nInner );
opt.XTraceIndex = zeros( nOuter*nRepeats*nInner, nParams );
opt.EstYTrace = zeros( nOuter*nRepeats*nInner, 1 );
opt.ObsYTrace = zeros( nOuter*nRepeats*nInner, 1 );
opt.EstYCITrace = zeros( nOuter*nRepeats*nInner, 1 );

opt.XTraceInter = setupOptTable( paramDef, nOuter*nRepeats*nInter );
opt.XTraceIndexInter = zeros( nOuter*nRepeats*nInter, nParams );
opt.YTraceOuter = zeros( nOuter*nRepeats*nInter, 1 );
opt.constraints = cell( nOuter*nRepeats*nInter, 1 );
opt.validModel = false( nOuter*nRepeats*nInter, 1 );

opt.Fold = zeros( nOuter*nRepeats*nInter, 1 );
opt.XFinal = setupOptTable( paramDef, nOuter );

opt.FitTimeTrace = zeros( nOuter*nRepeats*nInner, 1 );
opt.PSOTimeTrace = zeros( nOuter*nRepeats*nInner, 1 );

% initialise arrays recording diagnostics and results
valResult = zeros( nOuter, 1 );

% initialise counters
a1 = 0;
b1 = 0;
c1 = 0;
m = 0;

summaryFig = []; % new figure for each outer iteration

% loop over outer partitions
for i = 1:nOuter
    
    disp(['Outer Iteration = ' num2str(i)]);
    
    if isa( data, 'struct')
        % data is structured so extract the subset from each field
        trnData = dataStructExtract( data, trnSelect(:,i) );
    else
        % assumed to be a table or array
        trnData = data( trnSelect(:,i), : );
    end
       
    % repeat runs on inner partitions
    for j = 1:nRepeats
        
        disp(['Inner Repeat = ' num2str(j)]);
        
        [ ~, ~, optOutput, srchOutput ] = smOptimiser( ...
                                            objFcn, paramDef, setup, ...
                                            trnData, ...
                                            options );
        % update counters
        a0 = a1 + 1;
        a1 = a1 + nInner*nSearch;
        b0 = b1 + 1;
        b1 = b1 + nInner;
        c0 = c1 + 1;
        c1 = c1 + nInter;

        % record traces
        srch.XTrace( a0:a1, : ) = srchOutput.XTrace;
        srch.XTraceIndex( a0:a1, : ) = srchOutput.XTraceIndex;
        srch.YTrace( a0:a1 ) = srchOutput.YTrace;
        srch.ObjFnTimeTrace( a0:a1 ) = srchOutput.objFnTimeTrace;
        
        opt.XTrace( b0:b1, : ) = optOutput.XTrace;       
        opt.XTraceIndex( b0:b1, : ) = optOutput.XTraceIndex;
        opt.EstYTrace( b0:b1, : ) = optOutput.EstYTrace;
        opt.ObsYTrace( b0:b1, : ) = optOutput.ObsYTrace;
        opt.EstYCITrace( b0:b1, : ) = optOutput.EstYCITrace;
        opt.FitTimeTrace( b0:b1 ) = optOutput.fitTimeTrace;
        opt.PSOTimeTrace( b0:b1 ) = optOutput.psoTimeTrace;
        
        opt.XTraceInter( c0:c1, : ) = optOutput.XTrace( end-nInter+1:end, :);
        opt.XTraceIndexInter( c0:c1, : ) = ...
                                optOutput.XTraceIndex( end-nInter+1:end, :);
        
        opt.Fold( c0:c1 ) = i;
              
    end
    
    % find the outer validation error for intermediate models
    for j = 1:nInter*nRepeats
        [ opt.YTraceOuter( c1-j+1 ), opt.constraints{ c1-j+1 } ] = ...
                                objFcn( opt.XTraceInter( c1-j+1,:), ...
                                        data, ...
                                        options, ...
                                        trnSelect(:,i) );
        opt.validModel( c1-j+1 ) = all( opt.constraints{ c1-j+1 }<=0 );
    end
    
    
    m = m + 1;
    % determine ensemble optimal parameters for this outer fold
    temp = setup.showPlots;
    setup.showPlots = false;     % temporarily disable plotting
    
    % select models, excluding invalid ones
    modelIdx = c1-nRepeats*nInter+1:c1;
    modelIdx = modelIdx( opt.validModel( modelIdx ) );
    opt.XFinal(m,:) = plotOptDist( ...
                                opt.XTraceInter( modelIdx, : ), ...
                                paramDef, ...
                                setup, ...
                                [] );
    setup.showPlots = temp;
    
    % find the outer validation error for this ensemble model
    valResult(i) = objFcn( opt.XFinal(m,:), ...
                                   data, ...
                                   options, ...
                                   trnSelect(:,i) );
    
    disp(['Outer Validation Error = ' num2str( valResult(i) )]);
    
    % plot over distribution for all folds up to this point
    modelIdx = 1:c1;
    modelIdx = modelIdx( opt.validModel( modelIdx ) );
    [ opt.Final, ~, summaryFig ]= plotOptDist( ...
                                    opt.XTraceInter( modelIdx, : ), ...
                                    paramDef, ...
                                    setup, ...
                                    summaryFig, ...
                                    opt.Fold( modelIdx ) );
                                
end

% assemble output structure
output.estimate = mean( valResult );
output.valFolds = valResult;
output.optima = opt;
output.search = srch;

end



function subset = dataStructExtract( data, rows )

flds = fields( data );
subset = data;

for i = 1:length(flds)
    if isa( data.(flds{i}), 'struct' )
        subset.(flds{i}) = dataStructExtract( data.(flds{i}), rows );
    elseif length( rows ) == length( subset.(flds{i}) )
        subset.(flds{i}) = subset.(flds{i})( rows, : );
    end
end

end
