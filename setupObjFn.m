% ************************************************************************
% Function: setupObjFn
% Purpose:  Setup the objective function and its parameter definitions
%
%
% Parameters:
%           name: name of function to use
%
% Output:
%           objFn: objective function handle
%           varDef: function parameters
%
% ************************************************************************


function [ objFn, varDef ] = setupObjFn( name )


switch name
    
    case 'Example'
        
        varDef(1) = optimizableVariable( 'colour', ...
                {'Red', 'Green', 'Blue'}, ...
                'Type', 'categorical' );

        varDef(2) = optimizableVariable( 'pattern', ...
                {'Plain', 'Stripes', }, ...
                'Type', 'categorical' );

        varDef(3) = optimizableVariable( 'frequency', ...
                [0 180], ...
                'Type', 'real' );

        varDef(4) = optimizableVariable( 'step', ...
                [1 6], ...
                'Type', 'integer' );
            
        objFn = @objFnExample;

    
    case 'MultiDimTest'
        
        varDef(1) = optimizableVariable( 'a1', ...
                [0 180], ...
                'Type', 'real' );
            
        varDef(2) = optimizableVariable( 'a2', ...
                [0 180], ...
                'Type', 'real' );
            
        objFn = @objFnMultiDimTest;
        

    case 'MultiDimTest5'
        
        varDef(1) = optimizableVariable( 'a1', ...
                [0 180], ...
                'Type', 'real' );
            
        varDef(2) = optimizableVariable( 'a2', ...
                [0 180], ...
                'Type', 'real' );
            
        varDef(3) = optimizableVariable( 'a3', ...
                [0 180], ...
                'Type', 'real' );
            
        varDef(4) = optimizableVariable( 'a4', ...
                [0 180], ...
                'Type', 'real' );
            
        varDef(5) = optimizableVariable( 'a5', ...
                [0 180], ...
                'Type', 'real' );
            
        objFn = @objFnMultiDimTest5;
        
        
    otherwise
        
        error('Unrecognised function name.');

end
        
        
end
    
    