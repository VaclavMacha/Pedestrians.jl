struct RandomScheduler <: ScheduleStrategy end

function scheduler(::RandomScheduler, m::Model)
    return shuffle(allids(m))
end

struct ById <: ScheduleStrategy end

function scheduler(::ById, m::Model)
    return sort(allids(m))
end