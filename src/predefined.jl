function Room1(
    shape = RoomRectangle(6.0, 5.0),
    obstacles = [Rectangle((2.4, 1.9), 1.2, 0.5)],
    entrances = [
        XDoor((1.05, 5.0), 0.6),
        XDoor((2.7, 5.0), 0.6),
        XDoor((4.35, 5.0), 0.6),
    ],
    exits = [XDoor((2.7, 0.0), 0.6)],
    checkpoints = [
        Checkpoint((2.0, 4.0)),
        Checkpoint((3.0, 4.0)),
        Checkpoint((4.0, 4.0)),
        Checkpoint((2.0, 2.4)),
        Checkpoint((2.0, 1.9)),
        Checkpoint((4.0, 2.4)),
        Checkpoint((4.0, 1.9)),
    ],
)

    return Room(shape, obstacles, entrances, exits, checkpoints)
end

function Model1(;
    room = Room1(),
    time::TimeStrategy = Basic(),
    schedule::ScheduleStrategy = RandomScheduler(),
    target::TargetStrategy = Nearest(),
    move::MoveStrategy = JancaMove(),
    pedestrians = Dict{Int, Pedestrian}(),
    Δt::Real = 0.05,
    maxid::Int = 0,
    iter::Int = 0,
    safe_add::Bool = true,
)

    return Model(room, time, schedule, target, move, pedestrians,
            Δt, Ref(maxid), Ref(iter), safe_add)
end
