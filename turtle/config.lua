
local CONFIG_LOCATION = "/controller.cfg"

local module = {}
module.config = {}

function module.load()
    local f = io.open(CONFIG_LOCATION, "r")
    if f == nil then return end
    local str = f:read("a")
    module.config = textutils.unserialize(str)
    f:close()
end

function module.save()
    local f = io.open(CONFIG_LOCATION, "w")
    if f == nil then return end
    local str = textutils.serialize(module.config)
    f:write(str)
    f:flush()
    f:close()
end

return module
