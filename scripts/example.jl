using Revise

using Pedestrians
using Plots

# create model
k = 500
model = build_model()

@time anim = @animate for i in 1:k
    title = string("Blind velocity: ", lpad(i, 3, " "))
    makeplot(model; title, addview = true)
    simulation_step!(model)
end;
gif(anim, "./assets/blind_velocity.gif", fps = 10)
