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
    pos::NTuple{2,Float64}
    width::Float64
end

abstract type Obstacle end
struct Rectangle <: Obstacle
    id::Int
    pos::NTuple{2,Float64} 
    width::Float64
    height::Float64
end

struct Target
    id::Int
    pos::NTuple{2,Float64} 
end

Base.@kwdef struct Room
    width::Float64 = 6
    height::Float64 = 5
    obstacle::Dict{Int, <:Obstacle} = Dict(
        1 => Rectangle(1, (2.4, 1.9), 1.2, 0.5),
    )
    entrance::Dict{Int, Door} = Dict(
        1 => Door(1, (1.05, height), 0.6),
        2 => Door(2, (2.7, height), 0.6),
        3 => Door(3, (4.35, height), 0.6)
    )
    exit::Dict{Int, Door} = Dict(1 => Door(1, (2.7, 0), 0.6))
    checkpoint::Dict{Int, Target} = Dict(
        1 => Target(1, (2.0, 4)),
        2 => Target(2, (3.0, 4)),
        3 => Target(3, (4.0, 4)),
        4 => Target(4, (2.0, 2.4)),
        5 => Target(5, (2.0, 1.9)),
        6 => Target(6, (4.0, 2.4)),
        7 => Target(7, (4.0, 1.9)),
    )
    target::Dict{Int, Target} = Dict(1 => Target(1, (3.0, 0)))
end

include("utilities.jl")

function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("plots.jl")
end

end # module
