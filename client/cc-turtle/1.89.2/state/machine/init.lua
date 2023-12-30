
local states = require("state.machine.states")

Machine = {}
Machine.state = nil
Machine.thread = nil

function Machine.stop_state()
    if not Machine.state then return end

    local stop_state = states["stop_" .. Machine.state]
    if stop_state then
        stop_state()
    end
    Machine.state = nil
end

function Machine.change_state(new_state)
    if Machine.state == new_state then return end

    Machine.stop_state()
    Machine.state = new_state

    local start_state = states["start_" .. Machine.state]
    if start_state then
        start_state()
    end

    Machine.stop_waiting()
    coroutine.resume(Machine.thread)
end

function Machine.stop_waiting()
    if not Machine.waiting then return end
    Machine.restart = true
end

-- wait until .stop_waiting()
function Machine.wait()
    while true do
        local event = os.pullEventRaw()
        Machine.waiting = true
        if event == "terminate" then
            Machine.waiting = false
            Machine.alive = false
            return false
        end
        if Machine.restart then
            Machine.waiting = false
            Machine.restart = nil
            return true
        end
    end
end

function Machine.open()
    Machine.thread = coroutine.running()
    Machine.alive = true

    while Machine.alive do
        local continue_state = states[Machine.state]
        if not Machine.state or not continue_state then
            Machine.change_state("idle")
            continue_state = states[Machine.state]
        end

        continue_state()
        State.upload() -- upload updated state

        -- sleep(1 / self.config.think_rate)
    end
    print("Closing.")
end

