# ------------------------------------------------------------------------------------------
# Room shapes
# ------------------------------------------------------------------------------------------
"""
    RoomRectangle(width, height)

Representation of the rectangle room of size (width, height) with origin in (0, 0)
"""
struct RoomRectangle{T<:Real} <: RoomShape
    width::T
    height::T
end

function Base.show(io::IO, r::RoomRectangle)
    print(io, "rectangle (width, height) = $(r.width)m x $(r.height)m")
    return
end

"""
    isvalid(s::RoomRectangle, pos::Point, r = 0)

Checks wheter give point `pos` lies inside of the rectangle room. 
"""
function isvalid(s::RoomRectangle, pos::Point, r = 0)
    w, h = s.width, s.height
    x, y = pos
    return r <= x <= w - r && r <= y <= h - r
end

# ------------------------------------------------------------------------------------------
# Simple checkpoints
# ------------------------------------------------------------------------------------------
struct Checkpoint{T<:Real} <: Target
    pos::Point{T} 
end

"""
    nearest(c::Checkpoint, pos::Point)

Returns position of the checkpoint `c`. 
"""
nearest(c::Checkpoint, ::Point) = c.pos

"""
    distance(p::Pedestrian, c::Checkpoint, pos::Point = p.pos)

Returns euclidian distance of the pedestrian `p` to the checkpoint `c`. 
"""
distance(p::Pedestrian, c::Checkpoint, pos::Point = p.pos) = distance(pos, c.pos)

struct HCheckpoint{T<:Real} <: Target
    pos::Point{T} 
    width::Float64
end

"""
    nearest(c::HCheckpoint, pos::Point)

Returns the nearest point from the checkpoint `c` to the point `pos`.
"""
function nearest(c::HCheckpoint, pos::Point)
    (xc, yc), w = c.pos, c.width
    x = pos[1]
    return if x < xc
        (xc, yc)
    elseif x > xc + w
        (xc + w, yc)
    else
        (x, yc)
    end
end

"""
    distance(p::Pedestrian, c::HCheckpoint, pos::Point = p.pos)

Returns euclidian distance of the pedestrian `p` to the checkpoint `c`. 
"""
function distance(p::Pedestrian, c::HCheckpoint, pos::Point = p.pos)
    return distance(pos, nearest(c, p.pos))
end

# ------------------------------------------------------------------------------------------
# Doors
# ------------------------------------------------------------------------------------------
struct HDoor{T<:Real} <: Door
    pos::Point{T} 
    width::Float64
end

"""
    nearest(d::HDoor, pos::Point, r = 0)

Returns the nearest point from the door `d` to the point `pos`. Argument `r` specifies minimum distance from the side of the door.
"""
function nearest(d::HDoor, pos::Point, r = 0)
    (xd, yd), w = d.pos, d.width
    x = pos[1]
    return if x < xd + r
        (xd + r, yd)
    elseif x > xd + w - r
        (xd + w - r, yd)
    else
        (x, yd)
    end
end

"""
    distance(p::Pedestrian, d::HDoor, pos::Point = p.pos)

Returns euclidian distance of the pedestrian `p` to the door `d`. 
"""
function distance(p::Pedestrian, d::HDoor, pos::Point = p.pos)
    return distance(pos, nearest(d, p.pos, p.radius))
end

"""
    middle(d::HDoor)

Returns euclidian coordinates of the middle point of the door `d`. 
"""
middle(d::HDoor) = (d.pos[1] + d.width/2, d.pos[2])

"""
    isinside(d::HDoor, pos::Point, r = 0)

Checks wheter given position lies inside the door area. Argument `r` specifies minimum distance from the side of the door.
"""
function isinside(d::HDoor, pos::Point, r = 0)
    x, y = pos
    (xd, yd), w = d.pos, d.width

    if xd <= x <= xd + w && yd - r <= y <= yd + r
        if min(distance(d.pos, pos), distance(d.pos .+ (w, 0), pos)) >= r
            return true
        end
    end
    return false
end

"""
    isvalid(d::Door, pos::Point, r = 0)

Checks wheter give position `pos` is valid with respect to pedestrian `p`. 
"""
function isvalid(d::Door, pos::Point, r = 0)
    return distance(d.pos, pos) >= r && distance(d.pos .+ (d.width, 0), pos) >= r 
end

# ------------------------------------------------------------------------------------------
# Obstacles
# ------------------------------------------------------------------------------------------
struct Rectangle{T<:Real} <: Obstacle
    pos::Point{T} 
    width::T
    height::T
end

"""
    isinside(r::Rectangle, pos::Point)

Checks wheter give point `pos` lies inside of the rectangle `r`.
"""
function isinside(r::Rectangle, pos::Point)
    (xr, yr), w, h = r.pos, r.width, r.height
    return xr <= pos[1] <= xr + w && yr <= pos[2] <= yr + h
end

"""
    nearest(r::Rectangle, pos::Point)

Returns the nearest point from the border of the rectangle `r` to the point `pos`.
"""
function nearest(r::Rectangle, pos::Point)
    isinside(r, pos) && throw(ArgumentError("position must be outside of the rectangle"))

    (xr, yr), w, h = r.pos, r.width, r.height
    x, y = pos
    return if x < xr
        if y < yr
            (xr, yr)
        elseif y > yr + h
            (xr, yr + h)
        else
            (xr, y)
        end
    elseif x > xr + w
        if y < yr
            (xr + w, yr)
        elseif y > yr + h
            (xr + w, yr + h)
        else
            (xr + w, y)
        end
    else
        if y < yr
            (x, yr)
        elseif y > yr + h
            (x, yr + h)
        end
    end
end

"""
    isvalid(o::Rectangle, pos::Point, r)

Checks wheter give point `pos` is valid, i.e., if the distance to the nearest point of the rectangle `o` is greater or equal to the minimum distance `r`. 
"""
function isvalid(o::Rectangle, pos::Point, r = 0)
    isinside(o, pos) && return false
    return distance(nearest(o, pos), pos) >= r
end