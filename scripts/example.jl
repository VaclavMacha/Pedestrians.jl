using Revise

using Pedestrians
using Plots
using LinearAlgebra

target = (3, 0)
positions = [(1, 2), (5, 4), (2, 1), (2, 3.5), (5, 1.5), (4.5, 2.5), (1, 4)]

ps = map(enumerate(positions)) do (i, pos)
    vel = target .- pos
    vel = 0.5 .* vel ./ norm(vel,2)
    Pedestrian(i, pos, 1; vel)
end

r = Room()

@time begin
    plt = makeplot(r)
    makeplot!(plt, ps; addview = true)
end