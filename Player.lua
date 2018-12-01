local Vector = require("libraries.brinevector")
local world = require("world")

local Player = {}

Player.STATE_MOVING_PREP = 0
Player.STATE_CHARGE = 1
Player.STATE_FIRING = 2
Player.STATE_RETRACT_ATTACH = 3
Player.STATE_RETRACT_DETACH = 4

local HOOK_ROTATION_SPEED = 7
local HOOK_PLAYER_DISTANCE = 0.7
local HOOK_MAX_INITIAL_VELOCITY = 25

local CHARGE_SLOWDOWN = 0.2

local RETRACT_ACCELERATION = 20

local PLAYER_GRAVITY = 12.81
local PLAYER_SLOWDOWN_WHEN_CHARGING = 0.1

local CHARGE_TIME = 0.5
local AIM_TIME = 1.5

local PLAYER_AIR_RESISTANCE = .5

Player.PLAYER_COLLISION_RADIUS = 15 / world.pixelsize
Player.HOOKSHOT_COLLISION_RADIUS = 5 / world.pixelsize

function Player:New(--[[required]]position, --[[require]]sprite, lasershot)
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
    instance.sprite = sprite
    instance.lasershot = lasershot
    instance.charge_timer = 0
    instance.dead = false
    return instance
end

function Player:_ApplyGravity(dt)
    if self.in_air then
        self.velocity.y = self.velocity.y - (PLAYER_GRAVITY * dt)
    end
end

function Player:_ApplyVelocity(dt)
    self.position = self.position + (self.velocity * dt)
    self.velocity = self.velocity - (dt * PLAYER_AIR_RESISTANCE * self.velocity)
end


function Player:_ApplyHookGravity(dt)
    self.hookshot_velocity.y = self.hookshot_velocity.y - (PLAYER_GRAVITY * dt)
end

function Player:_ApplyHookVelocity(dt)
    self.hookshot_position = self.hookshot_position + (self.hookshot_velocity * dt)
    self.hookshot_velocity = self.hookshot_velocity - (dt * PLAYER_AIR_RESISTANCE * self.hookshot_velocity)
end

function Player:_AboveGround()
    return self.position.y > world.floor_height + Player.PLAYER_COLLISION_RADIUS
end


function Player:_ApplyGroundFriction(dt)
    local FRICTION_AMOUNT = 10
    if self.velocity.x > 0 then
        self.velocity.x = self.velocity.x - (FRICTION_AMOUNT * dt)
        if self.velocity.x < 0 then
            self.velocity.x = 0
        end
    elseif self.velocity.x < 0 then
        self.velocity.x = self.velocity.x + (FRICTION_AMOUNT * dt)
        if self.velocity.x > 0 then
            self.velocity.x = 0
        end

    end
end

function Player:_HandleHookShotOutOfBounds()
    local bOutOfBounds = self.hookshot_position.y < world.floor_height + Player.HOOKSHOT_COLLISION_RADIUS

    if bOutOfBounds then
        self.hookshot_position.y = world.floor_height + Player.HOOKSHOT_COLLISION_RADIUS
        self.hookshot_velocity.y = self.hookshot_velocity.y * -0.7
        bOutOfBounds = false
    end

    if self.hookshot_position.x > world.width then
        self.hookshot_velocity = Vector(-0.01, 0)
        self.hookshot_position.x = world.width - Player.HOOKSHOT_COLLISION_RADIUS
        bOutOfBounds = true
    elseif self.hookshot_position.x < 0 then
        self.hookshot_velocity = Vector(0.01, 0)
        self.hookshot_position.x = Player.HOOKSHOT_COLLISION_RADIUS
        bOutOfBounds = true
    end

    return bOutOfBounds
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

function Player:_CalculateBestAngle()
    local normalVector = (self.hookshot_position - self.position).normalized
    self.hookshot_angle = math.atan2(normalVector.y, normalVector.x)
end

function Player:Update(dt, input)
    self.in_air = self:_AboveGround()

    self:_Collisions(dt)

    if self.state == Player.STATE_MOVING_PREP then
        self.charge_timer = 0
        if input.action_down then
            -- CHARGE WEAPON
            self.state = Player.STATE_CHARGE
            love.audio.play(self.lasershot)
            self.velocity = self.velocity * PLAYER_SLOWDOWN_WHEN_CHARGING
        else
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)
            self.hookshot_angle = (self.hookshot_angle + (HOOK_ROTATION_SPEED * dt)) % (math.pi * 2)
            self.hookshot_position = (HOOK_PLAYER_DISTANCE * self:_InitialHookshotDirection()) + self.position
        end
    elseif self.state == Player.STATE_CHARGE then
        self.charge_timer = self.charge_timer + dt
        if input.action_up or (self.charge_timer > AIM_TIME) then
            self.state = Player.STATE_FIRING
            love.audio.stop(self.lasershot)
            if self.charge_timer > CHARGE_TIME then self.charge_timer = CHARGE_TIME end
            local charge_factor = self.charge_timer / CHARGE_TIME
            charge_factor = charge_factor * charge_factor * charge_factor
            self.hookshot_velocity = self:_InitialHookshotDirection() * HOOK_MAX_INITIAL_VELOCITY * (0.5 + (charge_factor / 2))
            self.hookshot_velocity = self.hookshot_velocity + (self.velocity)
            self.velocity = (self.hookshot_velocity * -0.5) + self.velocity
            self.charge_timer = 1
        else
            -- TODO: ACTUALLY CHARGE WEAPONS!
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt * PLAYER_SLOWDOWN_WHEN_CHARGING)
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
            self:_CalculateBestAngle()
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
            self:_CalculateBestAngle()
        elseif input.action_down then
            self.state = Player.STATE_RETRACT_ATTACH
        else
            local normal = displacement.normalized
            self:_ApplyVelocity(dt)
            self:_ApplyGravity(dt)
            self:_ApplyHookVelocity(dt)
            self.hookshot_velocity = normal * 20
        end
    else
        Assert(false, "Unhandled Player State")
    end
end

function Player:Draw()
    -- Draw Player
    do
        local screen_pos = world.ToScreen(self.position)
        local r, g, b, a = love.graphics.getColor()
        if self.dead == true then
            love.graphics.setColor(0.3, 0.2, 0.2)
        end
        love.graphics.draw(
            self.sprite,
            screen_pos.x - 15,
            screen_pos.y - 15
        )
        love.graphics.setColor(r, g, b, a)
    end

    -- Draw Player Hook
    do
        local draw_hook_position = self.hookshot_position
        local screen_pos = world.ToScreen(draw_hook_position)
        local hook_radius = Player.HOOKSHOT_COLLISION_RADIUS * world.pixelsize
        local r, g, b, a = love.graphics.getColor()
        local charge_factor = self.charge_timer / CHARGE_TIME
        charge_factor = charge_factor * charge_factor * charge_factor
        if self.state == Player.STATE_CHARGE then
            love.graphics.setColor(.9, charge_factor * .9, 0.2)
        elseif self.state == Player.STATE_FIRING then
            love.graphics.setColor(.9, .9, 0.2)
        elseif self.state == Player.STATE_RETRACT_ATTACH then
            love.graphics.setColor(.9, 0, .9)
        else
            love.graphics.setColor(.0, .9, .9)
        end
        love.graphics.circle('fill', screen_pos.x, screen_pos.y, hook_radius)
        love.graphics.setColor(r, g, b, a)
    end
end

return Player




