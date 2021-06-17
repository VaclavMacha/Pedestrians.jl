"""
    TimeStrategy

Abstract type that represents all time strategies for simulations. Each concrete strategy must have the following fields
- `iter::Int`: current iteration 
- `counter::Int`: total number of pedestrians (not only the current state)
"""
abstract type TimeStrategy end

add_pedestrian!(model) = add_pedestrian!(model.timestrategy, model)

Base.@kwdef mutable struct Basic <: TimeStrategy
    iter::Int = 0
    counter::Int = 0
    at::Int = 20
end

function add_pedestrian!(time::Basic, model)
    if mod(time.iter, time.at) == 0 && time.counter < model.n
        for (~, d) in model.room.entrances
            time.counter += 1
            pos = clip(middle(d), model)
            vel = (0., -model.v_opt)
            p = Pedestrian(model.n + 1, pos; vel)

            isvalid(p, model, pos) || continue
            add_agent!(pos, model; vel)
        end
    end
end

function simulation_step!(model)
    genocide!(model, hasfinished) # remove all agents that left the room
    add_pedestrian!(model) # add new pedestrians
    step!(model, agent_step!) # move pedestrians
    update_time!(model)
    return
end

function update_time!(model)
    time = model.timestrategy
    time.iter += 1
end