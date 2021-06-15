abstract type TargetStrategy end

struct Nearest <: TargetStrategy end

function find_target!(::Nearest, p::Pedestrian, model)
    pos = p.pos
    dist = Inf
    isexit = false

    # find nearest checkpoint
    for t in values(model.room.checkpoints)
        t_pos = nearest(t, p.pos)
        p.pos[2] > t_pos[2] || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || d == dist && rand() > 0.5
            pos, dist = t_pos, d 
        end
    end

    # find nearest exit
    for t in values(model.room.exits)
        t_pos = nearest(t, p.pos, model.τs)
        p.pos[2] > t_pos[2] || continue
        
        d = distance(p.pos, t_pos)
        if d < dist || d == dist && rand() > 0.5
            pos, dist, isexit = t_pos, d, true
        end
    end
    p.target = pos
    p.isexit = isexit
    return
end