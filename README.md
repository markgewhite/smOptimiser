# smOptimiser
Surrogate Model optimiser as alternative to Bayesian optimisation

Bayesian optimisation is an effective global optimiser for objective functions that are computationally expensive (*bayesopt* in MATLAB).
The optimiser takes a parsimonious approach carefully selecting where to make the next observation of the objective function.
However, with functions governed by continuous parameters the optimiser does not always find the global optimum as it makes very few observations. 
(It does much better with categorical parameters.)
The Bayesian optimiser's performance declines as the number of (continunous) parameters increases.
This situation is compounded when the objective function is noisy, as would be the case if that function yields the loss from a cross validation.
The subsampling variation leads to a variation in output.
With more iterations, the Bayesian optimiser will get closer but the cost rises exponentially.
The optimiser overhead can easily exceed the cost of the objective function in short order, perhaps by multiple times, even within 50 iterations.
Consequently, Bayesian optimisation becomes unweildy, unable to cope with complex functions with multiple continuous parameters.


**smOptimiser** is a proposed alternative. It still depends on a Bayesian model - the surrogate model - to represent the parameter space.
The model is trained on observations from a random search that is progressively constrained so observations are focused on regions of interest. 
It does this by reference to the emerging surrogate model to get an estimate of the likely value of the objective function at a newly proposed random point. 
That point is only accepted if it is below a threshold value which is gradually reduced. 
Some points with estimated values higher than this are admitted with diminishing probability to allow for the possibility that the true global optimum lies outside the current presumed region.

**Key points:**
- *smOptimiser* is considerably faster than *bayesopt*: over a 100x faster in these examples
- *smOptimiser* still performs well as the number of dimensions increases whereas *bayesopt* may start to miss the true optima
- *smOptimiser* can perform many more observations than *bayesopt*, if the objective function allows
- *smOptimiser* can still find the true optima when the number of objective function evaluations must be limited
- *bayesopt* will outperform *smOptimiser* when there are sufficient observations (enough to identify the global optimum with consistency)



**Function Call**

function [ optimum, model, opt, search ] = smOptimiser( objFn, paramDef, setup )

Arguments:
- objFn: objective function handle (all parameters specified in a single row table)
- paramDef: objective function's parameter definitions based on the same format as bayesopt: optimizervariable (https://uk.mathworks.com/help/stats/optimizablevariable.html)
- setup: optimiser's setup varable structure

Setup:
- .nOuter: number of outer iterations (default = 100)
- .nInner: after every nInner iterations make observation at the previously estimated optimum (default = 20)
- .maxTries: maximum number of times to try a random choice of parameter values that satisfies the constraint (default = 20)
- .initMaxLoss: initial maximum objective function loss (default = 1E6) rance for Particle Swarm Optimisation (optional; default = 1E-3)
- .tolPSO: function minimum tolerance for PSO (optional; default = 0.001)
- .maxIterPSO: maximum number of PSO search iterations (optional; default = 1000)
- .prcMaxLoss: percentile of observations for maxLoss (optional; default = 100)
- .verbose: output level: 0 = no output; 1 = commandline output (optional; default = 1)

Outputs:
- optimum: optimal parameters for the objective function
- model: Bayesian surrogate model structure (*fitrgp*)
- opt: optimisation record structure (PSO)
- search: random search record sructure



**Example**

The best way to demonstrate smOptimiser and compare it with bayesopt is to run the script in optDist.m.
It runs either optimisation procedure 200 times (specified by the method variable) and generates a probability distribution function for the two objective function's parameters. 
The true optimum is 104.599 in each dimension. The objective function have three optima (minima) in the range [0, 180].

*Scenario A: 50 iterations / 100 repeats* *

- Both smOptimiser and bayesopt find the true optimum (two distributions with highest peak at 104). 



*Scenario B: 25 iterations / 200 repeats* *

- smOptimiser still finds the true optimum but the peaks are much reduced. However, bayesopt can only find the optimum for one parameter, but not the other. The latter has no clear peak.


(To change the number of iterations vary nOuter and/or nInner.)


**Files**

- smOptimiser.m : optimisation procedure which contains sub-functions:

- - *randomParams* (constrained random search)
- - *roundParamsFn* (intermediate objective function for particle swarm which rounds integer or categorical parameters before calling the actual objective function)
- - *convParams* (converts particle swarm optimisation result back to integer/categorical format)

- setupObjFn.m : sets up the objective function and its parameter definitions (two examples included)

- objFnExample.m : example of an objective function with categorical, real and integer arguments.

- objFnMultiDimTest.m : example of a multi-dimensional objective function based on sine functions - the number of dimensions can be varied (this function was used in the above example)

- optDist.m : script repeatedly calls smOptimiser or bayesopt and generates optimal parameter distributions (example above)

- exampleOpt.m : simple script to demonstrate running either optimisation procedure with an objective function ('example') that has categorical, integer and real parameters

- refineOpt.m : script used to investigate the effect on accuracy of either procedure by varying the optimiser's own parameters. Ironically, it uses bayesopt for run the optimisation (optimisation within an optimisation).

- trueOptimum.m: script to use particle swarm optimisation to find the objective function's true global minimum. (The noise term must be removed first).


