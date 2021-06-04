% ************************************************************************
% Function: setPlotAttr
% Purpose:  Set attributes for plotting objective function
%
% Parameters:
%       varDef:     optimizableVariables
%
% Output:
%       attr:       attributes
%
% ************************************************************************

function attr = setPlotAttr( varDef )

% extract attributes
if isa( varDef, 'optimizableVariableExtension' )
    attr.XLabel = varDef.Descr;
    attr.XLim = varDef.Limits;
    attr.XBounds = varDef.Bounds;
    attr.XFcn = varDef.Fcn;
    
elseif isa( varDef, 'optimizableVariable' )
    attr.XLabel = varDef.Name;
    attr.XLim = varDef.Range;
    attr.XFcn = @(x) x;
    
else
    error('Unrecognised varDef type.');
    
end

% check transformation function
if isa( attr.XFcn, 'function_handle' ) && strcmp( varDef.Transform, 'none' )
    % remove the 10-to-the-power transformation
    attr.XFcn = @(x) x;
    
elseif isa( attr.XFcn, 'double' )
    % create a proper function for an array assuming linear spacing
    slope = (attr.XFcn(end)-attr.XFcn(1))/(length(attr.XFcn)-1);
    intercept = attr.XFcn(1);
    attr.XFcn = @(x) slope*x+intercept;
end


   
end
