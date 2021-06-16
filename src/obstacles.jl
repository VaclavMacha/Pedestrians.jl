abstract type Obstacle end

struct Rectangle <: Obstacle
    id::Int
    pos::NTuple{2,Float64} 
    width::Float64
    height::Float64
end

"""
    isinside(r::Rectangle, pos::NTuple{2, Float64})

Checks wheter give point `pos` lays inside of the rectangle `r`.
"""
function isinside(r::Rectangle, pos::NTuple{2, Float64})
    (xr, yr), w, h = r.pos, r.width, r.height
    return xr <= pos[1] <= xr + w && yr <= pos[2] <= yr + h
end

"""
    nearest(r::Rectangle, pos::NTuple{2, Float64})

Returns the nearest point from the border of the rectangle `r` to the point `pos`.
"""
function nearest(r::Rectangle, pos::NTuple{2, Float64})
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
    isvalid(r::Rectangle, pos::NTuple{2, Float64}, d_min)

Checks wheter give point `pos` is valid, i.e., if the distance to the nearest point of the rectangle `r` is greater or equal to the minimum distance `d_min`. 
"""
function isvalid(r::Rectangle, pos::NTuple{2, Float64}, d_min = 0)
    isinside(r, pos) && return false
    return distance(nearest(r, pos), pos) >= d_min
end