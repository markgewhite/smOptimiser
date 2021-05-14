% ************************************************************************
% Function: setupOptTable
% Purpose:  Setup the optimisation table from the variable definitions
%
%
% Parameters:
%           varDef: objective function parameters (optimizervariable)
%                   
%           nRows: number of rows requested
%
% Output:
%           optTable: formatted table
%
% ************************************************************************


function optTable = setupOptTable( varDef, nRows )

activeVar = activeVarDef( varDef );
nVars = length( activeVar );

varType = strings( nVars, 1 );
varName = strings( nVars, 1 );

for i = 1:nVars
   varName{i} = varDef( activeVar(i) ).Name;
   switch varDef( activeVar(i) ).Type
       case {'real','integer'}
           varType{i} = 'double';
       case 'categorical'
           varType{i} = 'categorical';
   end
end

optTable = table( 'Size', [ nRows, nVars ], ...
                   'VariableTypes', varType, ...
                   'VariableNames', varName );

end

