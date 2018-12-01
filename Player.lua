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
local HOOK_INITIAL_VELOCITY = 20

local CHARGE_SLOWDOWN = 0.2

local RETRACT_ACCELERATION = 20

local PLAYER_GRAVITY = 9.81

Player.PLAYER_COLLISION_RADIUS = 7.5 / world.pixelsize
Player.HOOKSHOT_COLLISION_RADIUS = 5 / world.pixelsize

function Player:New(--[[required]]position)
    instance = {}
    setmetatable(instance, self)
    self.__index = self

    Assert(position, "Player Must Have a position")
    instance.position = position.copy
    instance.velocity = Vector(0, 0)
    instance.state = Player.STATE_MOVING_PREP
    instance.hookshot_angle = 0
    instance.in_air = false
    instance.hookshot_velocity = Vector(0, 0)
    instance.hookshot_position = Vector(0, 0)
    return instance
end

function Player:_ApplyGravity(dt)
    if self.in_air then
        self.velocity.y = self.velocity.y - (PLAYER_GRAVITY * dt)
    end
end

function Player:_ApplyVelocity(dt)
    self.position = self.position + (self.velocity * dt)
end


function Player:_ApplyHookGravity(dt)
    self.hookshot_velocity.y = self.hookshot_velocity.y - (PLAYER_GRAVITY * dt)
end

function Player:_ApplyHookVelocity(dt)
    self.hookshot_position = self.hookshot_position + (self.hookshot_velocity * dt)
end

function Player:_AboveGround()
    return self.position.y > world.floor_height + Player.PLAYER_COLLISION_RADIUS
end


function Player:_ApplyGroundFriction(dt)
    self.velocity.x = self.velocity.x * 0.2 * dt
end

function Player:_HandleHookShotOutOfBounds()
    local bBelowGround = self.hookshot_position.y < world.floor_height + Player.HOOKSHOT_COLLISION_RADIUS

    if bBelowGround then
        self.hookshot_velocity = Vector(0, 0)
        self.hookshot_position.y = world.floor_height + Player.HOOKSHOT_COLLISION_RADIUS
    end

    if self.hookshot_position.x > world.width then
        self.hookshot_velocity = Vector(0, 0)
        self.hookshot_position.x = world.width - Player.HOOKSHOT_COLLISION_RADIUS
    elseif self.hookshot_position.x < 0 then
        self.hookshot_velocity = Vector(0, 0)
        self.hookshot_position.x = Player.HOOKSHOT_COLLISION_RADIUS
    end

    return bBelowGround
end

function Player:_Collisions(dt)
    if not self.in_air then
        self.position.y = world.floor_height + Player.PLAYER_COLLISION_RADIUS
        if self.velocity.y < 0 then
            self.velocity.y = 0
        end
        self:_ApplyGroundFriction(dt)
    end

    if self.position.x + Player.PLAYER_COLLISION_RADIUS > world.width then
        self.position.x = world.width - Player.PLAYER_COLLISION_RADIUS
        self.velocity.x = 0
    end

    if self.position.x - Player.PLAYER_COLLISION_RADIUS < 0 then
        self.position.x = Player.PLAYER_COLLISION_RADIUS
        self.velocity.x = 0
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

    self:_Collisions(dt)

    if self.state == Player.STATE_MOVING_PREP then
        if input.action_down then
            -- CHARGE WEAPON
            self.state = Player.STATE_CHARGE
        else
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)
            self.hookshot_angle = (self.hookshot_angle + (HOOK_ROTATION_SPEED * dt)) % (math.pi * 2)
            self.hookshot_position = (HOOK_PLAYER_DISTANCE * self:_InitialHookshotDirection()) + self.position
        end
    elseif self.state == Player.STATE_CHARGE then
        if input.action_up then
            self.state = Player.STATE_FIRING
            self.hookshot_velocity = self:_InitialHookshotDirection() * HOOK_INITIAL_VELOCITY
            self.hookshot_velocity = self.hookshot_velocity + self.velocity
        else
            -- TODO: ACTUALLY CHARGE WEAPONS!
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)
            self.hookshot_angle = (self.hookshot_angle + (HOOK_ROTATION_SPEED * dt * CHARGE_SLOWDOWN)) % (math.pi * 2)
            self.hookshot_position = (HOOK_PLAYER_DISTANCE * self:_InitialHookshotDirection()) + self.position
        end
    elseif self.state == Player.STATE_FIRING then

        if input.action_down then
            self.hookshot_velocity = Vector(0, 0)
            self.state = Player.STATE_RETRACT_ATTACH
            self:_HandleHookShotOutOfBounds()
        elseif self:_HandleHookShotOutOfBounds() then
            self.state = Player.STATE_RETRACT_DETACH
        else
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)

            self:_ApplyHookVelocity(dt)
            self:_ApplyHookGravity(dt)
        end
    elseif self.state == Player.STATE_RETRACT_ATTACH then
        local displacement = self.hookshot_position - self.position
        if displacement.length2 < HOOK_PLAYER_DISTANCE then
            self.state = Player.STATE_MOVING_PREP
        elseif input.action_up then
            self.state = Player.STATE_RETRACT_DETACH
        else
            local normal = displacement.normalized
            self.velocity = self.velocity + ((RETRACT_ACCELERATION * dt) * normal)
            self:_ApplyVelocity(dt)
        end
    elseif self.state == Player.STATE_RETRACT_DETACH then
        local displacement = self.position - self.hookshot_position
        if displacement.length2 < HOOK_PLAYER_DISTANCE then
            self.state = Player.STATE_MOVING_PREP
        elseif input.action_down then
            self.state = Player.STATE_RETRACT_ATTACH
        else
            local normal = displacement.normalized
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)
            self:_ApplyHookVelocity(dt)
            self.hookshot_velocity = normal * 10
        end
    else
        Assert(false, "Unhandled Player State")
    end
end

function Player:Draw()
    -- Draw Player
    do
        local screen_pos = world.ToScreen(self.position)
        love.graphics.circle('fill', screen_pos.x, screen_pos.y, Player.PLAYER_COLLISION_RADIUS * world.pixelsize)
    end

    -- Draw Player Hook
    do
        local draw_hook_position = self.hookshot_position
        local screen_pos = world.ToScreen(draw_hook_position)
        local hook_radius = Player.HOOKSHOT_COLLISION_RADIUS * world.pixelsize
        love.graphics.circle('fill', screen_pos.x, screen_pos.y, hook_radius)
    end
end

return Player




