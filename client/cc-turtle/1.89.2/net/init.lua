
local packet = require("net.packet")

Net = {}
Net.socket = nil

function Net.connect()
    Net.socket = http.websocket(Config.config.url, {
        ['user-agent'] = Config.config.agent
    })

    if not Net.socket then
        error("server not open.")
    end

    Net.send("introduce", os.computerID())
end

function Net.receive()
    local recv = Net.socket.receive()
    if not recv then
        error("socket closed")
    end

    local object = textutils.unserializeJSON(recv)
    if not object or not object.id then return end
    if not packet[object.id] then return end

    packet[object.id](object)
end

function Net.log(message)
    print("remote:", message)
    Net.send("log", message)
end

function Net.send(object, arg)
    if not Net.socket then return end
    if type(object) == "string" then
        return Net.send({ id = object, data = arg })
    end
    local send = textutils.serializeJSON(object)
    Net.socket.send(send)
end

function Net.open()
    while true do
        print("Reconnecting.")
        local _, error = pcall(function()
            Net.connect()
            State.upload()
            while true do
                Net.receive() -- TODO: try re-opening socket
            end
        end)
        if error then print("Net:", error) end
        sleep(5)
    end
end
