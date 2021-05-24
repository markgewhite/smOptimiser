% ************************************************************************
% Function: switchActiveVarDef
% Purpose:  Switch the active variables to the ones specified
%
% Parameters:
%       varDef: array of optimizableVariable
%       activeVar: list of requested active variables (other inactive)
%
% Output:
%       varDef: updated array of optimizableVariable
%
% ************************************************************************

function varDef = switchActiveVarDef( varDef, activeVar )

for i = 1:length( varDef )
    varDef(i).Optimize = any( i==activeVar );
end

end