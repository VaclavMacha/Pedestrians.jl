module Pedestrians

using LinearAlgebra
using ProgressMeter
using Random
using Requires

export run!

include("utilities.jl")
include("core.jl")
include("room_elements.jl")
include("strategies_time.jl")
include("strategies_schedule.jl")
include("strategies_target.jl")
include("strategies_move.jl")
include("predefined.jl")

function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("plots.jl")
end

end # module
