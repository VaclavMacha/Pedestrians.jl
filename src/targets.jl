abstract type Target end

# Checkpoint type
struct Checkpoint{T<:Real} <: Target
    pos::Point{T} 
end

"""
    nearest(c::Checkpoint, pos::Point)

Returns position of the checkpoint `c`. 
"""
nearest(c::Checkpoint, ::Point) = c.pos

"""
    distance(p::Pedestrian, c::Checkpoint)

Returns euclidian distance of the pedestrian `p` to the checkpoint `c`. 
"""
distance(p::Pedestrian, c::Checkpoint, pos::Point = p.pos) = distance(pos, c.pos)

# Door type
struct Door{T<:Real} <: Target
    pos::Point{T} 
    width::Float64
end

"""
    nearest(d::Door, pos::Point, r = 0)

Returns the nearest point from the door `d` to the point `pos`. Argument `r` specifies minimum distance from the side of the door.
"""
function nearest(d::Door, pos::Point, r = 0)
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
    distance(p::Pedestrian, d::Door, pos::Point = p.pos)

Returns euclidian distance of the pedestrian `p` to the door `d`. 
"""
function distance(p::Pedestrian, d::Door, pos::Point = p.pos)
    return distance(pos, nearest(d, p.pos, p.radius))
end

"""
    middle(d::Door)

Returns euclidian coordinates of the middle point of the door `d`. 
"""
middle(d::Door) = (d.pos[1] + d.width/2, d.pos[2])

"""
    isinside(d::Door, pos::Point, r = 0)

Checks wheter given position lies inside the door area. Argument `r` specifies minimum distance from the side of the door.
"""
function isinside(d::Door, pos::Point, r = 0)
    x, y = pos
    (xd, yd), w = d.pos, d.width

    if xd <= x <= xd + w && yd - r <= y <= yd + r
        if min(distance(d.pos, pos), distance(d.pos .+ (w, 0), pos)) >= r
            return true
        end
    end
    return false
end

function isvalid(d::Door, pos::Point, r = 0)
    return distance(d.pos, pos) >= r && distance(d.pos .+ (d.width, 0), pos) >= r 
end