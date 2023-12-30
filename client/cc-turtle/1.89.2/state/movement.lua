
CARDINALS = {
    north = vector.new(0, 0, -1),
    east = vector.new(1,  0, 0),
    south = vector.new(0, 0, 1),
    west = vector.new(-1, 0, 0),
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

RIGHT = {
    north = "east",
    east = "south",
    south = "west",
    west = "north",
}

local s2d = {
    n = "north",
    s = "south",
    w = "west",
    e = "east",
    u = "up",
    d = "down",
}

function State.continue_path()
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

function State.start_path(server_path)
    local out_path = {}
    for i = 1, #server_path do
        local char = server_path:sub(i, i)
        if s2d[char] then
            table.insert(out_path, s2d[char])
        end
    end

    State.current_path_point = 1
    State.current_path = out_path

    Machine.stop_waiting()
    coroutine.resume(Machine.thread)
end

function State.forward()
    if not State.state.direction then return end

    -- TODO: check self.state.direction with gps.locate
    local success = turtle.forward()
    if success then
        local pos = Util.to_vector(State.state.position)
        State.state.position = pos:add(CARDINALS[State.state.direction])
    end
    return success
end

function State.up()
    local success = turtle.up()
    if success then
        local pos = Util.to_vector(State.state.position)
        State.state.position = pos:add(DIRECTIONS.up)
    end
    return success
end

function State.down()
    local success = turtle.down()
    if success then
        local pos = Util.to_vector(State.state.position)
        State.state.position = pos:add(DIRECTIONS.down)
    end
    return success
end

State.inspect = {}

local function setInspect(name, func)
    State.inspect[name] = function()
        local exists, data = func()
        Net.send("update_world",
            {
                {
                    pos = Util.to_vector(State.state.position):add(DIRECTIONS[name] or CARDINALS[State.state.direction]),
                    data = exists and data or nil
                }
            }
        )
        return exists
    end
end

setInspect("forward", turtle.inspect)
setInspect("up", turtle.inspectUp)
setInspect("down", turtle.inspectDown)

local BATCH_SIZE = 16

function State.scan()
    if State.equip_item(BLOCK_SCANNER) then
        local scanner = peripheral.find("plethora:scanner")
        if scanner == nil then return State.unequip_item() end

        local scan = scanner.scan()
        local world_out = {}
        for _, block in pairs(scan) do
            local pos = Util.to_vector(block)
            local out = {
                pos = Util.to_vector(State.state.position):add(pos),
                data = {
                    name = block.name,
                    metadata = block.metadata,
                }
            }
            table.insert(world_out, out)
        end
        for i = 1, #world_out, BATCH_SIZE do
            local split = {}
            for j = 0, (BATCH_SIZE - 1) do
                if not world_out[i + j] then break end
                table.insert(split, world_out[i + j])
            end
            Net.send("update_world", split)
        end
        State.unequip_item()
    end
end

local function get_direction_index(direction)
    local directions = {"north", "east", "south", "west"}
    for i,v in pairs(directions) do
        if v == direction then
            return i
        end
    end
    return nil
end

function State.face_direction(cardinal)
    if State.state.direction == cardinal then return end
    if not CARDINALS[cardinal] then return end

    local old_index = get_direction_index(State.state.direction)
    local new_index = get_direction_index(cardinal)
    local c_turns = (new_index - old_index + 4) % 4
    local cc_turns = (old_index - new_index + 4) % 4

    local turns = (c_turns < cc_turns) and c_turns or cc_turns
    local turn_function = (c_turns < cc_turns) and State.turn_right or State.turn_left
    for i = 1, turns do
        turn_function()
    end
end

function State.turn_left()
    local success = turtle.turnLeft()
    if success then
        State.state.direction = LEFT[State.state.direction]
        State.inspect.forward()
    end
end

function State.turn_right()
    local success = turtle.turnRight()
    if success then
        State.state.direction = RIGHT[State.state.direction]
        State.inspect.forward()
    end
end

