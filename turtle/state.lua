
local STATE_LOCATION = "/controller.dat"

local module = {}
module.__index = module

function module.new()
    local self = setmetatable({}, module)
    self.state = {}

    self:load()

    return self
end

function module:getEmptySlot()
    for i = 1, #self.state.inventory do
        local slot = self.state.inventory[i]
        if not slot.name then
            return i
        end
    end
    return nil
end

function module:updateState()
    -- fuel
    self.state.fuel = turtle.getFuelLevel()

    -- inventory
    local is_color = turtle.isColor()
    local slots = is_color and 16 or 9

    self.state.inventory = {}

    for i = 1, slots do
        self.state.inventory[i] = turtle.getItemDetail(i) or {}
    end

    -- equipped
    local empty_slot = self:getEmptySlot()
    if empty_slot then
        self.state.equip = {}

        turtle.equipLeft()
        self.state.equip.left = turtle.getItemDetail(empty_slot)
        turtle.equipLeft()

        turtle.equipRight()
        self.state.equip.right = turtle.getItemDetail(empty_slot)
        turtle.equipRight()
    end
end

function module:load()

end

function module:save()
    local f = io.open(STATE_LOCATION, "w")
    if f == nil then return end
    local str = textutils.serialize(self.state)
    f:write(str)
    f:flush()
    f:close()
end

return module
