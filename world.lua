local Vector = require("libraries.brinevector")


local world = {}

-- TODO: Ensure we can handle non 16by9 aspect ratios

world.width = 32
world.height = 18

world.pixelsize = 30

-- floor height in metres
world.floor_height = 2

world.drawn_before = false

world.pillar_tops = "images/pillar_tops.png"
world.pillars = "images/pillars.png"

function world.DrawGround()
    if not world.drawn_before then
        world.drawn_before = true
        world.pillar_tops = love.graphics.newImage(world.pillar_tops)
        world.pillars = love.graphics.newImage(world.pillars)
    end

    for i = 0, world.width, 1 do
        love.graphics.draw(world.pillar_tops, world.pixelsize * i, love.graphics.getHeight() - (world.pixelsize * (world.floor_height + 0.5)))
    end



    for i = 0, world.width, 1 do
        for j = 1, world.floor_height, 1 do
            love.graphics.draw(world.pillars, world.pixelsize * i, love.graphics.getHeight() - (world.pixelsize * (j - 0.5)))
        end
    end
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
