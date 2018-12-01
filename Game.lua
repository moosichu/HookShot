local Game = {}

local Vector = require("libraries.brinevector")

local Player = require("Player")

local world = require("world")

function Game:New()
    self.input_names = {'space'}

    self.players = {}
    self.inputs = {}
    for index, input in pairs(self.input_names) do
        self.players[index] = Player:New(Vector(world.width / 2, world.height / 2))

        self.inputs[index] = {}
        self.inputs[index].action_down = false
        self.inputs[index].action = false
        self.inputs[index].action_up = false
    end

    self.world = world
    Game.Instance = self
    return self
end

function Game:Update(dt)
    for index, player in pairs(self.players) do
        local input = self.inputs[index]
        local input_action = love.keyboard.isDown(self.input_names[index])
        input.action_down = false
        input.action_up = false

        if input_action and (not input.action) then
            input.action_down = true
        elseif (not input_action) and input.action then
            input.action_up = true
        end
        input.action = input_action

        player:Update(dt, input)

        self.inputs[index] = input
    end
end

function Game:Draw()
    for _, player in pairs(self.players) do
        player:Draw()
    end

    world.DrawGround()
end


return Game
