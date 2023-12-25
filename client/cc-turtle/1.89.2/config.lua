
CONFIG_LOCATION = "/ctrl.cfg"

Config = {}
Config.config = {
    url = "ws://localhost:8080",
    agent = "turtle (controller00)",
    think_rate = 2,
}

function Config.load_or_create()
    if not Config.load() then
        Config.save()
    end
end

function Config.load()
    local f = io.open(CONFIG_LOCATION, "r")
    if f == nil then return false end
    local str = f:read("*a")
    Config.config = textutils.unserialize(str)
    f:close()
    return true
end

function Config.save()
    local f = io.open(CONFIG_LOCATION, "w")
    if f == nil then return end
    f:write(textutils.serialize(Config.config))
    f:flush()
    f:close()
end


