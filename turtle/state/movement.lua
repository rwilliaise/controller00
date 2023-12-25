
CARDINALS = {
    north = vector.new(0, 0, -1),
    west = vector.new(-1, 0, 0),
    south = vector.new(0, 0, 1),
    east = vector.new(1,  0, 0),
}

DIRECTIONS = {
    north = vector.new(0, 0, -1),
    west = vector.new(-1, 0, 0),
    south = vector.new(0, 0, 1),
    east = vector.new(1,  0, 0),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
}

LEFT = {
    north = "west",
    west = "south",
    south = "east",
    east = "north",
}

local function toVector(point)
    return vector.new(point.x, point.y, point.z)
end

function State.start_path(server_path)
    local out_path = {}
    local last_point = toVector(server_path[1])
    for i = 2, #server_path do
        local point = toVector(server_path[i])
        local delta = point:sub(last_point)
        last_point = point

        local direction
        for dir, v in pairs(DIRECTIONS) do
            if v:tostring() == delta:tostring() then -- :(
                direction = dir
            end
        end

        if direction == nil then
            print("what in the world -- failed path from server.")
            return false
        end
        table.insert(out_path, direction)
    end

    State.current_path_point = 1
    State.current_path = out_path
    Machine.change_state("follow_path")
    return true
end

function State.forward()
    if not State.state.direction then return end
    local success = turtle.forward()
    if success then
        local pos = toVector(State.state.position)
        State.state.position = pos:add(CARDINALS[State.state.direction])
    end
    return success
end

function State.up()
    local success = turtle.up()
    if success then
        local pos = toVector(State.state.position)
        State.state.position = pos:add(DIRECTIONS.up)
    end
    return success
end

function State.down()
    local success = turtle.down()
    if success then
        local pos = toVector(State.state.position)
        State.state.position = pos:add(DIRECTIONS.down)
    end
    return success
end

function State.face_direction(cardinal)
    if State.state.direction == cardinal then return end
    if not CARDINALS[cardinal] then return end
    while State.state.direction ~= cardinal do
        State.turn_left()
    end
end

function State.turn_left()
    local success = turtle.turnLeft()
    if success then
        State.state.direction = LEFT[State.state.direction]
    end
end


