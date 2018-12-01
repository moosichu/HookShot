local Game = require("Game")

local game_instance = nil


local bDevMode = true
local bAssertHit = false
local sAssertReason = "no assertion reason given"
local sAssertFunctionName = "error grabbing function"
local sAssertLineNumber = "error grabbing line number"

function Assert(bShouldNotAssert, sReason)
    if bDevMode and (not bShouldNotAssert) and (not bAssertHit) then
        local debuginfo = debug.getinfo(2, "Sln")
        bAssertHit = true
        sAssertReason = sReason
        sAssertFunctionName = debuginfo.short_src ..":" .. debuginfo.name
        sAssertLineNumber = debuginfo.currentline
    end
end

function love.load()
    game_instance = Game:New()
end

function love.draw()
    if bAssertHit then
        love.graphics.print(sAssertFunctionName .. ":" ..tostring(sAssertLineNumber) .. " " .. sAssertReason, 400, 300)
    else
        game_instance:Draw()
    end
end

function love.update(dt)
    game_instance:Update(dt)
end
