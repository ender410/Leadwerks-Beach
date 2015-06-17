Script.target = nil--entity "Target"
--Script.platform = "" --entity "Platform"
--Script.hidden = true --bool "Hidden on Start"

function Script:Start()
	--[[
	if self.platform == nil then
		Debug:Error("No platform assigned.")
	end
	if self.hidden then
		local material = Material:Load("Materials/Effects/invisible.mat")
		self.entity:SetMaterial(material)
	end	
	]]--
end

--function Script:Reached()
--	self.component:CallOutputs("Reached")
--end
