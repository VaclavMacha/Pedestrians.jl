function blind_velocity!(p::Pedestrian, model)
    # find nearest checkpoint of target
    find_target!(model.strategy, p, model)
    dir = direction(p.pos, p.target)

    # compute velocity
    p.vel = min(norm(p.vel, 2) + p.acc * model.Δt, model.v_opt) .* dir
    return
end

function agent_step!(p, model)
    blind_velocity!(p, model)

    if p.isexit && norm(p.vel, 2)*model.Δt > distance(p.pos, p.target)
        move_agent!(p, clip(p.target, model), model)
        p.finished = true
    else
        move_agent!(p, model, model.Δt)
    end
end
