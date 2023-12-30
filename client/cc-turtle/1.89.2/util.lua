
Util = {}

function Util.to_vector(point)
    return vector.new(
        point.x or 0,
        point.y or 0,
        point.z or 0
    )
end
