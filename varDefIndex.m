% ************************************************************************
% Function: varDefIndex
% Purpose:  Return the index representation of XTrace
%
%
% Parameters:
%           X:          XTrace in table form
%           varDef:     variable definitions (should match X)
%
% Output:
%           XIndex:     index representation of X
%
% ************************************************************************

function XIndex = varDefIndex( X, varDef )

[ nObs, nVar ] = size( X );

XIndex = zeros( nObs, nVar );
for i = 1:nVar
    if strcmp( varDef(i).Type, 'categorical' )
        varName = X.Properties.VariableNames{i};
        XIndex(:,i) = find( X.(varName)==varDef(i).Range );
    else
        XIndex(:,i) = table2array( X(:,i) );
    end
end

end
