% ************************************************************************
% Function: trueOptimum.m
% Purpose:  Find the true optimum with Particle Swarm optimisation
%
%
%
% ************************************************************************

function optimum = trueOptimum


[ objFunc, varDef ] = setupObjFn( 'MultiDimTest' );
    
nParams = length( varDef );
lb = zeros( 1, nParams );
ub = zeros( 1, nParams );
for i = 1:nParams

    switch varDef(i).Type
        case 'categorical'
            lb(i) = 0.5;
            ub(i) = length( varDef(i).Range )+0.49;
        case 'integer'
            lb(i) = varDef(i).Range(1);
            ub(i) = varDef(i).Range(2);
        case 'real'
            lb(i) = varDef(i).Range(1);
            ub(i) = varDef(i).Range(2);
    end

end

optionsPSO = optimoptions('particleswarm', ...
                            'Display', 'None', ...
                            'FunctionTolerance', 0.001, ...
                            'MaxIterations', 10000, ...
                            'MaxStallIterations', 50, ...
                            'SwarmSize', 100 );

objFcn = @(varDef) objFunc( varDef );

optimum = particleswarm(    objFcn, ...
                            nParams, ...
                            lb, ...
                            ub, ...
                            optionsPSO );       



end