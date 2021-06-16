abstract type Obstacle end

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