"""
    Basic <: TimeStrategy

Basic time strategy that adds new pedestrian to all available entrances every `at` iteration until `max_peds` pedestrians is added.

# Fields

- at::Int = 20
- max_peds::Int = 300

"""
Base.@kwdef struct Basic <: TimeStrategy
    at::Int = 20
    max_peds::Int = 300
end

function add_pedestrian!(s::Basic, m::Model)
    if iter(m) == 0 || mod(iter(m), s.at) == 0
        for d in m.room.entrances
            maxid(m) >= s.max_peds && break
            add_pedestrian!(m, Pedestrian(0, middle(d)))
        end
    end
    return
end