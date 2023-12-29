
local module = {}

function module.start_pathing(object)
    if not object.data then return end
    State.move_to = Util.to_vector(object.data)
    Machine.change_state("pathing")
end

function module.path_calculated(object)
    if not object.data then return end
    if Machine.state ~= "pathing" then return end
    if object.error then
        print("Failed to find path: ", object.error)
        return Machine.stop_state()
    end
    print("Received path:", object.data)
    State.start_path(object.data)
end

function module.rethink()
    if Machine.state ~= "idle" then
        Net.log("Failed to rethink, try again when idle")
        return
    end
    print("rethinking.")
    State.state = {}
    State.upload()
    Net.log("rethink finished")
end

return module
