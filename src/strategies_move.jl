function isvalid(p1::Pedestrian, p2::Pedestrian, pos)
    return norm(pos .- p2.pos, 2) > p1.radius + p2.radius
end

function reduce_size!(p::Pedestrian, model)
    p.radius = max(p.radius - model.Δs, p.radius_min)
    return
end

function move_pedestrian!(p, model)
    Δt = model.Δt
    d = distance(p.pos, p.target)
    vn = norm(p.vel, 2)
    if p.isexit && vn*Δt > d
        p.finished = true
        kill_agent!(p, model)
    else
        move_agent!(p, model, Δt)
    end
end

function blind_velocity!(p::Pedestrian, model)
    find_target!(p, model)
    p.finished && return 

    # compute velocity
    dir = direction(p.pos, p.target)
    p.vel = min(norm(p.vel, 2) + p.acc * model.Δt, model.v_opt) .* dir
    return
end

function positions_shorten(p, model, r = p.radius, r_max = norm(p.vel, 2)*model.Δt)
    φ0, origin = direction_angle(p.vel), p.pos

    # compute coordinates
    pos = Point[]
    for ri in range(0, r_max; length = model.kr)
        ri == 0 && continue
        posi = euclidian(ri, φ0, origin)
        if isvalid(model.room, posi, r)
            push!(pos, posi)
        else
            break
        end
    end
    return reverse(pos)
end

function positions_turn(p, model, r = p.radius, r_max = norm(p.vel, 2)*model.Δt)
    φ, φ0, origin = p.φ, direction_angle(p.vel), p.pos

    # compute coordinates
    pos = Point[]
    for φi in 0:model.Δφ:φ/2
            j = rand([-1, 1])
            posi = euclidian(r_max, φ0 + j*φi, origin)
            isvalid(model.room, posi, r) && push!(pos, posi)
            φi == 0 && continue # add 0 angle only once
            posi = euclidian(r_max, φ0 - j*φi, origin)
            isvalid(model.room, posi, r) && push!(pos, posi)
        end
    return pos
end

function pedestrian_step!(p, model)
    # update max view angle ???
    p.φ = norm(p.vel ,2) <= 1e-10 ? model.φmax : model.φ
    p.acc = norm(p.vel ,2) <= 1e-10 ? model.a_crisis : model.a
    vel = p.vel

    # blind velocity
    blind_velocity!(p, model)
    p.finished && return

    # find available positions
    r = p.radius
    r_max = norm(p.vel, 2)*model.Δt
    pos = vcat(
        positions_turn(p, model, r, r_max),
        positions_shorten(p, model, r, r_max),
    )
    
    # checks colisionn with other pedestrians
    for p2 in nearby_agents(p, model, 1.1*r_max)
        filter!(x -> Pedestrians.isvalid(p, p2, x), pos)
        isempty(pos) && break
    end

    # update velocity
    if !isempty(pos)
        p.vel = direction(p.pos, pos[1]; normed = false) ./ model.Δt
    else
        # reduce pedestrian size
        if p.radius > p.radius_min
            reduce_size!(p, model)
        else
            if norm(vel, 2) == 0

            elseif norm(vel, 2) > 0 && norm(p.vel, 2) > 0

            end
        end
        p.vel = (0, 0)
        return
    end
    move_pedestrian!(p, model)
    return
end