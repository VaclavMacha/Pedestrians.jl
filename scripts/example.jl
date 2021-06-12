using Revise

using Pedestrians
using Plots


ps = [
    Pedestrian(1, (3, 3), 1),
    Pedestrian(2, (1, 2), 1),
    Pedestrian(3, (5, 5), 1),
    Pedestrian(4, (2, 1), 1),
]

r = Room()

using Plots: Plot

plt = makeplot(r)
makeplot!(plt, ps)