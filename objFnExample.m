% ************************************************************************
% Function: objFnExample
% Purpose:  Example of an objective function with categorical, real and
%           integer arguments.
%
%
% Parameters:
%           colour: categorical ('Red', 'Green', Blue')
%           pattern: categorical ('Plain', 'Striped')
%           frequency: real (0...1000)
%           step: integer (1...20)
%           
%
% Output:
%           value: computed value
%
% ************************************************************************

function value = objFnExample( x )
   
% setup factors
switch x.colour
    case 'Red'
        f1 = 1;
    case 'Green'
        f1 = 3;
    case 'Blue'
        f1 = 2;
    otherwise
        f1 = 0;
end

switch x.pattern
    case 'Plain'
        f2 = 0.5;
    case 'Striped'
        f2 = 0.25;
    otherwise
        f2 = 0;
end
      
    

% calculate function
value = f2*sin( x.frequency*x.step*pi/180 )+f1;

end


