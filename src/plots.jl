using .Plots
using .Plots: Plot

export makeplot, makeplot!

const COLORS = palette([
    RGB(0, 0.4470, 0.7410),
    RGB(0.8500, 0.3250, 0.0980),
    RGB(0.9290, 0.6940, 0.1250),
    RGB(0.4940, 0.1840, 0.5560),
    RGB(0.4660, 0.6740, 0.1880),
    RGB(0.3010, 0.7450, 0.9330),
    RGB(0.6350, 0.0780, 0.1840),
])

getcolor(id) = COLORS[mod1(id, 7)]

makeplot(obj; kwargs...) = makeplot!(plot(), obj; kwargs...)
makeplot!(obj; kwargs...) = makeplot!(current(), obj; kwargs...)

function makeplot!(plt::Plot, r::Room; q = 100, kwargs...)
    w, h = r.width, r.height 
    
    # plot wall
    plot!(
        plt,
        [0, w, w, 0, 0],
        [0, 0, h, h, 0];
        label = "",
        ratio = :equal,
        linecolor = RGB(143/256, 31/256, 120/256),
        linewidth = 2,
        legend = false,
        axis = nothing,
        border = :none,
        size = (q*w, q*h),
        kwargs...
    )

    # add doors
    for (~, d) in r.entrance
        makeplot!(plt, d)
    end
    for (~, d) in r.exit
        makeplot!(plt, d)
    end

    # add obstacles
    for (~, o) in r.obstacle
        makeplot!(plt, o)
    end
    return plt
end

function makeplot!(plt, d::Door)
    pos = [d.pos1, d.pos2]
    plot!(
        plt,
        first.(pos),
        last.(pos);
        label = "",
        linecolor = :white,
        linewidth = 4,
        marker = :square,
        markercolor = RGB(143/256, 31/256, 120/256),
        markersize = 4,
    )
    return plt
end

function makeplot!(plt, o::Rectangle)
    (x, y), w, h = o.pos, o.width, o.height 
    plot!(
        plt,
        Shape(x .+ [0,w,w,0], y .+ [0,0,h,h]);
        label = "",
        color = RGB(143/256, 31/256, 120/256),
    )
    return plt
end

function makeplot!(plt, ps::Vector{<:Pedestrian})
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