# Sleef.jl
[![Travis Build Status](https://travis-ci.org/JuliaMath/Sleef.jl.svg?branch=master)](https://travis-ci.org/JuliaMath/Sleef.jl)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/j7lpafn4uf1trlfi/branch/master?svg=true)](https://ci.appveyor.com/project/musm/sleef-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/JuliaMath/Sleef.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaMath/Sleef.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaMath/Sleef.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaMath/Sleef.jl?branch=master)

A port of the [SLEEF math library](https://github.com/shibatch/sleef) (original author Naoki Shibata) in pure Julia. This port includes a few extras including an `exp10` function and many bug fixes in the original code. It remains, however, not reliable for large argument values for the trigonometric functions. The library supports Float32 and Float64 types.


# Usage

We recommend running Julia with `-O3` for maximal performance using `Sleef.jl` and to also build a custom system image by running
```julia
# Pkg.add("WinRPM"); WinRPM.install("gcc")  # on Windows please first run this line
julia> include(joinpath(dirname(JULIA_HOME),"share","julia","build_sysimg.jl"))
julia> build_sysimg(force=true)
```
and then to restart `julia`; this will ensure you are taking full advantage of hardware [FMA](https://en.wikipedia.org/wiki/FMA_instruction_set)  if your CPU supports it.


To use  `Sleef.jl`
```julia
julia> Pkg.clone("https://github.com/JuliaMath/Sleef.jl.git")

julia> using Sleef

julia> Sleef.sin(2.3)
0.7457052121767203

julia> Sleef.sin(2.3f0)
0.74570525f0

julia> Sleef.exp(3.0)
20.085536923187668

julia> Sleef.exp(3f0)
20.085537f0
```

The exported functions include (within 1 ulp)
```julia
sin, cos, tan, asin, acos, atan, atan2, sincos, sinh, cosh, tanh,
    asinh, acosh, atanh, log, log2, log10, log1p, ilog2, exp, exp2, exp10, expm1, ldexp, cbrt, pow
 ```
 Faster variants include (within 3 ulp)

 ```julia
sin_fast, cos_fast, tan_fast, sincos_fast, asin_fast, acos_fast, atan_fast, atan2_fast, log_fast, cbrt_fast
```

# Benchmarks

You can benchmark the performance of the Sleef.jl math library on your machine by running

```julia
include(joinpath(Pkg.dir("Sleef"), "benchmark", "benchmark.jl"))
```