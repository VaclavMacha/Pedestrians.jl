using Revise

using Pedestrians
using Pedestrians.Agents
using Plots
using LinearAlgebra
using Printf

using Pedestrians: distance, direction

function clip(pos::NTuple{2, Float64}, model; ϵ = 1e-16)
    x, y = pos
    w, h = model.room.width, model.room.height
    return (max(min(x, w - ϵ), ϵ), max(min(y, h - ϵ), ϵ))
end

target = (3, 0)
positions = [(x, 4.5) for x in 0.5:0.5:5.5]

# create model
r = Room()
space2d = ContinuousSpace((r.width, r.height), 0.01; periodic = false)
model = ABM(Pedestrian, space2d, properties = Parameters())

ps = map(positions) do pos
    add_agent!(pos, model)
end

function agent_step!(p, model)
    blind_velocity!(p, model)

    if p.isexit && norm(p.vel, 2)*model.Δt > distance(p.pos, p.target)
        move_agent!(p, clip(p.target, model), model)
        kill_agent!(p, model)
    else
        move_agent!(p, model, model.Δt)
    end
end

k = 120
@time anim = @animate for i in 1:k
    plt = makeplot(r; title = "$i")
    makeplot!(plt, collect(values(model.agents)); addview = false)
    step!(model, agent_step!)
end;
gif(anim, "anim_fps15.gif", fps = 10)