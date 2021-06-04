% ************************************************************************
% Function: generateSM
% Purpose:  Generate SM models from smOptimiserNCV output
%           in case they weren't generated originally by older versions.
%
%
% Parameters:
%           X:          XTraceInter from the output
%           Y:          YTrace also from the output
%           setup:      optimisation setup, including varDef
%
% Output:
%           smModels:   array of compact Surrogate Models
%
% ************************************************************************

function smModels = generateSM( X, Y, setup, activeVar )

[ nObs, nVar ] = size( X );
nOuter = nObs/(setup.nFit*setup.nSearch);

varDef = switchActiveVarDef( setup.varDef, activeVar );
varDef = varDef( activeVarDef(varDef) );

isCat = false( nVar, 1 );
for i = 1:nVar
    isCat(i) = strcmp( varDef(i).Type, 'categorical' );
end        

smModels = cell( nOuter, 1 );
for i = 1:nOuter
   
    obsEnd = i*setup.nFit*setup.nSearch;
    obsStart = obsEnd - setup.nInterTrace*setup.nSearch;

    XInter = X( obsStart:obsEnd, : );
    YInter = Y( obsStart:obsEnd );
    
    model = fitrgp(  ...
                            XInter, ...
                            YInter, ...
                            'CategoricalPredictors', isCat, ...
                            'BasisFunction', 'Constant', ... 
                            'KernelFunction', 'ARDMatern52', ...
                            'Standardize', false );
                        
    smModels{i} = compact( model );
    
    
end


end