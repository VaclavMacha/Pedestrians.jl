function blind_velocity!(p::Pedestrian, model)
    find_target!(p, model)
    p.finished && return 

    # compute velocity
    dir = direction(p.pos, p.target)
    p.vel = min(norm(p.vel, 2) + p.acc * model.Δt, model.v_opt) .* dir
    return
end




function agent_step!(p, model)
    # update max view angle
    p.φ = norm(p.vel ,2) <= 1e-10 ? model.φmax : model.φ
    p.acc = norm(p.vel ,2) <= 1e-10 ? model.a_crisis : model.a

    # blind velocity
    blind_velocity!(p, model)
    p.finished && return
    
    pos = available_positions(p, model)
    for (~, p2) in model.agents
        p.id == p2.id && continue
        filter!(pos_i -> Pedestrians.isvalid(p, p2, pos_i), pos)
        isempty(pos) && break
    end
    if isempty(pos)
        p.vel = (0., 0.)
    else
        p.vel = direction(p.pos, pos[1]; normed = false) ./ model.Δt
    end
    if p.isexit && norm(p.vel, 2)*model.Δt > distance(p.pos, p.target)
        p.finished = true
        move_agent!(p, clip(p.target, model), model)
    else
        move_agent!(p, model, model.Δt)
    end
end

function isvalid(p1::Pedestrian, p2::Pedestrian, pos)
    return norm(pos .- p2.pos, 2) > p1.radius + p2.radius
end

function isvalid(p::Pedestrian, model, pos)
    isvalid(model.room, pos, p.radius) || return false
    for (~, o) in model.room.obstacles
        isvalid(o, pos, p.radius) || return false
    end
    return true
end
