# Efficient First-Order Algorithms for Adaptive Signal Denoising

Matlab reproducible experiments from the following preprint:

Dmitrii Ostrovskii, Zaid Harchaoui. Efficient First-Order Algorithms for Adaptive Signal Denoising. 

We use [**AdaFilter**](https://github.com/ostrodmit/AdaFilter) codes for the efficient implementation of adaptive signal denoising, including them as a submodule.

We also use [**CVX**](http://cvxr.com/cvx/) software for disciplined convex programming.

## Installation

1. Make sure that CVX is installed on your computer (commercial license is not needed). CVX installation instructions can be found [here](http://cvxr.com/cvx/doc/install.html).
2. Download or clone the repository, and add the following path in **MATLAB**:
```
AlgoRec/AdaFilter/code
```

## Running the experiments
The experiments, in the order of appearance in the paper, are launched via the following MATLAB commands: 
```
exp_perf_MP_random(N,ifReproduce);
exp_perf_MP_coherent(N,ifReproduce);
exp_certificates(N,ifReproduce);
exp_complexity(N,ifReproduce);
exp_sigm(N,ifReproduce);
```
Plots will appear in folders ``plots-<...>``, where ``<...>`` corresponds to the experiment. 

Simulation data for the first four experiments will appear in folder ``sims-perf``, and for the last experiment in folder ``sims-sigm``.

- Running a script with ``ifReproduce = 1`` will first launch simulations, and then produce plots for the obtained data. 
After that, ``ifReproduce = 0`` can be used to produce the plots without running the simulations again.

- ``N`` is the number of Monte-Carlo trials. To reproduce the figures from the paper, one must set ``N=20`` for ``exp_sigm`` and ``N=10`` in all other cases. Smaller values of ``N`` can be used to obtain faster (and less precise) results.
