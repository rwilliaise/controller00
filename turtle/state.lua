
local WIRELESS_MODEM = { name = "computercraft:peripheral", damage = 1 }
local STATE_LOCATION = "/ctrl.dat"

local CARDINALS = {
    north = vector.new(0, 0, -1),
    west = vector.new(-1, 0, 0),
    south = vector.new(0, 0, 1),
    east = vector.new(1,  0, 0),
}

local DIRECTIONS = {
    north = vector.new(0, 0, -1),
    west = vector.new(-1, 0, 0),
    south = vector.new(0, 0, 1),
    east = vector.new(1,  0, 0),
    up = vector.new(0, 1, 0),
    down = vector.new(0, -1, 0),
}

local LEFT = {
    north = "west",
    west = "south",
    south = "east",
    east = "north",
}

local net = require("net")

local module = {}
module.__index = module

function module.new(config)
    local self = setmetatable({}, module)
    self.state = {}
    self.config = config

    self.machine_thread = nil
    self.machine_state = nil

    self.net = net.new(self)

    self:load()
    self:update_state()

    return self
end

function module:get_empty_slot()
    for i = 1, #self.state.inventory do
        local slot = self.state.inventory[i]
        if not slot.name then
            return i
        end
    end
    return nil
end

function module:save()
    local f = io.open(STATE_LOCATION, "w")
    if f == nil then return end
    local str = textutils.serialize(self.state)
    f:write(str)
    f:flush()
    f:close()
end

function module:load()
    local f = io.open(STATE_LOCATION, "r")
    if f == nil then return end
    local str = f:read("*a")
    self.state = textutils.unserialize(str)
    f:close()
end

function module:update_state()
    -- fuel
    self.state.fuel = turtle.getFuelLevel()
    if self.state.fuel == 0 and not self:refuel(1) then
        error("Insert some fuel before continuing.")
    end

    -- inventory
    self.state.inventory = {}

    for i = 1, 16 do
        self.state.inventory[i] = turtle.getItemDetail(i) or {}
    end

    -- equipped
    local empty_slot = self:get_empty_slot()
    if empty_slot and not self.state.equip then
        self.state.equip = {}
        turtle.select(empty_slot)

        turtle.equipLeft()
        self.state.equip.left = turtle.getItemDetail(empty_slot)
        turtle.equipLeft()

        turtle.equipRight()
        self.state.equip.right = turtle.getItemDetail(empty_slot)
        turtle.equipRight()
    end

    if not self.state.position and self:equip_item(WIRELESS_MODEM) then
        self.state.position = vector.new(gps.locate(5, true))
        self:unequip_item()
    elseif not self.state.position then
        print("Input current coordinates of turtle:")
        local coordinates = io.read("*l")
        -- TODO
    end

    if not self.state.direction and self:equip_item(WIRELESS_MODEM) then
        turtle.forward()
        local new_pos = vector.new(gps.locate(5, true))
        local old_pos = self.state.position

        -- ensure metatable is there
        old_pos = vector.new(
            old_pos.x,
            old_pos.y,
            old_pos.z
        )

        local delta = new_pos:sub(old_pos)
        print("Moved by:", delta)

        for dir, v in pairs(CARDINALS) do
            if v:tostring() == delta:tostring() then -- mom would be sad :(
                self.state.direction = dir
                break
            end
        end

        turtle.back()
        self:unequip_item()
    elseif not self.state.direction then
        print("Input current direction of turtle:")
        while true do
            local direction = io.read("*l")
            if CARDINALS[direction] then
                self.state.direction = direction
            end
        end
    end

    sleep(1 / self.config.think_rate)
end

function module:refuel(count)
    local last_slot = turtle.getSelectedSlot()
    local refuelled = false

    for i = 1, #self.state.inventory do
        turtle.select(i)
        if turtle.refuel(count) then
            refuelled = true
            break
        end
    end

    turtle.select(last_slot)
    return refuelled
end

function module:has_item(item)
    local name = item
    local damage = nil
    if type(name) == "table" then
        name = item.name
        damage = item.damage
    end

    for i = 1, #self.state.inventory do
        local slot = self.state.inventory[i]
        if slot.name == name and slot.damage == (damage or slot.damage) then
            return true, i
        end
    end

    for key, v in pairs(self.state.equip) do
        if v.name == name and v.damage == (damage or v.damage) then
            return true, key
        end
    end

    return false, nil
end

function module:equip_item(item)
    local has_item, slot = self:has_item(item)
    if not has_item then return end
    if type(slot) == "string" then
        return true, slot
    end
    self.last_slot = turtle.getSelectedSlot()
    self.last_equip_slot = slot
    turtle.select(self.last_equip_slot)
    turtle.equipLeft()
    return true, "left"
end

function module:unequip_item(item)
    if self.last_slot and self.last_equip_slot then
        turtle.equipLeft()
        turtle.select(self.last_slot)
        self.last_slot = nil
        self.last_equip_slot = nil
    end
end

function module:select_item(item)
    local has_item, slot = self:has_item(item)

    if not has_item then return false end
    if type(slot) == "string" then
        local hand = slot
        slot = self:get_empty_slot()
        if slot == nil then return false end
        -- unequip into empty slot
        turtle.last_hand = hand
        if hand == "left" then turtle.equipLeft() end
        if hand == "right" then turtle.equipRight() end
    end
    self.last_slot = turtle.getSelectedSlot()
    turtle.select(slot)
    return true
end

function module:unselect_item()
    if not self.last_slot then return end
    if self.last_hand == "left" then turtle.equipLeft() end
    if self.last_hand == "right" then turtle.equipRight() end
    turtle.select(self.last_slot)
    self.last_slot = nil
    self.last_hand = nil
end

function module:stop_machine_state()
    if not self.machine_state then return end

    local stop_state = self["stop_" .. self.machine_state]
    if stop_state then
        stop_state(self)
    end
    self.machine_state = nil
end

function module:change_machine_state(new_state)
    if self.machine_state == new_state then return end

    module:stop_machine_state()

    local start_state = self["start_" .. new_state]
    if start_state then
        start_state(self)
    end

    self.machine_state = new_state
    coroutine.resume(self.machine_thread)
end

function module:idle()
    print("yielding.")
    coroutine.yield() -- stop machine_thread while idle
end

function module:follow_path()
    if not self.current_path then return self:stop_machine_state() end
    if not self.current_path[self.current_path_point] then return self:stop_machine_state() end
    local point = self.current_path[self.current_path_point]
    if self[point] then -- up, down
        self[point](self) -- yuck
        return
    end

    self:face_direction(point)
    self:forward()
    self.current_path_point = self.current_path_point + 1
end

local function toVector(point)
    return vector.new(point.x, point.y, point.z)
end

function module:start_path(server_path)
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

    self.current_path_point = 1
    self.current_path = out_path
    self:change_machine_state("follow_path")
    return true
end

function module:forward()
    if not self.state.direction then return end
    local success = turtle.forward()
    if success then
        local pos = toVector(self.state.position)
        self.state.position = pos:add(CARDINALS[self.state.direction])
    end
end

function module:up()
    local success = turtle.up()
    if success then
        local pos = toVector(self.state.position)
        self.state.position = pos:add(DIRECTIONS.up)
    end
end

function module:down()
    local success = turtle.down()
    if success then
        local pos = toVector(self.state.position)
        self.state.position = pos:add(DIRECTIONS.down)
    end
end

function module:face_direction(cardinal)
    if self.state.direction == cardinal then return end
    if not CARDINALS[cardinal] then return end
    while self.state.direction ~= cardinal do
        module:turn_left()
    end
end

function module:turn_left()
    local success = turtle.turnLeft()
    if success then
        self.state.direction = LEFT[self.state.direction]
        self:save()
    end
end

function module:open()

    self.net:send("update_state", self.state)

    parallel.waitForAny(
        function() self:open_machine() end,
        function() self.net:open() end
    )
    self:save()
end

-- start the state machine
function module:open_machine()
    self.machine_thread = coroutine.running()
    while true do
        local continue_state = self[self.machine_state]
        if not self.machine_state or not continue_state then
            self:change_machine_state("idle")
            continue_state = self[self.machine_state]
        end

        continue_state(self)
        print("sleeping for", 1 / self.config.think_rate)
        sleep(1 / self.config.think_rate)
    end
end

return module
