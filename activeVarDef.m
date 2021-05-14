% ************************************************************************
% Function: activeVarDef
% Purpose:  Identify active variables for optimisation
%           as indicated by the Optimize flag.
%
% Parameters:
%       varDef: array of optimizableVariable
%
% Output:
%       id: active variables
%
% ************************************************************************

function id = activeVarDef( varDef )

n = length( varDef );
include = false( n, 1 );
for i = 1:n
    include(i) = varDef(i).Optimize;
end

id = find( include );

end