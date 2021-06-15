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
    direction_angle(d)

Computes angle in radians of the direction `d`.
"""
direction_angle(d) = atan(d[2], d[1])

"""
    direction_angle(x, y)

Computes angle in radians of the direction from `x` to `y`.
"""
direction_angle(x, y) = atan(direction(x, y))

"""
    euclidian(r::Real, ϕ::Real, origin = (0, 0))

Computes euclidian coordinates from the given polar coordinates coordinates `(r, ϕ)`.
"""
function euclidian(r::Real, ϕ::Real, origin = (0, 0))
    r >= 0 || throw(ArgumentError("r must be greater or equal to 0."))
    ϕ = mod1(ϕ + π, 2π) - π
    return origin .+ r .* (cos(ϕ), sin(ϕ))
end

"""
    polar(x::Real, y::Real)

Computes polar coordinates from the given 2D euclidian coordinates `(x, y)`.
"""
polar(x::Real, y::Real) = (hypot(x, y), atan(y, x))


function clip(pos::NTuple{2, Float64}, model)
    x, y = pos
    w, h = prevfloat(model.room.width), prevfloat(model.room.height)
    return (max(min(x, w), nextfloat(0.0)), max(min(y, h), nextfloat(0.0)))
end
