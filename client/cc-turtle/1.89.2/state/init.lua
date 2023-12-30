
STATE_LOCATION = "/ctrl.dat"

State = {}
State.state = {}

require("state.inventory")
require("state.movement")

function State.load()
    local f = io.open(STATE_LOCATION, "r")
    if f == nil then return end
    local str = f:read("*a")
    State.state = textutils.unserialize(str)
    f:close()
end

function State.save()
    local f = io.open(STATE_LOCATION, "w")
    if f == nil then return end
    local str = textutils.serialize(State.state)
    f:write(str)
    f:flush()
    f:close()
end

function State.upload()
    State.update()
    State.save()
    Net.send("update_state", State.state)
end

function State.update()
    local state = State.state

    -- fuel
    state.fuel = turtle.getFuelLevel()

    -- inventorymaking a command line interface node js readline
    state.inventory = {}

    for i = 1, 16 do
        state.inventory[i] = turtle.getItemDetail(i) or {}
    end

    if state.fuel == 0 and not State.refuel() then
        error("Insert some fuel before continuing.")
    end

    -- equipped
    local empty_slot = State.get_empty_slot()
    if empty_slot and not state.equip then
        state.equip = {}
        turtle.select(empty_slot)

        turtle.equipLeft()
        state.equip.left = turtle.getItemDetail(empty_slot)
        turtle.equipLeft()

        turtle.equipRight()
        state.equip.right = turtle.getItemDetail(empty_slot)
        turtle.equipRight()
    end

    if not state.position and State.equip_item(WIRELESS_MODEM) then
        local x, y, z = gps.locate(5)
        if not x then error("Failed to get position.") end
        state.position = vector.new(x, y, z)
        State.unequip_item()
    elseif not state.position then
        error("Requires wireless modem.")
    end

    if not state.direction and State.equip_item(WIRELESS_MODEM) then
        turtle.forward()
        local x, y, z = gps.locate(5)
        if not x then error("Failed to get position.") end
        local new_pos = vector.new(x, y, z)
        local old_pos = state.position

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
                state.direction = dir
                break
            end
        end

        turtle.back()
        State.unequip_item()
    elseif not state.direction then
        error("Requires wireless modem.")
    end

    state.state = Machine.state
end
