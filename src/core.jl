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

    # history
    position::Matrix{T} = zeros(0, 2)
    velocity::Matrix{T} = zeros(0, 2)
end

Pedestrian(id, pos; kwargs...) = Pedestrian(; id, pos, kwargs...)

"""
    isvalid(p::Pedestrian, pos, radius)

Checks wheter give position `pos` is valid with respect to pedestrian `p`. 
"""
function isvalid(p::Pedestrian, pos::Point, radius::Real; social::Bool = false)
    radius_p = social ? p.rlims[2] : p.radius
    return distance(p.pos, pos) >= radius_p + radius
end

"""
    isvalid(p1::Pedestrian, p2::Pedestrian)

Checks wheter pedestrian `p2` has valid position with respect to pedestrian `p1`. 
"""
function isvalid(p1::Pedestrian, p2::Pedestrian; kwargs...)
    return isvalid(p1, p2.pos, p2.radius; kwargs...)
end

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

Base.@kwdef struct Model{T<:Real}
    # room specification
    room::Room

    # strategies
    time_strategy::TimeStrategy
    schedule_strategy::ScheduleStrategy
    target_strategy::TargetStrategy
    move_strategy::MoveStrategy

    # pedestrians
    pedestrians::Dict{Int, Pedestrian} = Dict{Int, Pedestrian}()
    history::Dict{Int, Pedestrian} = Dict{Int, Pedestrian}()

    # additional parameters
    Δt::T = 0.05
    maxid::Ref{Int} = Ref(0)
    iter::Ref{Int} = Ref(0)
    safe_add::Bool = true
    stop::Ref{Bool} = Ref(false)
end

function Model(
    room,
    time_strategy,
    schedule_strategy,
    target_strategy,
    move_strategy,
    kwargs...
)
    return Model(;
        room,
        time_strategy,
        schedule_strategy,
        target_strategy,
        move_strategy,
        kwargs...
    )
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

set_stop!(m::Model) = m.stop[] = true
maxid(m::Model) = m.maxid[]
npads(m::Model) = isempty(m.pedestrians)
iter(m::Model) = m.iter[]
allids(m::Model) = collect(keys(m.pedestrians))
allpedestrians(m::Model) = collect(values(m.pedestrians))

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
function remove_pedestrian!(m::Model, p::Pedestrian)
    m.history[p.id] = deepcopy(p)
    delete!(m.pedestrians, p.id)
end

"""
    move_pedestrian!(m::Model, p::Pedestrian)

Move pedestrian `p` based on its position and velocity or remove `p` from model if in exit.
"""
function move_pedestrian!(m::Model, p::Pedestrian)
    p.velocity = vcat(p.velocity, [p.vel[1] p.vel[2]])
    p.position = vcat(p.position, [p.pos[1] p.pos[2]])
    p.finished && remove_pedestrian!(m, p)

    if p.isexit && norm(p.vel, 2)*m.Δt > distance(p.pos, p.target)
        p.finished = true
        remove_pedestrian!(m, p)
    else
        p.pos = p.pos .+ p.vel .* m.Δt
    end
end

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

function run!(m::Model, iter)

    bar = Progress(iter; showspeed = true)
    for i in 1:iter
        step!(m)

        # progress bar
        k = length(keys(m.pedestrians))
        next!(bar; showvalues = [
                (:iter, i),
                (:pedestrians, k)
        ])
        if m.stop[]
            finish!(bar)
            break
        end
    end
    return
end
