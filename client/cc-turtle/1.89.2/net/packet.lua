
local module = {}

function module.start_pathing(object)
    if not object.data then return end
    State.move_to = Util.to_vector(object.data)
    Machine.change_state("pathing")
end

function module.start_scanning(object)
    if not object.data then return end
    if not State.has_item(BLOCK_SCANNER) then
        Net.log("No block scanner.")
        return
    end
    State.to_scan = Util.to_vector(object.data)
    Machine.change_state("scanning")
end

function module.start_idling(object)
    Machine.stop_state()
    Net.log("Idling.")
end

function module.path_calculated(object)
    if not object.data then return end
    if Machine.state ~= "pathing" and Machine.state ~= "scanning" then return end
    if object.error then
        print("Failed to find path: ", object.error)
        return Machine.stop_state()
    end
    State.start_path(object.data)
end

function module.rethink()
    if Machine.state ~= "idle" then
        Net.log("Failed to rethink, try again when idle")
        return
    end
    State.state = {}
    State.upload()
    Net.log("rethink finished")
end

return module
