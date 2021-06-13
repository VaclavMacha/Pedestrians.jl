module Pedestrians

using Agents
using LinearAlgebra
using Random
using Requires

export Pedestrian, Room, Door, Obstacle, Rectangle

# basic types
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

struct Door
    id::Int
    pos1::NTuple{2,Float64}
    pos2::NTuple{2,Float64}
end

abstract type Obstacle end
struct Rectangle <: Obstacle
    id::Int
    pos::NTuple{2,Float64} 
    width::Float64
    height::Float64
end

Base.@kwdef struct Room
    width::Float64 = 6
    height::Float64 = 5
    obstacle::Dict{Int, <:Obstacle} = Dict(
        1 => Rectangle(1, (2.4, 1.9), 1.2, 0.5),
    )
    entrance::Dict{Int, Door} = Dict(
        1 => Door(1, (1.05, height), (1.65, height)),
        2 => Door(2, (2.7, height), (3.3, height)),
        3 => Door(3, (4.35, height), (4.95, height))
    )
    exit::Dict{Int, Door} = Dict(1 => Door(1, (2.7, 0), (3.3, 0)))
end

include("utilities.jl")

function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("plots.jl")
end

end # module
