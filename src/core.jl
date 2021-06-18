const Point{T} = NTuple{2, T}

# ------------------------------------------------------------------------------------------
# Pedestrian
# ------------------------------------------------------------------------------------------
Base.@kwdef mutable struct Pedestrian{T<:Real}
    # mandatory properties
    id::Int
    pos::Point{T}
    vel::Point{T} = (0., 0.)
    target::Point{T} = pos

    # additional properties
    acc::Float64 = 0.5            # acceleration
    φ::Float64 = 3π/4             # maximum change of a pedestrian course
    radius::Float64 = 0.25        # social pedestrian size
    rlims::Point{T} = (0.1, 0.25) # physical pedestrian size

    # flags
    finished::Bool = false
    isexit::Bool = false
end

Pedestrian(id, pos; kwargs...) = Pedestrian(; id, pos, kwargs...)

"""
    isvalid(p::Pedestrian, pos, radius)

Checks wheter give position `pos` is valid with respect to pedestrian `p`. 
"""
function isvalid(p::Pedestrian, pos::Point, radius::Real)
    return distance(p.pos, pos) >= p.radius + radius
end

"""
    isvalid(p1::Pedestrian, p2::Pedestrian)

Checks wheter pedestrian `p2` has valid position with respect to pedestrian `p1`. 
"""
isvalid(p1::Pedestrian, p2::Pedestrian) = isvalid(p1, p2.pos, p2.radius)

# ------------------------------------------------------------------------------------------
# Room specification
# ------------------------------------------------------------------------------------------
abstract type RoomShape end
abstract type Obstacle end
abstract type Target end
abstract type Door <: Target end

struct Room
    shape::RoomShape
    obstacles::Vector{<:Obstacle}
    entrances::Vector{<:Door}
    exits::Vector{<:Door}
    checkpoints::Vector{<:Target}
end

"""
    isvalid(r::Room, pos::Point, r = 0)

Checks wheter give point `pos` is valid for given room configuration. 
"""
function isvalid(room::Room, pos::Point, r = 0)
    # checks wheter given position lies inside the room (with zero radius)
    isvalid(room.shape, pos, 0) || return false

    # checks wheter given position is valid with respect to obstacles
    for o in room.obstacles
        isvalid(o, pos, r) || return false
    end
    
    # checks wheter given position lies inside the door area
    for d in vcat(room.entrances, room.exits)
        isvalid(d, pos, r) || return false
        isinside(d, pos, r) && return true
    end
    return isvalid(room.shape, pos, r)
end

# ------------------------------------------------------------------------------------------
# Model specification
# ------------------------------------------------------------------------------------------
abstract type TimeStrategy end
abstract type ScheduleStrategy end
abstract type TargetStrategy end
abstract type MoveStrategy end

struct Model{T<:Real}
    # room specification
    room::Room

    # strategies
    time_strategy::TimeStrategy
    schedule_strategy::ScheduleStrategy
    target_strategy::TargetStrategy
    move_strategy::MoveStrategy

    # pedestrians
    pedestrians::Dict{Int, Pedestrian}

    # additional parameters
    Δt::T
    maxid::Ref{Int}
    iter::Ref{Int}
    safe_add::Bool
end

function Base.show(io::IO, m::Model)
    println(io, "Pedestrian model:")
    println(io, " ⋅ room: ", m.room.shape)
    println(io, "   - checkpoints: ", length(m.room.checkpoints))
    println(io, "   - obstacles: ", length(m.room.obstacles))
    println(io, "   - entrances: ", length(m.room.entrances))
    println(io, "   - exits: ", length(m.room.exits))
    println(io, " ⋅ pedestrians: ", length(m.pedestrians))
    print(io,   " ⋅ time strategy: ", m.time_strategy)
    println(io, " ⋅ schedule strategy: ", m.schedule_strategy)
    println(io, " ⋅ target strategy: ", m.target_strategy)
    println(io, " ⋅ move strategy: ", m.move_strategy)
    return
end

maxid(m::Model) = m.maxid[]
iter(m::Model) = m.iter[]
allids(m::Model) = collect(keys(m.pedestrians))
allpedestrians(m::Model) = collect(values(m.pedestrians))

function step!(m::Model)
    # add new pedestrians
    add_pedestrian!(m.time_strategy, m)

    # move all pedestrians
    for id in scheduler(m.schedule_strategy, m)
        pedestrian_step!(m.move_strategy, m, m.pedestrians[id])
    end

    # update counter
    m.iter[] += 1
    return
end

"""
    add_pedestrian!(m::Model, p::Pedestrian)

If the position of the pedestrian `p` is valid, adds `p` to the model `m` with smallest available `id`. 
"""
function add_pedestrian!(m::Model, p::Pedestrian)
    if m.safe_add
        if !isvalid(m.room, p.pos, p.radius)
            @warn "invalid pedestrian with respect to room specification"
            return 
        end
        for (~, p2) in m.pedestrians
            if !isvalid(p, p2)
                @warn "invalid pedestrian with respect to other pedestrians"
                return
            end
        end
    end

    m.maxid[] += 1
    p.id = m.maxid[]
    m.pedestrians[p.id] = p
    return
end

"""
    remove_pedestrian!(m::Model, p::Pedestrian)

Removes pedestrian `p` from the model `m`. 
"""
remove_pedestrian!(m::Model, p::Pedestrian) = delete!(m.pedestrians, p.id)

"""
    move_pedestrian!(m::Model, p::Pedestrian)

Move pedestrian `p` based on its position and velocity or remove `p` from model if in exit.
"""
function move_pedestrian!(m::Model, p::Pedestrian)
    p.finished && remove_pedestrian!(m, p)

    if p.isexit && norm(p.vel, 2)*m.Δt > distance(p.pos, p.target)
        p.finished = true
        remove_pedestrian!(m, p)
    else
        p.pos = p.pos .+ p.vel .* m.Δt
    end
end