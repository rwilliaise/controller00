
local module = {}

function module.follow_path(object)
    if not object.path then return end
    State.start_path(object.path)
end

return module
