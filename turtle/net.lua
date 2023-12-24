
local packet = {}

function packet:introduce(object)
end

function packet:follow_path(object)
    if not object.path then return end
    self:start_path(object.path)
end

local module = {}
module.__index = module

function module.new(state)
    local self = setmetatable({}, module)
    self.socket = nil

    self.state = state
    self.config = state.config

    self:connect()

    return self
end

function module:connect()
    self.socket = http.websocket(self.config.url or "ws://localhost:8080", {
        ['user-agent'] = self.config.agent or "controller00 turtle"
    })

    if not self.socket then
        error("server not open.")
    end

    self:send("introduce", os.computerID())
end

function module:receive()
    local recv = self.socket.receive()
    if not recv then
        error("socket closed")
    end

    local object = textutils.unserializeJSON(recv)
    if not object or not object.id then return end
    if not packet[object.id] then return end

    packet[object.id](self.state, object)
end

function module:send(object, arg)
    if type(object) == "string" then
        return self:send({ id = object, data = arg })
    end
    local send = textutils.serializeJSON(object)
    self.socket.send(send)
end

function module:open()
    while true do
        self:receive() -- TODO: try re-opening socket
    end
end

return module
