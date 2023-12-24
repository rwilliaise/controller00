
local state = require("state")
local config = require("config")

config.load()

local S = state.new(config.config)

S:open()
S:save()
config.save()

