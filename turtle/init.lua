
require("config")
require("net")
require("state")
require("state.machine")

Config.load_or_create()
State.load()

Net.connect()
State.upload()

parallel.waitForAny(
    function() Machine.open() end,
    function() Net.open() end
)

