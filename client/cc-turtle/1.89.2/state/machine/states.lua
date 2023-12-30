
local module = {}

-- path to specific point
function module.pathing()
    if not State.current_path then
        Net.send("request_path", State.move_to)
        if not Machine.wait() then return end
        if not State.current_path then return end
    end
    if not State.current_path[State.current_path_point] then
        Net.log("Finished path.")
        return Machine.stop_state()
    end
    State.continue_path()
end

function module.start_pathing()
    if not State.move_to then return Machine.stop_state() end
end

function module.stop_pathing()
    State.current_path = nil
    State.current_path_point = nil
end

local CORNERS = {
    vector.new(0, 0, 0),
    vector.new(15, 0, 0),
    vector.new(0, 0, 15),
    vector.new(15, 0, 15),
    vector.new(0, 0, 0), -- loop back to start
}

-- scanning the majority of the top of the chunk with block scanner
function module.scanning()
    if not State.current_path then
        local corner = CORNERS[State.current_corner]
        if not corner then
            Net.log("Finished scanning.")
            return Machine.stop_state()
        end
        local chunk_pos = State.to_scan * 16
        local target_pos = chunk_pos + corner
        target_pos.y = -State.current_corner
        Net.send("request_path", target_pos)
        if not Machine.wait() then return end
        if not State.current_path then return end
    end
    if not State.current_path[State.current_path_point] then
        State.current_corner = State.current_corner + 1
        State.current_path = nil
        return
    end
    State.continue_path()
end

function module.start_scanning()
    if not State.to_scan then return Machine.stop_state() end
    State.current_corner = 1
end

function module.stop_scanning()
    State.current_corner = nil
    State.current_path = nil
    State.current_path_point = nil
end

-- do nothing, wait for State.stop_waiting()
function module.idle()
    Machine.wait()
end

return module
