local Vector2D = {}

function Vector2D:New(--[[optional]]x,--[[optional]]y)
    self.x = x or 0
    self.y = y or 0

    return self
end

function Vector2D.Add(v1, v2)
    local result = Vector2D:New()
    result.x = v1.x + v2.x
    result.y = v1.y + v2.y
    return result
end

function Vector2D.ElementWiseDivide(v1, v2)
    local result = Vector2D:New()
    result.x = v1.x / v2.x
    result.y = v1.y / v2.y
    return result
end



function Vector2D.ElementWiseProduct(v1, v2)
    local result = Vector2D:New()
    result.x = v1.x * v2.x
    result.y = v1.y * v2.y
    return result
end

return Vector2D
