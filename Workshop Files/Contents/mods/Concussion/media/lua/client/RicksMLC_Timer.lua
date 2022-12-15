-- -- RicksMLC_Timer


-- require "ISBaseObject"

-- RicksMLC_Timer = ISBaseObject:derive("RicksMLC_Timer");

-- function RicksMLC_Timer:new(timeoutInSeconds, owner, id, isExpectValid)
--     local o = {}
--     setmetatable(o, self)
--     self.__index = self

--     o.timer = self

--     o.isTimerOn = false
--     o.elapsedTime = 0

--     o.owner = owner
--     o.timerEndSeconds = timeoutInSeconds
--     o.id = id
--     o.isExpectValid = isExpectValid

--     o.endTimerCallback = nil

--     return o
-- end

-- function RicksMLC_Timer:HandleUpdateTimer()
-- 	self.elapsedTime = self.elapsedTime + GameTime.getInstance():getRealworldSecondsSinceLastUpdate()
--     --DebugLog.log(DebugType.Mod, "RicksMLC_Timer:HandleUpdateTimer()")
-- 	if self.elapsedTime >= self.timerEndSeconds then
--         self.endTimerCallback(self.timedObject, self.id, self.isExpectValid)
--         self:CancelTimer()
--         return
-- 	end
-- end

-- function RicksMLC_Timer:CancelTimer()
--     DebugLog.log(DebugType.Mod, "RicksMLC_Timer:CancelTimer()")
--     self.isTimerOn = false
--     self.endTimerCallback = nil
-- 	Events.OnTick.Remove(RicksMLC_Timer.UpdateTimer)
-- end

-- function RicksMLC_Timer:StartTimer(endTimerCallback)
-- 	if (not self.isTimerOn) then
-- 		self.isTimerOn = true
-- 		self.elapsedTime = 0
--         self.endTimerCallback = endTimerCallback
-- 		Events.OnTick.Add(RicksMLC_Timer.UpdateTimer)
-- 		DebugLog.log(DebugType.Mod, "RicksMLC_Timer:StartTimer() added UpdateTimer")
-- 	end
-- end

-- function RicksMLC_Timer.UpdateTimer()
-- 	if (iTest and iTest.timer) then
-- 		iTest.timer:HandleUpdateTimer()
-- 	else
-- 		--DebugLog.log(DebugType.Mod, "RicksMLC_Timer:UpdateTimer() No instance found")	
-- 	end
-- end
