--[[
This script will act as a trigger to change the current map.
Place this at the end of your map to make the player progress
to the next level.
]]--
Script.damage=10--int "Damage"
Script.enabled=true--bool "Enabled"

function Script:Collision(entity, position, normal, speed)
	if self.enabled then
		if entity.script then
			if type(entity.script.TakeDamage)=="function" then
				entity.script:TakeDamage(self.damage)
			end
		end
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
