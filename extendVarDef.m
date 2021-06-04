% ************************************************************************
% Function: extendVarDef
% Purpose:  Create a new object that inherits varDef's fields
%
% Parameters:
%       varDef:     full array of optimizableVariables
%       setup:      optimization setup structure that contains extra info
%
% Output:
%       newDef:     updated definition
%
% ************************************************************************

function newDef = extendVarDef( varDef, setup )

for i = 1:length(varDef)
   newDef(i) = optimizableVariableExtension( ...
                    varDef(i), ...
                    setup.descr(i), ...
                    setup.fcn(i), ...
                    setup.bounds(i), ...
                    setup.lim(i) ); %#ok<AGROW>
end


end
