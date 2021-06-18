Base.@kwdef struct Parameters
    room::Room = Room()
    target_strategy::TargetStrategy = Nearest()
    move_strategy::MoveStrategy = JancaMove()
    time_strategy::TimeStrategy = Basic()

    Δt::Float64 = 0.05     # time step
    n::Float64 = 300       # maximal number of pedestrians
end

function Base.show(io::IO, model::AgentBasedModel)
    println(io, "Pedestrian model:")
    println(io, " ⋅ pedestrians: ", length(model.agents))
    println(io, " ⋅ scheduler: ", model.scheduler)
    println(io, " ⋅ ", model.room)
    println(io, " ⋅ ", model.target_strategy)
    println(io, " ⋅ ", model.move_strategy)
    print(io,   " ⋅ ", model.time_strategy)
    return
end

build_model(; spacing = 0.01, kwargs...) = build_model(Parameters(; kwargs...); spacing)

function build_model(pars::Parameters; scheduler = random_activation, spacing = 0.01)
    r = pars.room.shape
    space2d = ContinuousSpace((r.width, r.height), spacing; periodic = false)
    model = ABM(Pedestrian, space2d; scheduler, properties = pars)
    model.maxid[] = model.time_strategy.counter
    return model
end

function simulation_step!(model)
    genocide!(model, hasfinished) # remove all agents that left the room
    add_pedestrian!(model) # add new pedestrians
    step!(model, pedestrian_step!) # move pedestrians
    update_time!(model)
    return
end
