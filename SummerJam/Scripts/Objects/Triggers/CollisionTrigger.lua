--[[
This script will make any entity act as a collision trigger.  It works best when you set the
entity's collision type to "Trigger".  This will continuously detect collisions without causing
any physical reaction.
]]--

function Script:Start()
	self.enabled=true
end

function Script:Collision(entity, position, normal, speed)
	if self.enabled then
		self.component:CallOutputs("Collision")
	end
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
