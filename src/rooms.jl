struct Door
    id::Int
    pos::NTuple{2,Float64}
    width::Float64
end

function isinside(d::Door, pos::NTuple{2, Float64}, ylims, d_min = 0,)
    (x, y) = pos
    (xd, yd), w = d.pos, d.width

    if xd <= x <= xd + w && max(yd - d_min, ylims[1]) <= y <= min(yd + d_min, ylims[2])
        if min(distance(d.pos, pos), distance(d.pos .+ (w, 0), pos)) >= d_min
            return true
        end
    end
    return false
end

"""
    nearest(d::Door, pos::NTuple{2, Float64}, d_min = 0)

Returns the nearest point from the door `d` to the point `pos`. Argument `d_min` specifies minimum distance of the side of the door.
"""
function nearest(d::Door, pos::NTuple{2, Float64}, d_min = 0)
    (xd, yd), w = d.pos, d.width
    x, ~ = pos
    return if x < xd + d_min
        (xd + d_min, yd)
    elseif x > xd + w - d_min
        (xd + w - d_min, yd)
    else
        (x, yd)
    end
end

middle(d::Door) = (d.pos[1] + d.width/2, d.pos[2])

struct Checkpoint
    id::Int
    pos::NTuple{2,Float64} 
end

"""
    nearest(c::Checkpoint, pos::NTuple{2, Float64})

Returns position of the checkpoint `c`. 
"""
nearest(c::Checkpoint, ::NTuple{2, Float64}) = c.pos

Base.@kwdef struct Room
    width::Float64 = 6
    height::Float64 = 5
    obstacles::Dict{Int, <:Obstacle} = Dict(
        1 => Rectangle(1, (2.4, 1.9), 1.2, 0.5),
    )
    entrances::Dict{Int, Door} = Dict(
        1 => Door(1, (1.05, height), 0.6),
        2 => Door(2, (2.7, height), 0.6),
        3 => Door(3, (4.35, height), 0.6)
    )
    exits::Dict{Int, Door} = Dict(1 => Door(1, (2.7, 0), 0.6))
    checkpoints::Dict{Int, Checkpoint} = Dict(
        1 => Checkpoint(1, (2.0, 4)),
        2 => Checkpoint(2, (3.0, 4)),
        3 => Checkpoint(3, (4.0, 4)),
        4 => Checkpoint(4, (2.0, 2.4)),
        5 => Checkpoint(5, (2.0, 1.9)),
        6 => Checkpoint(6, (4.0, 2.4)),
        7 => Checkpoint(7, (4.0, 1.9)),
    )
end

function isvalid(r::Room, pos::NTuple{2, Float64}, d_min = 0)
    w, h = r.width, r.height
    for (~, d) in r.entrances
        isinside(d, pos, (0, h), d_min) && return true
    end
    for (~, d) in r.exits
        isinside(d, pos, (0, h), d_min) && return true
    end
    return d_min <= pos[1] <= w - d_min && d_min <= pos[2] <= h - d_min
end