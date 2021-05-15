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

% initialise tables for recording optimisations
srchXTrace = setupOptTable( paramDef, nOuter*nRepeats*nInner*nSearch );
srchYTrace = zeros( nOuter*nRepeats*nInner*nSearch, 1 );

optXTrace = setupOptTable( paramDef, nOuter*nRepeats*nInner );
optEstYTrace = zeros( nOuter*nRepeats*nInner, 1 );
optObsYTrace = zeros( nOuter*nRepeats*nInner, 1 );
optEstYCITrace = zeros( nOuter*nRepeats*nInner, 1 );

optXTraceInter = setupOptTable( paramDef, nOuter*nRepeats*nInter );

optFold = zeros( nOuter*nRepeats*nInter, 1 );
optXFinal = setupOptTable( paramDef, nOuter );

optFitTimeTrace = zeros( nOuter*nRepeats*nInner, 1 );
optPSOTimeTrace = zeros( nOuter*nRepeats*nInner, 1 );

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
        srchXTrace( a0:a1, : ) = srchOutput.XTrace;
        srchYTrace( a0:a1 ) = srchOutput.YTrace;
        
        optXTrace( b0:b1, : ) = optOutput.XTrace;       
        optEstYTrace( b0:b1, : ) = optOutput.EstYTrace;
        optObsYTrace( b0:b1, : ) = optOutput.ObsYTrace;
        optEstYCITrace( b0:b1, : ) = optOutput.EstYCITrace;
        optFitTimeTrace( b0:b1 ) = optOutput.fitTimeTrace;
        optPSOTimeTrace( b0:b1 ) = optOutput.psoTimeTrace;
        
        optXTraceInter( c0:c1, : ) = optOutput.XTrace( end-nInter+1:end, :);
        
        optFold( c0:c1 ) = i;
              
    end
    
    m = m + 1;
    % determine optimal parameters for this outer fold
    temp = setup.showPlots;
    setup.showPlots = false;     % temporarily disable plotting
    optXFinal(m,:) = plotOptDist( ...
                                optXTraceInter(c1-nRepeats*nInter+1:c1,:), ...
                                paramDef, ...
                                setup, ...
                                [] );
    setup.showPlots = temp;
    
    valResult(i) = objFcn( optXFinal(m,:), ...
                                   data, ...
                                   options, ...
                                   trnSelect(:,i) );
    
    disp(['Outer Validation Error = ' num2str( valResult(i) )]);
    
    % plot over distribution for all folds up to this point
    [ optFinal, ~, summaryFig ]= plotOptDist( ...
                                    optXTraceInter(1:c1,:), ...
                                    paramDef, ...
                                    setup, ...
                                    summaryFig, ...
                                    optFold(1:c1) );
                                
end

% assemble output structure
output.optimum = optFinal;
output.estimate = mean( valResult );
output.valFolds = valResult;
output.optXFinal = optXFinal;
output.optXTraceInter = optXTraceInter;
output.optXTraceFull = optXTrace;
output.EstYTrace = optEstYTrace;
output.EstYCITrace = optEstYCITrace;
output.ObsYTrace = optObsYTrace;
output.searchXTrace = srchXTrace;
output.searchYTrace = srchYTrace;
output.optFitTimeTrace = optFitTimeTrace;
output.optPSOTimeTrace = optPSOTimeTrace;


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
