
require("config")
require("net")
require("state")
require("state.machine")

Config.load_or_create()
State.load()

if State.equip_item(BLOCK_SCANNER) and State.last_slot then
    turtle.select(State.last_slot)
    State.last_slot = nil
    State.last_equip_slot = nil
end

parallel.waitForAny(
    Machine.open,
    Net.open
)

Net.socket.close()

