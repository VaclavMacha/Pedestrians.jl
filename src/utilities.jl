"""
    distance(x, y)

Computes euclidian distance between `x` and `y`.
"""
distance(x, y) = norm(x .- y, 2)

"""
    direction(x, y; normed = true)
    
Computes direction from `x` to `y`. 
"""
function direction(x, y; normed = true)
    d = y .- x
    return normed ? d./norm(d) : d
end

"""
    direction_angle(x, y)

Computes angle in radians of the direction from `x` to `y`.
"""
function direction_angle(x, y)
    dir = direction(x, y)
    return atan(dir[2], dir[1])
end

"""
    euclidian(r::Real, ϕ::Real, origin = (0, 0))

Computes euclidian coordinates from the given polar coordinates coordinates `(r, ϕ)`.
"""
function euclidian(r::Real, ϕ::Real, origin = (0, 0))
    r >= 0 || throw(ArgumentError("r must be greater or equal to 0."))
    -π < ϕ <= π || throw(ArgumentError("ϕ must be from interval (-π, π]."))
    return origin .+ r .* (cos(ϕ), sin(ϕ))
end

"""
    polar(x::Real, y::Real)

Computes polar coordinates from the given 2D euclidian coordinates `(x, y)`.
"""
polar(x::Real, y::Real) = (hypot(x, y), atan(y, x))