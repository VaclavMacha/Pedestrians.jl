module Pedestrians

using Agents
using LinearAlgebra
using Random
using Requires

export Pedestrian, Parameters
export Obstacle, Rectangle, Circle
export Room, Door, Checkpoint, Target
export Basic, Nearest

export build_model, simulation_step!

# basic types
const Point{T} = NTuple{2, T}

Base.@kwdef mutable struct Pedestrian <: AbstractAgent
    # mandatory properties
    id::Int
    pos::NTuple{2,Float64}
    vel::NTuple{2,Float64} = (0., 0.)

    # additional properties
    finished::Bool = false
    target::NTuple{2,Float64} = pos # target position
    isexit::Bool = false       # true if target position represents exit
    acc::Float64 = 0.5         # acceleration
    radius_min::Float64 = 0.1 # physical pedestrian size
    radius::Float64 = 0.25      # social pedestrian size
    φ::Float64 = 3π/4          # maximum change of a pedestrian course
end

Pedestrian(id, pos; kwargs...) = Pedestrian(; id, pos, kwargs...)
hasfinished(p::Pedestrian) = p.finished

include("utilities.jl")
include("targets.jl")
include("obstacles.jl")
include("rooms.jl")
include("strategies_time.jl")
include("strategies_target.jl")
include("strategies_move.jl")

Base.@kwdef struct Parameters
    timestrategy::TimeStrategy = Basic()
    strategy::TargetStrategy = Nearest()
    room::Room = Room()
    w::Float64 = 0         # minimum distance from any obstacle
    s::Float64 = 1         # initial size of a pedestrian
    Δs::Float64 = 0.075        # step to reduce the pedestrian size
    τs::Float64 = 0.25     # minimum (physical) pedestrian size
    v_opt::Float64 = 1.3   # pedestrian optimum speed
    ν::Float64 = π/4       # pedestrian field of vision

    # Course change
    kr::Int64 = 10
    φ::Float64 = 3π/4  # maximum change of a pedestrian course
    φmax::Float64 = 2π # maximum change of a pedestrian course if norm(vel) == 0
    Δφ::Float64 = 0.1

    # shortening
    Δr::Float64 = 0.05

    a::Float64 = 0.5       # pedestrian acceleration
    a_crisis::Float64 = 60 # acceleration if an arch occurs
    ϑ::Float64 = π/32      # field of vision if an arch occurs
    Δt::Float64 = 0.05     # time step
    n::Float64 = 300       # maximal number of pedestrians
end

build_model(; spacing = 0.01, kwargs...) = build_model(Parameters(; kwargs...); spacing)

function build_model(pars::Parameters; scheduler = random_activation, spacing = 0.01)
    r = pars.room.shape
    space2d = ContinuousSpace((r.width, r.height), spacing; periodic = false)
    model = ABM(Pedestrian, space2d; scheduler, properties = pars)
    model.maxid[] = model.timestrategy.counter
    return model
end

function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("plots.jl")
end

end # module
