using .Plots
using .Plots: Plot

export makeplot, makeplot!

const COLORS = palette([
    RGB(0.0000, 0.4470, 0.7410),
    RGB(0.8500, 0.3250, 0.0980),
    RGB(0.9290, 0.6940, 0.1250),
    RGB(0.4940, 0.1840, 0.5560),
    RGB(0.4660, 0.6740, 0.1880),
    RGB(0.3010, 0.7450, 0.9330),
    RGB(0.6350, 0.0780, 0.1840),
])

const MAIN_COLOR = RGB(0.5586, 0.1211, 0.4688)

getcolor(id) = COLORS[mod1(id, 7)]

makeplot(obj; kwargs...) = makeplot!(plot(), obj; kwargs...)
makeplot!(obj; kwargs...) = makeplot!(current(), obj; kwargs...)

function makeplot!(
    plt::Plot,
    model::AgentBasedModel;
    addview = false,
    kwargs...
)
    title = get(kwargs, :title, "Simulation: $(model.timestrategy.iter)")
    xlims = get(kwargs, :xlims, (-0.1, model.room.width + 0.1))
    ylims = get(kwargs, :ylims, (-0.1, model.room.height + 0.1))

    makeplot!(plt, model.room; title, xlims, ylims, kwargs...)
    makeplot!(plt, collect(values(model.agents)); addview)
    return plt
end

function makeplot!(
    plt::Plot,
    room::Room;
    q = 100,
    addcheckpoints = true,
    addvalid = false,
    r = 0.25,
    k = 500,
    kwargs...
)
    
    plot!(
        plt;
        label = "",
        ratio = :equal,
        legend = false,
        axis = nothing,
        border = :none,
        kwargs...
        )

    # plot wall
    makeplot!(plt, room.shape, q)

    # add doors
    for d in vcat(room.entrances, room.exits)
        makeplot!(plt, d, addcheckpoints, r)
    end

    # add obstacles
    for o in room.obstacles
        makeplot!(plt, o)
    end

    # add checkpoints
    if addcheckpoints
        makeplot!(plt, room.checkpoints)
    end

    if addvalid
        xs, ys = computerange(room.shape, k)
        heatmap!(
            xs,
            ys,
            (x, y) -> isvalid(room, (x, y), r);
            color = [MAIN_COLOR, :white],
            opacity = 0.2,
            cbar = false,
        )
    end
    return plt
end

function computerange(s::RoomRectangle, k)
    return (range(0, s.width; length = k), range(0, s.height; length = k))
end

function makeplot!(plt, s::RoomRectangle, q)
    w, h = s.width, s.height

    plot!(
        plt,
        [0, w, w, 0, 0],
        [0, 0, h, h, 0];
        linecolor = MAIN_COLOR,
        linewidth = 2,
        size = (q*w, q*h),
    )
    return plt
end

function makeplot!(plt, d::Door, addcheckpoints, r)
    pos = [d.pos, d.pos .+ (d.width, 0)]
    plot!(
        plt,
        first.(pos),
        last.(pos);
        label = "",
        linecolor = :white,
        linewidth = 4,
        marker = :square,
        markercolor = MAIN_COLOR,
        markerstrokecolor = MAIN_COLOR,
        markersize = 4,
    )
    if addcheckpoints
        pos = [d.pos .+ (r, 0), d.pos .+ (d.width - r, 0)]
        plot!(
            plt,
            first.(pos),
            last.(pos);
            label = "",
            marker = :vline,
            linecolor = :gray,
            markercolor = :gray,
            markersize = 6,
        )
    end
    return plt
end

function makeplot!(plt, o::Rectangle)
    (x, y), w, h = o.pos, o.width, o.height 
    plot!(
        plt,
        Shape(x .+ [0,w,w,0], y .+ [0,0,h,h]);
        label = "",
        fillcolor = MAIN_COLOR,
        linecolor = MAIN_COLOR,
    )
    return plt
end

function makeplot!(plt, ts::Vector{<:Checkpoint})
    pos = getproperty.(ts, :pos)
    scatter!(
        plt,
        first.(pos),
        last.(pos);
        label = "",
        marker = :x,
        markercolor = :gray,
        markersize = 6,
    )
    return plt
end

function makeplot!(plt, ps::Vector{<:Pedestrian}; addview = false)
    if addview
        for p in ps
            norm(p.vel) == 0 && continue
            r = 0.5
            ϕ = direction_angle(p.vel)
            pos = vcat(
                p.pos,
                euclidian.(r, ϕ .+ range(-p.φ/2, p.φ/2; length = 10), Ref(p.pos)),
            )
            plot!(
                plt,
                Shape(first.(pos), last.(pos));
                label = "",
                color = getcolor.(p.id),
                fillalpha = 0.2,
                linealpha = 0,
            )
        end
    end

    pos = getproperty.(ps, :pos)
    cls = getcolor.(getproperty.(ps, :id))
    scatter!(
        plt,
        first.(pos),
        last.(pos);
        label = "",
        markercolor = cls,
        markerstrokecolor = cls,
        markersize = 8,
    )
    return plt
end