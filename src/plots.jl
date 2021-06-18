using .Plots
using .Plots: Plot

export makeplot, set_palette!, set_main_color!, default_palette

# color definitions
function default_palette()
    return palette([
        RGB(0.5586, 0.1211, 0.4688),
        RGB(0.0000, 0.4470, 0.7410),
        RGB(0.8500, 0.3250, 0.0980),
        RGB(0.9290, 0.6940, 0.1250),
        RGB(0.4660, 0.6740, 0.1880),
        RGB(0.3010, 0.7450, 0.9330),
        RGB(0.6350, 0.0780, 0.1840),
    ])
end

const PALETTE = Ref{ColorPalette}(default_palette())
const MAIN_COLOR = Ref{RGB}(default_palette()[1])

function set_main_color!(c)
    MAIN_COLOR[] = parse(Colorant, c)
end

function set_palette!(pal; set_main = true)
    pal = palette(pal)
    PALETTE[] = pal
    set_main && set_main_color!(pal[1])
    return 
end

function get_color(id)
    pal = PALETTE[]
    return pal[mod1(id, length(pal))]
end
get_main_color() = MAIN_COLOR[]

# object shapes
function rectangle(pos::Point, w, h)
    x, y = pos
    return Shape(x .+ [0, w, w, 0], y .+ [0, 0, h, h])
end

function circle(pos::Point, r = 1; step = π/20)
    x, y = pos
    θ = range(-π, π; step)
    return Shape(x .+ r*sin.(θ), y .+ r*cos.(θ))
end

function circle_section(pos::Point, r = 1, θ0  = 0, θmax = 2π; step = π/20)
    x, y = pos
    coors = euclidian.(r, θ0 .+ range(-θmax/2, θmax/2; step), Ref(pos))

    return Shape(vcat(x, first.(coors)), vcat(y, last.(coors)))
end

# recipes
@recipe function f(s::RoomRectangle; px_meter = 100)
    w, h = s.width, s.height

    # set plot style
    seriestype  :=  :shape
    fillalpha := 0
    xlims := (- 0.01*w, 1.01*w)
    ylims := (- 0.01*h, 1.01*h)
    aspect_ratio := :equal
    label := ""
    linecolor --> get_main_color()
    linewidth --> 2
    legend --> false
    axis --> nothing
    framestyle --> :none
    size --> px_meter .* (w, h)

    # remove kwargs
    delete!(plotattributes, :px_meter)

    return rectangle((0, 0), w, h)
end

roomlims(s::RoomRectangle) = (s.width, s.height)

@recipe f(s::Rectangle) = [s]
@recipe function f(s::Vector{<:Rectangle})
    pos = getproperty.(s, :pos)
    w =getproperty.(s, :width)
    h = getproperty.(s, :height)

    # set plot style
    seriestype  := :shape
    label := ""
    linecolor --> get_main_color()
    fillcolor --> get_main_color()

    return rectangle.(pos, w, h)
end

@recipe function f(d::Door; add_checkpoints = false, radius = 0.1)
    pos = [d.pos, d.pos .+ (d.width, 0)]
    x, y = first.(pos), last.(pos)

    if add_checkpoints
        pos = [d.pos .+ (radius, 0), d.pos .+ (d.width - radius, 0)]
        x = hcat(x, first.(pos))
        y = hcat(y, last.(pos))
    end

    # set plot style
    seriestype  := :path
    label := ""
    marker := add_checkpoints ? [:square :vline] : :square
    linecolor := add_checkpoints ? [:white :gray] : :white
    linewidth := add_checkpoints ? [4 1] : 4
    markercolor := add_checkpoints ? [get_main_color() :gray] : get_main_color()
    markerstrokecolor := add_checkpoints ? [get_main_color() :gray] : get_main_color()
    markersize := add_checkpoints ? [4 6] : 4

    # remove kwargs
    delete!(plotattributes, :add_checkpoints)
    delete!(plotattributes, :radius)

    return x, y
end

@recipe f(c::Checkpoint) = [c]
@recipe function f(cs::Vector{<:Checkpoint})
    pos = getproperty.(cs, :pos)

    # set plot style
    seriestype  := :scatter
    label --> ""
    marker --> :x
    markersize --> 6
    markercolor --> :gray

    return first.(pos), last.(pos)
end

@recipe f(p::Pedestrian) = [p]
@recipe f(d::Dict{Int, Pedestrian}) = collect(values(d))
@recipe function f(ps::Vector{<:Pedestrian}; add_view = false, add_personal = true)
    k = length(ps)
    pos = getproperty.(ps, :pos)
    cls0 = get_color.(getproperty.(ps, :id))

    # physical size
    shps = circle.(pos, getproperty.(ps, :radius_min))
    cls = cls0
    ops = ones(k)
    lnstyle = fill(:solid, k)
    lnalpha = ones(k)

    # personal space
    if add_personal
        append!(shps, circle.(pos, getproperty.(ps, :radius)))
        append!(cls, cls0)
        append!(ops, zeros(k))
        append!(lnstyle, fill(:dash, k))
        append!(lnalpha, ones(k))
    end

    # current view
    if add_view
        vel = getproperty.(ps, :vel)
        rv = norm.(vel, 2)
        θ0 = direction_angle.(vel)
        θmax = getproperty.(ps, :φ)

        append!(shps, circle_section.(pos, rv, θ0, θmax))
        append!(cls, cls0)
        append!(ops, 0.2*ones(k))
        append!(lnstyle, fill(:solid, k))
        append!(lnalpha, zeros(k))

    end

    # set plot style
    seriestype  := :shape
    label --> ""
    fillcolor --> permutedims(cls)
    linecolor --> permutedims(cls)
    linestyle --> permutedims(lnstyle)
    linealpha --> permutedims(lnalpha)
    fillalpha --> permutedims(ops)

    # remove kwargs
    delete!(plotattributes, :add_view)
    delete!(plotattributes, :add_personal)

    return shps
end

# room plot
function makeplot(
    room::Room;
    add_checkpoints = false,
    add_valid = false,
    k_valid = 300,
    radius = 0.1,
    kwargs...
)
    # basic setup
    plt = plot(; kwargs...)

    # plot walls
    plot!(plt, room.shape)

    # add doors
    for d in vcat(room.entrances, room.exits)
        plot!(plt, d; add_checkpoints, radius)
    end

    # add checkpoints
    if add_checkpoints && !isempty(room.checkpoints)
        plot!(plt, room.checkpoints)
    end

    # add obstacles
    for o in room.obstacles
        plot!(plt, o)
    end

    # add valid positions
    if add_valid
        lims = roomlims(room.shape)
        xs = range(0, lims[1]; length = k_valid)
        ys = range(0, lims[2]; length = k_valid)
        heatmap!(plt, xs, ys, (x, y) -> isvalid(room, (x, y), radius);
            color = [get_main_color(), :white],
            opacity = 0.2,
            cbar = false,
        )
    end
    return plt
end

# model plot
function makeplot(
    model::AgentBasedModel;
    add_view = false,
    add_personal = true,
    kwargs...
)   

    plt = makeplot(model.room; kwargs...)
    if !isempty(model.agents)
        plot!(plt, model.agents; add_view, add_personal)
    end
    return plt
end