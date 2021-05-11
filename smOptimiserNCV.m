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


function [ optTrace, valResult ] = smOptimiserNCV( ...
                                objFcn, paramDef, setup, data, options )

% partition the data (outer)

[ trnSelect, valSelect ] = partitionData(  data.outcome, ...
                                           data.subject, ...
                                           options.part.select );

% initialise
                                       
nOuter = options.part.select.kFolds;
nObs = nOuter*setup.nRepeats*setup.nInterTrace;

optTraceFull = setupOptTable( paramDef, nObs );
optTrace = setupOptTable( paramDef, nOuter*setup.nRepeats );

valResult = zeros( nOuter, 1 );

outputFigures = [];


% loop over outer partitions

c0 = 1;
c1 = setup.nInterTrace;
m = 0;
for i = 1:nOuter
    
    if isa( data, 'struct')
        % data is structured so extract the subset from each field
        trnData = dataStructExtract( data, trnSelect(i,:) );
        valData = dataStructExtract( data, valSelect(i,:) );
    else
        % assumed to be a table or array
        trnData = data( trnSelect(i,:), : );
        valData = data( trnSelect(i,:), : );
    end
        
    for j = 1:setup.nRepeats
        
        [ ~, ~, optOutput ] = smOptimiser( objFcn, paramDef, setup, ...
                                           trnData, ...
                                           options );
       
        optTraceFull( c0:c1, : ) = ...
                        optOutput.XTrace( end-setup.nInterTrace+1:end, :);

        m = m + 1;
        [optTrace(m,:), ~, outputFigures] = identifyOptimum( ...
                                                optTraceFull(1:c1,:), ...
                                                paramDef, ...
                                                setup, ...
                                                outputFigures );
        
        c0 = c1 + 1;
        c1 = c1 + setup.nInterTrace;
        
    end
    
    valResult(i) = objFcn( optTrace(m,:), valData, options );
    
    
end


end


function subset = dataStructExtract( data, rows )

flds = fields( data );
subset = data;

for i = 1:length(flds)
    if isa( data.(flds{i}), 'struct' )
        subset.(flds{i}) = dataStructExtract( data.(flds{i}), rows );
    else
        subset.(flds{i}) = subset.(flds{i})( rows, : );
    end
end

end
