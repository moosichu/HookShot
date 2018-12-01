local Game = {}

local Vector = require("libraries.brinevector")

local Player = require("Player")

local world = require("world")

Game.STATE_PLAYING = 0
Game.STATE_KILL_OCCURED = 1


function Game:ResetLevel()
    self.player_characters = {}
    self.inputs = {}
    self.state = Game.STATE_PLAYING
    for index, player_initialise in pairs(self.players_initialise) do
        self.player_characters[index] = Player:New(player_initialise.start_pos)

        self.inputs[index] = {}
        self.inputs[index].action_down = false
        self.inputs[index].action = false
        self.inputs[index].action_up = false
    end
end

function Game:New()
    instance = {}
    setmetatable(instance, self)
    self.__index = self

    self.players_initialise = {
        {
            control = 'lshift',
            start_pos = Vector(3, 5)
        },
        {
            control = 'space',
            start_pos = Vector(world.width - 3, 5)
        }
    }


    self.player_scores = {}
    for index, player_initialise in pairs(self.players_initialise) do
        self.player_scores[index] = 0
    end

    self.world = world
    Game.Instance = self
    self:ResetLevel()

    return self
end

function Game:Update(dt)
    do
        local collision_radii = Player.PLAYER_COLLISION_RADIUS + Player.HOOKSHOT_COLLISION_RADIUS
        local collision_radii2 = collision_radii * collision_radii
        for kill_index, player_maybe_killing in pairs(self.player_characters) do
            for death_index, player_maybe_dying in pairs(self.player_characters) do
                if kill_index ~= death_index then
                    local killing_hookshot_position = player_maybe_killing.hookshot_position
                    local dying_player_position = player_maybe_dying.position
                    if (killing_hookshot_position - dying_player_position).length2 < collision_radii2 then
                        self.state = Game.STATE_KILL_OCCURED
                        self.player_scores[kill_index] = self.player_scores[kill_index] + 1
                        print("Player " .. tostring(death_index) .. " died, score = " .. tostring(self.player_scores[kill_index]))
                    end
                end
            end
        end
    end

    for index, player in pairs(self.player_characters) do
        local input = self.inputs[index]
        local input_action = love.keyboard.isDown(self.players_initialise[index].control)
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
    for _, player in pairs(self.player_characters) do
        player:Draw()
    end

    world.DrawGround()
end


return Game
