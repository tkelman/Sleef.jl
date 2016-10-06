using Sleef
using Base.Test

isnzero{T<:AbstractFloat}(x::T) = signbit(x)
ispzero{T<:AbstractFloat}(x::T) = !signbit(x)

function cmpdenorm{Tx<:AbstractFloat, Ty<:AbstractFloat}(x::Tx, y::Ty)
    sizeof(Tx) < sizeof(Ty) ? y = Tx(y) : x = Ty(x) # cast larger type to smaller type
    (isnan(x) && isnan(y)) && return true
    (isnan(x) || isnan(y)) && return false
    (isinf(x) != isinf(y)) && return false
    (x == Tx(Inf)  && y == Ty(Inf))  && return true
    (x == Tx(-Inf) && y == Ty(-Inf)) && return true
    if y == 0
        (ispzero(x) && ispzero(y)) && return true
        (isnzero(x) && isnzero(y)) && return true
        return false
    end
    (!isnan(x) && !isnan(y) && !isinf(x) && !isinf(y)) && return sign(x) == sign(y)
    return false
end

# the following compares the ulp between x and y.
# First it promotes them to the larger of the two types x,y
infh(::Type{Float64}) = 1e+300
infh(::Type{Float32}) = 1e+37
function countulp(T, x::AbstractFloat, y::AbstractFloat)
    X,Y = promote(x,y)
    x, y = T(X), T(Y) # Cast to smaller type
    (isnan(x) && isnan(y)) && return 0
    (isnan(x) || isnan(y)) && return 10000
    if isinf(x)
        (sign(x) == sign(y) && abs(y) > infh(T)) && return 0 # Relaxed infinity handling
        return 10001
    end
    (x ==  Inf && y ==  Inf) && return 0
    (x == -Inf && y == -Inf) && return 0
    if y == 0
        (x == 0) && return 0
        return 10002
    end
    if isfinite(x) && isfinite(y)
        return T(abs(X - Y)/eps(y))
    end
    return 10003
end
countulp{T<:AbstractFloat}(x::T, y::T) = countulp(T,x,y)

# get rid off annoying warnings from overwritten function
macro nowarn(expr)
    quote
        stderr = STDERR
        stream = open("null", "w")
        redirect_stderr(stream)
        result = $(esc(expr))
        redirect_stderr(stderr)
        close(stream)
        result
    end
end

# overide domain checking that base adheres to
using Base.MPFR.ROUNDING_MODE
for f in (:sin, :cos, :tan, :asin, :acos, :atan, :asinh, :acosh, :atanh, :log, :log10, :log2, :log1p)
    @eval begin
        import Base.$f
        @nowarn function ($f)(x::BigFloat)
            z = BigFloat()
            ccall($(string(:mpfr_,f), :libmpfr), Int32, (Ptr{BigFloat}, Ptr{BigFloat}, Int32), &z, &x, ROUNDING_MODE[])
            return z
        end
    end
end

strip_module_name(f::Function) = last(split(string(f), '.')) # strip module name from function f

# test the accuracy of a function where fun_table is a Dict mapping the function you want
# to test to a reference function
# xx is an array of values (which may be tuples for multiple arugment functions)
# tol is the acceptable tolerance to test against
function test_acc(T, fun_table, xx, tol; debug=false, tol_debug=5)
    @testset "accuracy $(strip_module_name(xfun))" for (xfun, fun) in fun_table
        rmax = 0.0
        rmean = 0.0
        xmax = map(zero, first(xx))
        for x in xx
            q = xfun(x...)
            c = fun(map(BigFloat,x)...)
            u = countulp(T,q,c)
            rmax = max(rmax, u)
            xmax = rmax == u ? x : xmax
            rmean += u
            if debug && u > tol_debug
                @printf("%s = %.20g\n%s  = %.20g\nx = %.20g\nulp = %g\n", strip_module_name(xfun), q, strip_module_name(fun), T(c), x, ulp(T(c)))
            end
        end
        rmean = rmean/length(xx)

        t = @test trunc(rmax,1) <= tol

        fmtxloc = isa(xmax, Tuple) ? string('(', join((@sprintf("%.5f", x) for x in xmax), ", "), ')') : @sprintf("%.5f", xmax)
        println(rpad(strip_module_name(xfun), 18, " "), ": max ", @sprintf("%f", rmax),
            rpad(" at x = "*fmtxloc, 40, " "),
            ": mean ", @sprintf("%f", rmean))
    end
end

function runtests()
    @testset "Sleef" begin
        include("dnml_nan.jl")
        include("accuracy.jl")
    end
end

runtests()

