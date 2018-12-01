local Vector = require("libraries.brinevector")
local world = require("world")

local Player = {}

Player.STATE_MOVING_PREP = 0
Player.STATE_CHARGE = 1
Player.STATE_FIRING = 2
Player.STATE_RETRACT_ATTACH = 3
Player.STATE_RETRACT_DETACH = 4

local HOOK_ROTATION_SPEED = 9
local HOOK_PLAYER_DISTANCE = 0.5

local PLAYER_GRAVITY = 9.81

function Player:New(--[[required]]position)
    Assert(position, "Player Must Have a position")
    self.position = position.copy
    self.velocity = Vector(0, 0)
    self.state = Player.STATE_MOVING_PREP
    self.hookshot_angle = 0
    self.in_air = false
    return self
end

function Player:_ApplyGravity(dt)
    if self.in_air then
        self.velocity.y = self.velocity.y - (PLAYER_GRAVITY * dt)
    end
end

function Player:_ApplyVelocity(dt)
    self.position = self.position + (self.velocity * dt)
end

function Player:_AboveGround()
    return self.position.y > world.floor_height
end

function Player:_CollideGround()
    if not self.in_air then
        self.position.y = world.floor_height
        if self.velocity.y < 0 then
            self.velocity.y = 0
        end
    end
end

function Player:_InitialHookshotDirection()
    return Vector(
        math.cos(self.hookshot_angle),
        math.sin(self.hookshot_angle)
    )
end

function Player:Update(dt, input)
    self.in_air = self:_AboveGround()

    self:_CollideGround()

    if self.state == Player.STATE_MOVING_PREP then
        if input.action_down then
            -- FIRE WEAPON
            self.state = Player.STATE_CHARGE
        else
            self.hookshot_angle = (self.hookshot_angle + (HOOK_ROTATION_SPEED * dt)) % (math.pi * 2)
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)
        end
    elseif self.state == Player.STATE_CHARGE then
        if input.action_up then
            --


            self.state = Player.STATE_FIRING
        else

        end
    elseif self.state == Player.STATE_FIRING then
        if input.action_down then

            self.state = Player.STATE_RETRACT_ATTACH
        else

        end
    elseif self.state == Player.STATE_RETRACT_ATTACH then
        if input.action_up then

            self.state = Player.STATE_RETRACT_DETACH
        else

        end
    elseif self.state == Player.STATE_RETRACT_DETACH then
        if input.action_down then

            self.state = Player.STATE_CHARGE
        else

        end
    else
        Assert(false, "Unhandled Player State")
    end
end

function Player:Draw()
    -- Draw Player
    do
        local screen_pos = world.ToScreen(self.position)
        love.graphics.rectangle('fill', screen_pos.x, screen_pos.y - 10, 10, 10)
    end

    -- Draw Player Hook
    do
        local draw_hook_position = Vector(0, 0)
        if self.state == Player.STATE_MOVING_PREP then
            draw_hook_position = (HOOK_PLAYER_DISTANCE * self:_InitialHookshotDirection()) + self.position
        end


        local screen_pos = world.ToScreen(draw_hook_position)
        local hook_radius = 2.5
        love.graphics.circle('fill', screen_pos.x, screen_pos.y, hook_radius)

    end
end

return Player




