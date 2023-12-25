
local module = {}

function module.follow_path(object)
    if not object.data then return end
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
