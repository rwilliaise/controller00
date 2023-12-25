
function State.get_empty_slot()
    for i = 1, #State.state.inventory do
        local slot = State.state.inventory[i]
        if not slot.name then
            return i
        end
    end
    return nil
end

function State.has_item(item)
    local name = item
    local damage = nil
    if type(name) == "table" then
        name = item.name
        damage = item.damage
    end

    for i = 1, #State.state.inventory do
        local slot = State.state.inventory[i]
        if slot.name == name and slot.damage == (damage or slot.damage) then
            return true, i
        end
    end

    for key, v in pairs(State.state.equip) do
        if v.name == name and v.damage == (damage or v.damage) then
            return true, key
        end
    end

    return false, nil
end

function State.equip_item(item)
    local has_item, slot = State.has_item(item)
    if not has_item then return end
    if type(slot) == "string" then
        return true, slot
    end
    State.last_slot = turtle.getSelectedSlot()
    State.last_equip_slot = slot
    turtle.select(State.last_equip_slot)
    turtle.equipLeft()
    return true, "left"
end

function State.unequip_item()
    if State.last_slot and State.last_equip_slot then
        turtle.equipLeft()
        turtle.select(State.last_slot)
        State.last_slot = nil
        State.last_equip_slot = nil
    end
end

function State.select_item(item)
    local has_item, slot = State.has_item(item)

    if not has_item then return false end
    if type(slot) == "string" then
        local hand = slot
        slot = State.get_empty_slot()
        if slot == nil then return false end
        -- unequip into empty slot
        turtle.last_hand = hand
        if hand == "left" then turtle.equipLeft() end
        if hand == "right" then turtle.equipRight() end
    end
    State.last_slot = turtle.getSelectedSlot()
    turtle.select(slot)
    return true
end

function State.unselect_item()
    if not State.last_slot then return end
    if State.last_hand == "left" then turtle.equipLeft() end
    if State.last_hand == "right" then turtle.equipRight() end
    turtle.select(State.last_slot)
    State.last_slot = nil
    State.last_hand = nil
end

function State.refuel(count)
    local last_slot = turtle.getSelectedSlot()
    local refuelled = false

    for i = 1, #State.state.inventory do
        turtle.select(i)
        if turtle.refuel(count) then
            refuelled = true
            break
        end
    end

    turtle.select(last_slot)
    return refuelled
end
