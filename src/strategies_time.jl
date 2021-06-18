"""
    TimeStrategy

Abstract type that represents all time strategies for simulations. Each concrete strategy must have the following fields
- `iter::Int`: current iteration 
- `counter::Int`: total number of pedestrians (not only the current state)
"""
abstract type TimeStrategy end

function update_time!(model)
    time = model.time_strategy
    time.iter += 1
end

add_pedestrian!(model) = add_pedestrian!(model.time_strategy, model)

# bais time strategy
Base.@kwdef mutable struct Basic <: TimeStrategy
    iter::Int = 0
    counter::Int = 0
    at::Int = 20
end

function add_pedestrian!(time::Basic, model)
    if mod(time.iter, time.at) == 0 && time.counter < model.n
        for d in model.room.entrances
            time.counter += 1
            pos = clip(middle(d), model)
            vel = (0., -model.move_strategy.v_opt)
            p = Pedestrian(model.n + 1, pos; vel)

            isvalid(model.room, pos, p.radius) || continue
            add_agent!(pos, model; vel)
        end
    end
end