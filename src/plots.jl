using .Plots
using .Plots: Plot

export makeplot, set_palette!, set_main_color!, default_palette, run_anim!

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

@recipe function f(c::Checkpoint)

    # set plot style
    seriestype  := :scatter
    label --> ""
    marker --> :x
    markersize --> 6
    markercolor --> :gray

    return [c.pos[1]], [c.pos[2]]
end

@recipe function f(c::HCheckpoint)
    pos = [c.pos, c.pos .+ (c.width, 0)]

    # set plot style
    seriestype  := :path
    label := ""
    marker := :vline
    linecolor := :gray
    linewidth := 1
    markercolor := :gray
    markerstrokecolor := :gray
    markersize := 6

    return first.(pos), last.(pos)
end

@recipe f(p::Pedestrian) = [p]
@recipe f(d::Dict{Int, Pedestrian}) = collect(values(d))
@recipe function f(ps::Vector{<:Pedestrian}; add_view = false, add_personal = true)

    props = extract_shapes.(ps; add_view, add_personal)
    shps = reduce(vcat, getindex.(props, 1))
    cls = reduce(vcat, getindex.(props, 2))
    ops = reduce(vcat, getindex.(props, 3))
    lnstyle = reduce(vcat, getindex.(props, 4))
    lnalpha = reduce(vcat, getindex.(props, 5))

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

function extract_shapes(p::Pedestrian; add_view = false, add_personal = true)
    inds = [1]
    shps = [circle(p.pos, p.rlims[1])]
    if add_personal
        push!(shps, circle(p.pos, p.radius))
        push!(inds, 2)
    end
    if add_view
        push!(shps, circle_section(p.pos, norm(p.vel, 2), direction_angle(p.vel), p.φ))
        push!(inds, 3)
    end
    
    cls = fill(get_color(p.id), 3)[inds]
    ops = [1, 0, 0.2][inds]
    lnstyle = [:solid, :dash, :solid][inds]
    lnalpha = [1, 1, 0][inds]
    return shps, cls, ops, lnstyle, lnalpha
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
        for c in room.checkpoints
            plot!(plt, c)
        end
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
    model::Model;
    add_view = false,
    add_personal = true,
    kwargs...
)   

    plt = makeplot(model.room; kwargs...)
    if !isempty(model.pedestrians)
        plot!(plt, model.pedestrians; add_view, add_personal)
    end
    return plt
end

function run_anim!(m::Model, iter, filename::String; at::Int = 5, fps::Int = 20)

    bar = Progress(iter; showspeed = true)
    anim = Animation()
    for i in 1:iter
        step!(m)

        # progress bar
        k = length(keys(m.pedestrians))
        next!(bar; showvalues = [
                (:iter, i),
                (:pedestrians, k)
        ])
        if mod(iter, at) == 0
            title = @sprintf "Pedestrians: %4.1f s" m.Δt * m.iter[]
            makeplot(m; title)
            frame(anim)
        end
        if m.stop[]
            finish!(bar)
            break
        end
    end
    return gif(anim, filename; fps)
end
