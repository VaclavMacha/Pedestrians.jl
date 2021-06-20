"""
    Basic <: TimeStrategy

Basic time strategy that adds new pedestrian to all available entrances every `at` iteration until `max_peds` pedestrians is added.

# Fields

- at::Int = 20
- max_peds::Int = 300
- vel_init::Point{<:Real} = initial velocity

"""
Base.@kwdef struct Basic{T} <: TimeStrategy
    at::Int = 20
    max_peds::Int = 300
    vel_init::Point{T} = (0.0, -1.3)
end

function add_pedestrian!(s::Basic, m::Model)
    if iter(m) == 0 || mod(iter(m), s.at) == 0
        for d in m.room.entrances
            maxid(m) >= s.max_peds && break
            add_pedestrian!(m, Pedestrian(0, middle(d); vel = s.vel_init))
        end
    end
    return
end