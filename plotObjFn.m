% ************************************************************************
% Function: plotObjFn
% Purpose:  Plot the objective function at a given position in
%           parameter space varying one, two or three parameters.
%
%
% Parameters:
%
%           XTrace:             table logging the optima recorded by
%                               smOptimiser
%
%
%           figRef:             figure handle (optional)
%
%
% Output:
%           figRef:          figure handles
%
% ************************************************************************

function figRef = plotObjFn( v, optimum, XTrace, varDef, model, opt, figRef )

% constants
cmap = colorcube(64);
cmap2 = colorcube(16);

        
% defaults
if ~isfield( opt, 'overlapFactor' )
    opt.overlapFactor = 0.75;
end
if ~isfield( opt, 'contourStep' )
    opt.contourStep = 0.2;
end
if ~isfield( opt, 'contourType' )
    opt.contourType = 'Lines';
end

% create figure if it doesn't already exist
if isempty( figRef )
    figRef = figure;
else
    figure( figRef );
end


% ----------------------------------------------------------------
%  Prepare data
% ----------------------------------------------------------------        

% extract the valid points

validPts = XTrace ~= 0;       

nVar = length( v );
if nVar < 1 || nVar >2
    error('Incorrect number of variables for plotting');
end

isCat = false( nVar, 1 );
for i = 1:nVar
    isCat(i) = strcmp( varDef{i}.Type, 'categorical' );
end


[ XFit, XPlot, nPts ] = fineMesh( nVar, varDef );

[ XMeshFit, XMeshPlot ] = fineMeshMultiDim( nVar, XFit, XPlot );


%  Generate and plot each optimum
nOpt = size( optimum, 1 );
for j = 1:nOpt

    % set the optimum fit and plot parameters
    optimaFit = optimum(j,:);
    optimaPlot = zeros( 1, nVar );
    for i = 1:nVar
        if isCat(i)
            optimaPlot(i) = optimaFit( v(i) );              
        else           
            optimaPlot(i) = results.fcn{v(i)}( optimum(j,v(i)) );
            if strcmp( varDef.Transform(i), 'log' )
                optimaPlot(i) = log10( optimaPlot(i) );
            end
        end
    end

    % create the full predictor table (index representation)
    XLongFit = repmat( optimum(j,:), prod(nPts), 1 );

    % turn them into a long array for predictions
    % and place them in the full predictor table
    for i=1:nVar
        XLongFit( :, v(i) ) = reshape( XMeshFit(:,:,i), prod(nPts), 1 );
    end

    % predict the losses from the model (which is based on indices)
    [ YLong, YCI ] = predict( model, XLongFit );
    [ YOpt, YOptCI ] = predict( model, optimaFit );
    noise = model.Sigma;

    YOptMax = YOpt+opt.overlapFactor*YOptCI;

    ax = gca;
    pRef = [];
    switch nVar
        case 1
            pRef = plotFn1D( XMeshPlot, YLong, YCI, YOptMax, ...
                                noise, cmap, cmap2, opt );

        case 2
            pRef = plotFn2D( XMeshPlot, YLong, YOptMax, nPts, opt );

    end


    hold off;
    if ~isempty(pRef)
        legend( pRef, 'Location', 'best' );
        legend( 'boxoff' );
    end

    % set the axes' limits and tick values
    xlim( varDef{v(1)}.Range );
    xlabel( results.descr( v(1) ) );
    if nVar == 1
        ylim( opt.lossLim );
        yticks( opt.lossLim(1):opt.lossLim(2) );
        ylabel( opt.objectiveDescr );
    else
        ylim( results.lim{ v(2) } );
        ylabel( results.descr( v(2) ) );
    end

    if isCat(1)
        xTickNum = unique( round(XPlot{1}) );
        xticks( xTickNum );
        if isBoolean(1)
            xticklabels( {'False', 'True'} );
            ax.XAxis.MinorTickValues = 2.5;
        else
            xticklabels( results.varDef{v(1)}.Range );
            ax.XAxis.MinorTickValues = xTickNum(1:end-1)+0.5;
        end
    end

    if nVar >= 2

        if isCat(2)
            yTickNum = unique( round(XPlot{2}) );
            yticks( yTickNum );
            if isBoolean(2)
                yticklabels( {'False', 'True'} );
                ax.YAxis.MinorTickValues = 2.5;
            else
                yticklabels( results.varDef{v(2)}.Range );
                ax.YAxis.MinorTickValues = yTickNum(1:end-1)+0.5;
            end
        end

    end

    % set preferred properties
    ax.FontName = opt.plot.font;
    set( gca, 'FontSize', opt.plot.fontSize );
    set( gca, 'XTickLabelRotation', opt.plot.xLabelRotation );
    set( gca, 'LineWidth', opt.plot.lineWidth );
    set( gca, 'Box', opt.plot.box );
    set( gca, 'TickDir', opt.plot.tickDirection );

    drawnow;



end





end





function [ XFit, XPlot, nPts ] = fineMesh( nVar, varDef )


% create fine mesh for each variable 
% for the original ranges
% and for the index representation
nMesh = 200;
XFit = cell( nVar, 1 );
XPlot = cell( nVar, 1 );
nPts = zeros( nVar, 1 );
for i = 1:nVar
    limFit(1) = round( varDef(v(i)).Range(1) );
    limFit(2) = round( varDef(v(i)).Range(2) );

    if strcmp( varDef.Type, 'categorical' )

        limPlot = limFit;
        XFit{i} = twice( limFit(1):limFit(2), 0 )';
        XPlot{i} = twice( limFit(1):limFit(2), 0.5 )';

    else

        limPlot(1) = results.fcn{v(i)}( limFit(1) );
        limPlot(2) = results.fcn{v(i)}( limFit(2) );
        if results.isLog(v(i))
            limPlot = log10( limPlot );
        end
        hFit = ( limFit(2)-limFit(1) )/nMesh;
        XFit{i} = (limFit(1):hFit:limFit(2))';
        hPlot = ( limPlot(2)-limPlot(1) )/nMesh;
        XPlot{i} = (limPlot(1):hPlot:limPlot(2))';

    end

    nPts(i) = length( XFit{i} );

end

end



function [ XMeshFit, XMeshPlot ] = fineMeshMultiDim( nVar, XFit, XPlot )

% transform into mesh for contour plots
switch nVar
    case 1
        XMeshFit = XFit{1};
        XMeshPlot = XPlot{1};

    case 2
        [ XMeshFit(:,:,1), XMeshFit(:,:,2) ] = ...
                                    meshgrid( XFit{1}, XFit{2} );
        [ XMeshPlot(:,:,1), XMeshPlot(:,:,2) ] = ...
                                    meshgrid( XPlot{1}, XPlot{2} );

    case 3
        [ XMeshFit(:,:,1), XMeshFit(:,:,2), XMeshFit(:,:,3) ] = ...
                        meshgrid( XFit{1}, XFit{2}, XFit{3} );
        [ XMeshPlot(:,:,1), XMeshPlot(:,:,2), XMeshPlot(:,:,3) ] = ...
                        meshgrid( XPlot{1}, XPlot{2}, XPlot{3} );
end



end



function pRef = plotFn1D( XMeshPlot, YLong, YCI, YOptMax, noise, cmap, cmap2, opt )


lineMap = [ cmap2(13,:); cmap2(12,:); cmap2(6,:); ...
                        cmap2(8,:); cmap2(3,:); cmap2(2,:)];

% find the limits about the optimum
optIdx = YLong<=YOptMax;
ubIdx = 1;

while sum( optIdx(ubIdx:end) )>0 && ubIdx<length(optIdx)
    
    % find lower bound
    lbIdx = find( optIdx(ubIdx:end)==1, 1 )+ubIdx-1;
    % find upper bound
    ubIdx = find( optIdx(lbIdx:end)==0, 1 )+lbIdx-2;
    if isempty( ubIdx )
        ubIdx = length(optIdx);
    end
    
    % draw shaded area
    XOptPlotRev = [ XMeshPlot(lbIdx:ubIdx); ...
                flipud(XMeshPlot(lbIdx:ubIdx)) ];
    YOptPlotRev = [ YLong(lbIdx:ubIdx); ...
                zeros(ubIdx-lbIdx+1,1) ];                    
    pRef(4) = fill( XOptPlotRev, ...
                 YOptPlotRev, ...
                 cmap(63,:), ...
                 'LineWidth', opt.plot.lineWidth, ...
                 'DisplayName', 'Optimum Range' );
    hold on;

    ubIdx = ubIdx+1;
    
end


% plot line graph showing confidence limits and noise
XMeshPlotRev = [ XMeshPlot; flipud(XMeshPlot) ];
YPlotCIRev = [ YLong-YCI; flipud(YLong+YCI) ];

pRef(2) = fill( XMeshPlotRev, ...
             YPlotCIRev, ...
             cmap(25,:), ...
             'LineWidth', opt.plot.lineWidth, ...
             'DisplayName', 'Confidence Limits' );

if ubIdx == 1
    hold on; % for some reason no optimum range plotted
end


YPlotNoiseRev = [ YLong-noise; flipud(YLong+noise) ];
pRef(3) = fill( XMeshPlotRev, ...
             YPlotNoiseRev, ...
             cmap(30,:), ...
             'LineWidth', opt.plot.lineWidth, ...
             'DisplayName', 'Noise' );

         
% plot the bagged prediction
pRef(1) = plot( XMeshPlot, ...
             YLong, ...
             'Color', lineMap(j,:), ...
             'LineWidth', opt.plot.lineWidth, ...
             'DisplayName', 'Surrogate Prediction' );
         
end



function pRef = plotFn2D( XMeshPlot, YLong, YOptMax, nPts, opt )


YMesh = reshape( YLong, nPts(2), nPts(1) );

switch opt.contourType
    case 'Lines'
        cRange = opt.lossLim(1):opt.contourStep:opt.lossLim(2);
        [ cMatrix, cObj ] = contour( ...
                             XMeshPlot(:,:,1), ...
                             XMeshPlot(:,:,2), ...
                             YMesh, ...
                             cRange, ...
                            'LineWidth', 1.5, ...
                            'ShowText', 'on', ...
                            'LabelSpacing', 4*72 );
        cObj.LevelList = round( cObj.LevelList, 2);
        clabel( cMatrix, cObj, 'Color', 'k', 'FontSize', 10 );

    case 'Solid'
        cRange = opt.lossLim(1):opt.contourStep:opt.lossLim(2);
        [ cMatrix, cObj ] = contourf( ...
                             XMeshPlot(:,:,1), ...
                             XMeshPlot(:,:,2), ...
                             YMesh, ...
                             cRange, ...
                            'LineWidth', 0.5, ...
                            'ShowText', 'off', ...
                            'LabelSpacing', 4*72 );
        cBar = colorbar;
        cBar.Label.String = opt.objectiveDescr;
        cBar.Limits = opt.lossLim;
        cBar.TickDirection = 'out';
        cBar.Ticks = opt.lossLim(1):opt.lossLim(2);

    case 'Optimum'
        cRange = opt.lossLim(1):opt.contourStep:opt.lossLim(2);
        [ ~, cObjFull ] = contour( ...
                             XMeshPlot(:,:,1), ...
                             XMeshPlot(:,:,2), ...
                             YMesh, ...
                             cRange, ...
                            'LineWidth', 1.5, ...
                            'ShowText', 'on', ...
                            'LabelSpacing', 4*72 );

        hold on;
        %YOptMin = round( YOptMin/opt.contourStep ) ...
        %                *opt.contourStep;
        YOptMax = round( YOptMax/opt.contourStep ) ...
                        *opt.contourStep;           
        optRange = [YOptMax YOptMax];
        [ ~, cObjOPt ] = contour( ...
                             XMeshPlot(:,:,1), ...
                             XMeshPlot(:,:,2), ...
                             YMesh, ...
                             optRange, ...
                            'LineWidth', 4, ...
                            'ShowText', 'on', ...
                            'LabelSpacing', 4*72 );
        cmap = parula(32);
        plot( optimaPlot(1), optimaPlot(2), '*', ...
                'MarkerEdgeColor', cmap(1,:), ...
                'MarkerSize', 20, ...
                'LineWidth', 2 );                                      

end

end


end

 

