
local module = {}

function module.stop_follow_path()
    State.current_path = nil
    State.current_path_point = nil
end

function module.follow_path()
    if not State.current_path then return Machine.stop_state() end
    if not State.current_path[State.current_path_point] then return Machine.stop_state() end
    local point = State.current_path[State.current_path_point]
    if State[point] then -- up, down
        repeat until State[point](State) -- yuck
        State.current_path_point = State.current_path_point + 1
        return
    end

    State.face_direction(point)
    repeat until State.forward()
    State.current_path_point = State.current_path_point + 1
end

function module.idle()
    print("Idling.")
    coroutine.yield() -- stop machine_thread while idle
end

return module
