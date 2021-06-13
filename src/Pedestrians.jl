module Pedestrians

using Agents
using LinearAlgebra
using Random
using Requires

export Pedestrian
export Obstacle, Rectangle
export Room, Door, Checkpoint

# basic types
abstract type Obstacle end

include("utilities.jl")
include("obstacles.jl")
include("rooms.jl")
include("pedestrians.jl")

function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("plots.jl")
end

end # module
