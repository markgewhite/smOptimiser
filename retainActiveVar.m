% ************************************************************************
% Function: retainActiveVar
% Purpose:  Retain the active variables from X based on
%           the active variables in varDef
%
% Parameters:
%       X:          X trace for trimming
%       varDef:     full array of optimizableVariables
%
% Output:
%       newX:       X trace with trimmed fields
%
% ************************************************************************

function newX = retainActiveVar( X, varDef )

% select the appropriate X fields to match
retain = false( size(X,2), 1 );

for i = 1:length( varDef )
    flds = strcmp( varDef(i).Name, X.Properties.VariableNames );
    if any( flds ) && varDef(i).Optimize
        retain( flds ) = true;
    end
end

newX = X( :, retain );

end