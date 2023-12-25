
local module = {}

function module.stop_follow_path()
    State.current_path = nil
    State.current_path_point = nil
end

function module.follow_path()
    if not State.current_path then return Machine.stop_state() end
    if not State.current_path[State.current_path_point] then return Machine.stop_state() end
    local point = State.current_path[State.current_path_point]
    print("Starting scan")
    State.scan()
    print("Finished scan")

    if State[point] then -- up, down
        if State.inspect[point] and State.inspect[point]() then
            return State.request_path()
        end
        if State[point]() then -- yuck
            State.current_path_point = State.current_path_point + 1
        end
        return
    end

    State.face_direction(point)
    if State.inspect.forward() then return State.request_path() end
    if State.forward() then
        State.current_path_point = State.current_path_point + 1
    end
end

function module.stop_idle()
    Machine.restart = true
end

function module.idle()
    while true do
        local event = os.pullEventRaw()
        if event == "terminate" then
            Machine.alive = false
            break
        end
        if Machine.restart then
            Machine.restart = nil
            break
        end
    end
end

return module
