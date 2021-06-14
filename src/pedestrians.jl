Base.@kwdef mutable struct Pedestrian <: AbstractAgent
    # mandatory properties
    id::Int
    pos::NTuple{2,Float64}
    vel::NTuple{2,Float64} = (0., 0.)

    # additional properties
    target::NTuple{2,Float64} = pos # target position
    isexit::Bool = false   # true if target position represents exit
    acc::Float64 = 0.5     # acceleration
    radius::Float64 = 0.25 # pedestrian size
    φ::Float64 = 3π/4      # maximum change of a pedestrian course
end

Pedestrian(id, pos; kwargs...) = Pedestrian(; id, pos, kwargs...)

# static parameters
Base.@kwdef struct Parameters
    strategy::CheckpointStrategy = Nearest()
    room::Room = Room()
    w::Float64 = 0         # minimum distance from any obstacle
    s::Float64 = 1         # initial size of a pedestrian
    Δs::Float64 = 0        # step to reduce the pedestrian size
    τs::Float64 = 0.25     # minimum (physical) pedestrian size
    v_opt::Float64 = 1.3   # pedestrian optimum speed
    ν::Float64 = π/4       # pedestrian field of vision
    φ::Float64 = 3π/4      # maximum change of a pedestrian course
    a::Float64 = 0.5       # pedestrian acceleration
    a_crisis::Float64 = 60 # acceleration if an arch occurs
    ϑ::Float64 = π/32      # field of vision if an arch occurs
    Δt::Float64 = 0.05     # time step
end


# Selection strategies for targets
struct Nearest <: CheckpointStrategy end

function find_target!(::Nearest, p::Pedestrian, model)
    pos = p.pos
    dist = Inf
    isexit = false

    # find nearest checkpoint
    for t in values(model.room.checkpoints)
        t_pos = nearest(t, p.pos)
        p.pos[2] > t_pos[2] || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || d == dist && rand() > 0.5
            pos, dist = t_pos, d 
        end
    end

    # find nearest exit
    for t in values(model.room.exits)
        t_pos = nearest(t, p.pos, model.τs)
        p.pos[2] > t_pos[2] || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || d == dist && rand() > 0.5
            pos, dist, isexit = t_pos, d, true
        end
    end
    p.target = pos
    p.isexit = isexit
    return
end

function blind_velocity!(p::Pedestrian, model)
    # find nearest checkpoint of target
    find_target!(model.strategy, p, model)
    dir = direction(p.pos, p.target)

    # compute velocity
    p.vel = min(norm(p.vel, 2) + p.acc * model.Δt, model.v_opt) .* dir
    return
end