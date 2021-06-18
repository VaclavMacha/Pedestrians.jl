function isvalid(p1::Pedestrian, p2::Pedestrian, pos, radius = p1.radius)
    return distance(pos, p2.pos) >= radius + p2.radius
end

function move_pedestrian!(p, model)
    p.finished && kill_agent!(p, model)

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

function positions_turn(
    model,
    φ0::Real, # direction angle
    φmax::Real,
    Δφ::Real, 
    origin::Point,
    r::Real,
    d_max::Real,
)

    # compute coordinates
    pos = Point[]
    for φi in 0:Δφ:φmax/2
            j = rand([-1, 1])
            posi = euclidian(d_max, φ0 + j*φi, origin)
            isvalid(model.room, posi, r) && push!(pos, posi)
            φi == 0 && continue # add 0 angle only once
            posi = euclidian(d_max, φ0 - j*φi, origin)
            isvalid(model.room, posi, r) && push!(pos, posi)
        end
    return pos
end

function positions_shorten(
    model, 
    φ0::Real, # direction angle
    origin::Point,
    r::Real,
    d_max::Real,
    d_k::Int,
)

    pos = Point[]
    for di in range(0, d_max; length = d_k)
        di == 0 && continue
        posi = euclidian(di, φ0, origin)
        if isvalid(model.room, posi, r)
            push!(pos, posi)
        else
            break
        end
    end
    return reverse(pos)
end

# move strategies
abstract type MoveStrategy end

pedestrian_step!(p, model) = pedestrian_step!(model.move_strategy, p, model)

# Janca Move
Base.@kwdef struct JancaMove{T<:AbstractFloat} <: MoveStrategy
    # blind velocity
    acc::T = 0.5     # pedestrian acceleration
    v_opt::T = 1.3 # pedestrian optimum speed

    # Course change
    φ::T = 3π/4  # maximum change of a pedestrian course
    φmax::T = 2π # maximum change of a pedestrian course if norm(vel) == 0
    Δφ::T = 0.1  # step

    # shortening
    d_k::Int64 = 10 # number of shortening steps

    # size reduction
    Δr::T = 0.075 # number of shortening steps

    # crisis
    acc_crisis::T = 60.0 # acceleration if an arch occurs
    ϑ::T = π/32      # field of vision if an arch occurs
end

function pedestrian_step!(pars::JancaMove, p, model)
    # update max view angle ???
    vel = p.vel
    p.acc = norm(vel, 2) == 0 ? pars.acc_crisis : pars.acc
    p.φ = pars.φ
    
    # find targets
    find_target!(p, model)
    p.finished && move_pedestrian!(p, model)

    # blind velocity
    dir = direction(p.pos, p.target)
    p.vel = min(norm(p.vel, 2) + p.acc * model.Δt, pars.v_opt) .* dir

    # find available positions
    if norm(vel ,2) == 0 && p.isexit
        p.φ = pars.φmax
    end
    φ0 = direction_angle(p.vel)
    d_max = norm(p.vel, 2)*model.Δt
    pos = vcat(
        positions_turn(model, φ0, pars.φmax, pars.Δφ, p.pos, p.radius, d_max),
        positions_shorten(model, φ0, p.pos, p.radius, d_max, pars.d_k),
    )

    for p2 in allagents(model)
        p.id == p2.id && continue
        distance(p.pos, p2.pos) - (p.radius + p2.radius) >= d_max  && continue
        filter!(x -> isvalid(p, p2, x), pos)
        isempty(pos) && break
    end

    # update velocity
    if !isempty(pos)
        p.vel = direction(p.pos, pos[1]; normed = false) ./ model.Δt
    else
        # reduce pedestrian size
        if p.radius > p.rlims[1]
            p.radius = max(p.radius - pars.Δr, p.rlims[1])
        end
        p.vel = (0, 0)
    end
    move_pedestrian!(p, model)
    return
end

# Foo
Base.@kwdef struct GridSearch{T<:AbstractFloat} <: MoveStrategy
    # blind velocity
    v_opt::T = 1.3 # pedestrian optimum speed

    # Course change
    φ::T = 3π/4  # maximum change of a pedestrian course
    φmax::T = 2π # maximum change of a pedestrian course if norm(vel) == 0
    Δφ::T = 0.1  # step

    # shortening
    d_k::Int64 = 5 # number of shortening steps

    # size reduction
    Δr::T = 0.05 # number of shortening steps
end

function pedestrian_step!(pars::GridSearch, p, model)
    vel = p.vel
    p.φ = pars.φ
    
    # find targets
    find_target!(p, model)
    p.finished && move_pedestrian!(p, model)

    # blind velocity
    dir = direction(p.pos, p.target)
    p.vel = min(norm(p.vel, 2) + p.acc * model.Δt, pars.v_opt) .* dir

    # find available positions
    if norm(vel ,2) == 0 && p.isexit
        p.φ = pars.φmax
    end
    φ0 = direction_angle(p.vel)
    d_max = norm(p.vel, 2)*model.Δt
    pos = positions_grid(model, φ0, pars.φmax, pars.Δφ, p.pos, p.radius, pars.Δr, p.rlims, d_max, pars.d_k)


    for p2 in allagents(model)
        p.id == p2.id && continue
        distance(p.pos, p2.pos) - (p.radius + p2.radius) >= d_max  && continue
        filter!(x -> isvalid(p, p2, x[1], x[2]), pos)
        isempty(pos) && break
    end

    # update velocity
    if !isempty(pos)
        p.radius = pos[1][2]
        p.vel = direction(p.pos, pos[1][1]; normed = false) ./ model.Δt
    else
        p.vel = (0, 0)
    end
    move_pedestrian!(p, model)
    return
end

function positions_grid(
    model,
    φ0::Real, # direction angle
    φmax::Real,
    Δφ::Real, 
    origin::Point,
    r::Real,
    Δr::Real,
    rlims,
    d_max::Real,
    d_k::Int,
)
    rs = [
        max(rlims[1], r - Δr),
        r,
        min(r + Δr, rlims[2]),
    ] |> unique
    # compute coordinates
    pos = []
    skip = []
    for di in range(0, d_max; length = d_k)
        di == 0 && continue
        for φi in φmax/2:-Δφ:0
            for ri in rs
                j = rand([-1, 1])
                posi = euclidian(di, φ0 + j*φi, origin)
                if !in((j*φi, ri), skip) && isvalid(model.room, posi, ri)
                    push!(pos, (posi, ri))
                else
                    push!(skip, (j*φi, ri))
                end
                φi == 0 && continue # add 0 angle only once
                posi = euclidian(di, φ0 - j*φi, origin)
                if !in((-j*φi, ri), skip) && isvalid(model.room, posi, ri)
                    push!(pos, (posi, ri))
                else
                    push!(skip, (- j*φi, ri))
                end
            end
        end
    end
    return reverse(pos)
end