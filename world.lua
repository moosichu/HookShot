local Vector = require("libraries.brinevector")


local world = {}

-- TODO: Ensure we can handle non 16by9 aspect ratios

world.width = 32
world.height = 18

world.pixelsize = 30

-- floor height in metres
world.floor_height = 4

function world.DrawGround()
    local floor_position = Vector(0, world.floor_height)
    floor_position = world.ToScreen(floor_position.copy)
    love.graphics.line(0, floor_position.y, love.graphics.getWidth(), floor_position.y)
end

function world.ToScreen(position)
    local canvas_size = Vector(love.graphics.getWidth(), love.graphics.getHeight())
    local world_size = Vector(world.width, world.height)
    local normalised_world_position = position / world_size

    -- screen space y coordinates go down :'(
    normalised_world_position.y = 1 - normalised_world_position.y

    return canvas_size % normalised_world_position
end

return world
