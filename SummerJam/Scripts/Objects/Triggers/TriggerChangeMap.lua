--[[
This script will act as a trigger to change the current map.
Place this at the end of your map to make the player progress
to the next level.
]]--

Script.mapname=""--string "Map Name"

function Script:Start()
	self.enabled=true
end

function Script:Collision(entity, position, normal, speed)
	changemapname=self.mapname
end

function Script:Enable()--in
	if self.enabled==false then
		self.enabled=true
		self:CallOutputs("Enable")
	end
end

function Script:Disable()--in
	if self.enabled then
		self.enabled=false
		self:CallOutputs("Disable")
	end
end
