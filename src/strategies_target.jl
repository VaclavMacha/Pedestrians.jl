abstract type TargetStrategy end

Base.@kwdef struct Nearest <: TargetStrategy
    p::Float64 = 0.5
    dmin::Float64 = 0
end

function find_target!(p::Pedestrian, model)
    #  find target based on selected strategy 
    find_target!(model.strategy, p, model)

    # checks wheter pedestrian is in exit
    if p.isexit && p.pos == p.target
        p.vel = (0., 0.)
        p.finished = true
        return
    end
end

function find_target!(s::Nearest, p::Pedestrian, model)
    pos = p.pos
    dist = Inf
    isexit = false

    # find nearest checkpoint
    for t in values(model.room.checkpoints)
        t_pos = nearest(t, p.pos)
        p.pos[2] > t_pos[2] || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || abs(d - dist) <= s.dmin && rand() > s.p
            pos, dist = t_pos, d 
        end
    end

    # find nearest exit
    for t in values(model.room.exits)
        t_pos = nearest(t, p.pos, model.τs)
        p.pos[2] > t_pos[2] || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || abs(d - dist) <= s.dmin && rand() > s.p
            pos, dist, isexit = t_pos, d, true
        end
    end
    p.target = pos
    p.isexit = isexit
    return
end