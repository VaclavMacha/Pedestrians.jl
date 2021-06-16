abstract type RoomShape end

struct RoomRectangle{T<:Real} <: RoomShape
    width::T
    height::T
end

"""
    isvalid(s::RoomRectangle, pos::Point, r = 0)

Checks wheter give point `pos` layes inside of the rectangle room. 
"""
function isvalid(s::RoomRectangle, pos::Point, r = 0)
    w, h = s.width, s.height
    x, y = pos
    return r <= x <= w - r && r <= y <= h - r
end

# Room type
Base.@kwdef struct Room
    shape::RoomShape = RoomRectangle(6.0, 5.0)
    obstacles::Vector{<:Obstacle} = [
        Rectangle((2.4, 1.9), 1.2, 0.5),
    ]
    entrances::Vector{Door} = [
        Door((1.05, 5.0), 0.6),
        Door((2.7, 5.0), 0.6),
        Door((4.35, 5.0), 0.6),
    ]
    exits::Vector{Door} = [
        Door((2.7, 0.0), 0.6),
    ]
    checkpoints::Vector{<:Target} = [
        Checkpoint((2.0, 4.0)),
        Checkpoint((3.0, 4.0)),
        Checkpoint((4.0, 4.0)),
        Checkpoint((2.0, 2.4)),
        Checkpoint((2.0, 1.9)),
        Checkpoint((4.0, 2.4)),
        Checkpoint((4.0, 1.9)),
    ]
end

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
