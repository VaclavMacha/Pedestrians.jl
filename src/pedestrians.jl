Base.@kwdef mutable struct Pedestrian <: AbstractAgent
    # mandatory properties
    id::Int
    pos::NTuple{2,Float64}
    vel::NTuple{2,Float64} = (0., 0.)

    # additional properties
    target_id::Int      # id of the currenttarget
    acc::Float64 = 0.5  # acceleration
    radius::Float64 = 1 # pedestrian size
    φ::Float64 = 3π/4   # maximum change of a pedestrian course
end

Pedestrian(id, pos, target_id; kwargs...) = Pedestrian(; id, pos, target_id, kwargs...)