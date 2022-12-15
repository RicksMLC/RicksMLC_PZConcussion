-- RandomiseWASDControl

require "ISBaseObject"

RicksMLC_WASDController = nil

RicksMLC_WASDCtrl = ISBaseObject:derive("RicksMLC_WASDCtrl");

function RicksMLC_WASDCtrl:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    self.isRandomised = false
    self.isLeftRightSwapped = false

    self.origForward = getCore():getKey("Forward")
    self.origBackward = getCore():getKey("Backward")
    self.origLeft = getCore():getKey("Left")
    self.origRight = getCore():getKey("Right")

    return o
end

function RicksMLC_WASDCtrl:SwapLeftRight()
    getCore():addKeyBinding("Right", self.origLeft)
    getCore():addKeyBinding("Left", self.origRight)
    self.isLeftRightSwapped = true
end


function RicksMLC_WASDCtrl:RandomiseWASD()
    local keyBinds = {"Forward", "Backward", "Left", "Right"}
    local newBinds = {}
    newBinds[1] = {2,3,4,1}
    newBinds[2] = {3,4,1,2}
    newBinds[3] = {4,1,2,3}
    newBinds[4] = {2,4,1,3}
    local n = ZombRand(1, 4)
    getCore():addKeyBinding(keyBinds[newBinds[n][1]], self.origForward)
    getCore():addKeyBinding(keyBinds[newBinds[n][2]], self.origBackward)
    getCore():addKeyBinding(keyBinds[newBinds[n][3]], self.origLeft)
    getCore():addKeyBinding(keyBinds[newBinds[n][4]], self.origRight)
    self.isRandomised = true
end

function RicksMLC_WASDCtrl:RestoreWASD()
    if self.isRandomised or self.isLeftRightSwapped then
        getCore():addKeyBinding("Left", self.origLeft)
        getCore():addKeyBinding("Right", self.origRight)
    end
    if self.isRandomised then 
        getCore():addKeyBinding("Forward", self.origForward)
        getCore():addKeyBinding("Backward", self.origBackward)
    end
    self.isRandomised = false
    self.isLeftRightSwapped = false
end


function RicksMLC_WASDCtrl.OnGameStart()
    if not RicksMLC_WASDController then
        RicksMLC_WASDController = RicksMLC_WASDCtrl:new()
    end
end

Events.OnGameStart.Add(RicksMLC_WASDCtrl.OnGameStart)