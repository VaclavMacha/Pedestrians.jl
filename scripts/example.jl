using Revise

using Pedestrians
using Plots
using LinearAlgebra

target = (3, 0)
ps = map(enumerate([(3, 3), (1, 2), (5, 4), (2, 1)])) do (i, pos)
    vel = target .- pos
    vel = 0.5 .* vel ./ norm(vel,2)
    Pedestrian(i, pos, 1; vel)
end

r = Room()

@time begin
    plt = makeplot(r)
    makeplot!(plt, ps; addview = true)
end