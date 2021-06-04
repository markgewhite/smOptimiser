classdef optimizableVariableExtension < optimizableVariable
    properties
        Descr
        Fcn
        Bounds
        Limits
    end
    methods
        function obj = optimizableVariableExtension( varDef, descr, fcn, bounds, lim )
            obj.Descr = descr;
            obj.Fcn = fcn{1};
            obj.Bounds = bounds{1};
            obj.Limits = lim{1};
            obj.Name = varDef.Name;
            obj.Range = varDef.Range;
            obj.Type = varDef.Type;
            obj.Transform = varDef.Transform;
            obj.Optimize = varDef.Optimize;
        end
    end
end
