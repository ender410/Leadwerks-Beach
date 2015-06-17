Script.vwepfile=""--path "VWep" "Prefab (*pfb):pfb|Prefabs"
--Script.vwep=nil--entity

function Script:Start()
	if self.vwepfile~="" then
		local prefab = Prefab:Load(self.vwepfile)
		if prefab~=nil then
			if prefab.script~=nil then	
				self.vwep = prefab.script
			else
				prefab:Release()
			end
		end
	end
end

function Script:Use(player)
	if self.vwep then
		if type(player.AddWeapon)=="function" then
			if player.weapons~=nil then
				if player.weapons[self.index]==nil then
					player:AddWeapon(self.vwep)
					self.entity:Hide()
				end
			end
		end	
	end
end

function Script:Collision(entity, position, normal, speed)
	if self.vwep then
		if entity.script~=nil then self:Use(entity.script) end
	end
end
