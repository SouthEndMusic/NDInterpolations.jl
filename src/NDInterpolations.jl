module NDInterpolations
using KernelAbstractions # Keep as dependency or make extension?
using Adapt: @adapt_structure
using EllipsisNotation

abstract type AbstractInterpolationDimension end

struct NDInterpolation{
    N_in, N_out, ID <: AbstractInterpolationDimension, uType <: AbstractArray}
    interp_dims::NTuple{N_in, ID}
    u::uType
    function NDInterpolation(interp_dims, u)
        N_in = length(interp_dims)
        N_out = ndims(u) - N_in
        @assert N_out≥0 "The number of dimensions of u must be at least the number of interpolation dimensions."
        @assert ntuple(i -> length(interp_dims[i]), N_in)==size(u)[1:N_in] "For the first N_in dimensions of u the length must match the t of the corresponding interpolation dimension."
        new{N_in, N_out, eltype(interp_dims), typeof(u)}(interp_dims, u)
    end
end

@adapt_structure NDInterpolation

include("interpolation_utils.jl")
include("interpolation_dimensions.jl")
include("interpolation_methods.jl")
include("interpolation_parallel.jl")

# Multiple `t` arguments to tuple (can these 2 be done in 1?)
function (interp::NDInterpolation)(t_args::Vararg{Number}; kwargs...)
    interp(t_args; kwargs...)
end

function (interp::NDInterpolation)(
        out::AbstractArray, t_args::Vararg{Number}; kwargs...)
    interp(out, t_args; kwargs...)
end

# In place single input evaluation
function (interp::NDInterpolation{N_in})(
        out::Union{Number, AbstractArray{<:Number}},
        t::Tuple{Vararg{Number, N_in}};
        derivative_orders::NTuple{N_in, <:Integer} = ntuple(_ -> 0, N_in)
) where {N_in}
    validate_derivative_orders(derivative_orders)
    idx = get_idx(interp.interp_dims, t)
    @assert size(out)==size(interp.u)[(N_in + 1):end] "The size of the out must match the size of the last N_out dimensions of u."
    _interpolate!(out, interp, t, idx, derivative_orders)
end

# Out of place single input evaluation
function (interp::NDInterpolation)(t::Tuple{Vararg{Number, N_in}}; kwargs...
) where {N_in}
    out = make_out(interp, t)
    interp(out, t; kwargs...)
end

export NDInterpolation, LinearInterpolationDimension, ConstantInterpolationDimension,
       eval_unstructured, eval_unstructured!, eval_grid, eval_grid!

end # module NDInterpolations
