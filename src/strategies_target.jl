function find_target!(m::Model, p::Pedestrian)
    #  find target based on selected target strategy 
    find_target!(m.target_strategy, m, p)

    # checks wheter pedestrian is in exit
    if p.isexit && p.pos == p.target
        p.vel = (0., 0.)
        p.finished = true
        return
    end
end

"""
    Nearest <: TargetStrategy

Basic target strategy that selects nearest (euclidian distance) target.  

# Fields

- p::Float64 = 0.5 
- ε::Float64 = 0.0

"""
Base.@kwdef struct Nearest <: TargetStrategy
    p::Float64 = 0.5
    ε::Float64 = 0
end

function find_target!(s::Nearest, m::Model, p::Pedestrian)
    dist = Inf
    k = length(m.room.checkpoints)

    # find nearest checkpoint
    for (i, t) in enumerate(vcat(m.room.checkpoints, m.room.exits))
        t_pos = nearest(t, p.pos)
        p.pos[2] > t_pos[2] || continue
        isreachable(m.room, p.pos, t_pos) || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || abs(d - dist) <= s.ε && rand() > s.p
            dist = d
            p.target = t_pos
            p.isexit = i > k
        end
    end
    return
end