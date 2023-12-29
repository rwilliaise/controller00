
local module = {}

function module.stop_follow_path()
    State.current_path = nil
    State.current_path_point = nil
end

function module.pathing()
    if not State.current_path then
        Net.send("request_path", State.move_to)
        if not Machine.wait() then return end
    end
    if not State.current_path[State.current_path_point] then
        Net.log("Finished path.")
        return Machine.stop_state()
    end
    local point = State.current_path[State.current_path_point]
    State.scan()

    if State[point] then -- up, down
        if State.inspect[point] and State.inspect[point]() then
            State.current_path = nil
            return
        end
        if State[point]() then -- yuck
            State.current_path_point = State.current_path_point + 1
        end
        return
    end

    State.face_direction(point)
    if State.inspect.forward() then
        State.current_path = nil
        return
    end
    if State.forward() then
        State.current_path_point = State.current_path_point + 1
    end
end

function module.stop_idle()
    Machine.stop_waiting()
end

function module.idle()
    Machine.wait()
end

return module
