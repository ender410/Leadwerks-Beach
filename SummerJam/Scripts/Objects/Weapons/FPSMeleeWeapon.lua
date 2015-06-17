import "Scripts/AnimationManager.lua"

Script.index=1--int "Weapon slot"
--Script.autogive=false--bool "Autogive"
Script.offset=Vec3(0,0,0)--Vec3 "Offset"
Script.rotation=Vec3(0,0,0)--Vec3 "Rotation"
Script.maxswayamplitude=0.01
Script.amplitude=0
Script.swayspeed=0
Script.timeunits=0
Script.smoothedposition=Vec3(0)
Script.smoothedrotation=Vec3(0)
Script.verticalbob=0
Script.jumpoffset=0
Script.strikedelay=500--int "Strike delay"
Script.landoffset=0
Script.firetime=0
Script.refirerate=100--int "Refire rate"
Script.bulletrange=1000
Script.bulletforce=500--float "Force"
Script.bulletdamage=10--int "Damage"
Script.automatic=false--bool "Automatic"
Script.fire1soundfile=""--path "Fire sound 1" "Wav File (*wav):wav|Sound"
Script.fire2soundfile=""--path "Fire sound 2" "Wav File (*wav):wav|Sound"
Script.fire3soundfile=""--path "Fire sound 3" "Wav File (*wav):wav|Sound"
Script.ricochet1soundfile=Sound:Load("Sound/Ricochet/bullet_impact_dirt_01.wav")
Script.ricochet2soundfile=Sound:Load("Sound/Ricochet/bullet_impact_dirt_02.wav")
Script.ricochet3soundfile=Sound:Load("Sound/Ricochet/bullet_impact_dirt_03.wav")
Script.firespeed=0.05--float "Fire speed"
Script.currentaction=nil

function Script:Start()
	if self.started then return end
	self.started=true
	
	self.entity:SetPickMode(0,true)

	self.entity:SetPosition(self.offset)
	self.entity:SetAnimationFrame(0,1,"fire")
	
	self.entity:Hide()
	
	self.entity:SetShadowMode(0)
	self.entity:SetOcclusionCullingMode(false)
	
	self.currentaction=nil
	self.muzzle = self.entity:FindChild("blade")
	
	self.sound={}
	self.sound.fire={}
	if self.fire1soundfile~="" then self.sound.fire[1]=Sound:Load(self.fire1soundfile) end
	if self.fire2soundfile~="" then self.sound.fire[2]=Sound:Load(self.fire2soundfile) end
	if self.fire3soundfile~="" then self.sound.fire[3]=Sound:Load(self.fire3soundfile) end
	self.sound.ricochet={}
	self.sound.ricochet[1]=Sound:Load("Sound/Ricochet/bullet_impact_dirt_01.wav")
	self.sound.ricochet[2]=Sound:Load("Sound/Ricochet/bullet_impact_dirt_02.wav")
	self.sound.ricochet[3]=Sound:Load("Sound/Ricochet/bullet_impact_dirt_03.wav")
	
	self.entity:SetPickMode(0)
	
	self.animationmanager = AnimationManager:Create(self.entity)
	self.originalposition = self.entity:GetPosition()
	self.originalrotation = self.entity:GetRotation()
	
	self.emitter={}

	--Debris emitter - This will throw chunks off of walls and make it look like they are breaking
	self.emitter[0]=Emitter:Create()
	self.emitter[0]:SetMaterial("Materials/Effects/default.mat")
	self.emitter[0]:SetEmissionVolume(0.05,0.05,0.05)	
	self.emitter[0]:SetColor(0.1,0.1,0.1,1)
	self.emitter[0]:SetVelocity(1.5,1.5,1.5,1)
	self.emitter[0]:SetParticleCount(10)
	self.emitter[0]:SetReleaseQuantity(10)
	self.emitter[0]:SetMaxScale(0.3)
	self.emitter[0]:SetDuration(1000)
	self.emitter[0]:SetAcceleration(0,-12,0)
	self.emitter[0]:Hide()
	
	--Blood emitter - This will provide a visual cue when an enemy is shot
	self.emitter[2]=Emitter:Create()
	self.emitter[2]:SetColor(1,1,1,0.25)
	self.emitter[2]:SetEmissionVolume(0.1,0.1,0.1)
	self.emitter[2]:SetVelocity(0.3,0.3,0.3,1)
	self.emitter[2]:SetParticleCount(3)
	self.emitter[2]:SetReleaseQuantity(3)
	self.emitter[2]:SetMaxScale(4)
	self.emitter[2]:SetDuration(2500)
	self.emitter[2]:AddScaleControlPoint(0,0.5)
	self.emitter[2]:AddScaleControlPoint(1,1)
	self.emitter[2]:SetRotationSpeed(10)
	self.emitter[2]:SetMaterial("Materials/Effects/bloodspatter.mat")
	self.emitter[2]:SetColor(1,1,1,0.25)
	self.emitter[2]:SetParticleCount(3)
	self.emitter[2]:SetReleaseQuantity(3)
	self.emitter[2]:SetDuration(200)
	self.emitter[2]:SetEmissionVolume(0,0,0)
	self.emitter[2]:SetMaxScale(1)
	self.emitter[2]:SetRotationSpeed(10)
	self.emitter[2]:AddScaleControlPoint(0,0)
	self.emitter[2]:AddScaleControlPoint(1,1)
	self.emitter[2]:SetVelocity(0,0,0,0)
	self.emitter[2]:SetVelocity(0,0,0,1)
	self.emitter[2]:Hide()
	
	--[[if self.autogive then
		local player,n
		for n,player in ipairs(players) do
			player:AddWeapon(self,self.index)
		end
	end]]--

	self.entity:Hide()
end

function Script:Hide()
	self.entity:Hide()
end

function Script:FindScriptedParent(entity,func)
	while entity~=nil do
		if entity.script then
			if type(entity.script[func])=="function" then
				if entity.script.enabled~=false then
					return entity
				else
					return nil
				end
			end
		end
		entity = entity:GetParent()
	end
	return nil
end

function Script:BeginJump()
	self.jumpoffset = -180
end

function Script:BeginLand()
	self.landoffset = -180
end

function Script:EndFire()
	self.currentaction=nil
end

function Script:Strike()
	local pickinfo=PickInfo()
	local pos = self.player.camera:GetPosition(true)
	local dir = Transform:Normal(0,0,0.5,self.player.camera,nil)
	
	if self.entity.world:Pick(pos,pos+dir,pickinfo,0,true,Collision.Projectile) then						

		--Find first parent with the Hurt() function
		local enemy = self:FindScriptedParent(pickinfo.entity,"Hurt")
		if enemy~=nil then
			if enemy.script.health>0 then
				enemy.script:Hurt(self.bulletdamage,self.player)
			end
			
			--Blood emitter
			e = self.emitter[2]:Instance()
			e = tolua.cast(e,"Emitter")
			e:Show()
			e:SetLoopMode(false,true)
			e:SetPosition(pickinfo.position+pickinfo.normal*0.1)
			e:SetVelocity(0,0,0)
			
		else
			
			--Add a temporary particle emitter for bullet effects
			local e
			
			e = self.emitter[0]:Instance()
			e = tolua.cast(e,"Emitter")
			e:Show()
			e:SetLoopMode(false,true)
			e:SetPosition(pickinfo.position)
			local v=3
			e:SetVelocity(pickinfo.normal.x*v,pickinfo.normal.y*v,pickinfo.normal.z*v,0)
			
			--Play bullet impact noise
			e:EmitSound(self.sound.ricochet[math.random(#self.sound.ricochet)],30)
			
			if pickinfo.entity~=nil then
				
				--Add impulse to the hit object
				if pickinfo.entity:GetMass()>0 then
					--local force = pickinfo.normal*-1*self.bulletforce
					local dir = Transform:Normal(0,0,1,self.player.camera,nil)
					local force = dir * self.bulletforce * math.max(0,-pickinfo.normal:Dot(dir))
					--force = force * math.max(0,-pickinfo.normal:Dot(d))--multiply by dot product of velocity and collided normal, to weaken glancing blows
					pickinfo.entity:AddPointForce(force,pickinfo.position)
				end
			end
		end
	end	
end

function Script:Fire()
	if self.player.weaponlowerangle==0 then
		local currenttime=Time:GetCurrent()
		if self.lastfiretime==nil then self.lastfiretime=0 end
		if currenttime-self.lastfiretime>self.refirerate then
			if self.currentaction==nil then			
				self.lastfiretime = currenttime
				self.currentaction="strike"
				if #self.sound.fire>0 then
					self.sound.fire[math.random(#self.sound.fire)]:Play()					
				end
				self.firetime = Time:GetCurrent()
				self.animationmanager:SetAnimationSequence("Fire",self.firespeed,300,1,self,self.EndFire)
			end
		end
	end
end

function Script:UpdateWorld()
	if self.currentaction=="strike" then		
		local t=Time:GetCurrent()
		if t-self.firetime>self.strikedelay then
			self:Strike()
			self.currentaction="fire"
		end
	end
end

function Script:Draw()
	
	local t = Time:GetCurrent()
	
	local jumpbob = 0
	
	if self.jumpoffset<0 then
		jumpbob = (Math:Sin(self.jumpoffset))*0.01
		self.jumpoffset = self.jumpoffset + 8*Time:GetSpeed()
	end
	
	if self.landoffset<0 then
		jumpbob = jumpbob + (Math:Sin(self.landoffset))*0.01
		self.landoffset = self.landoffset + 10*Time:GetSpeed()
	end
	
	--Animate the weapon
	local bob = 0;
	local speed = math.max(0.1,self.player.entity:GetVelocity():xz():Length())
	if self.player.entity:GetAirborne() then speed = 0.1 end
	self.swayspeed = Math:Curve(speed,self.swayspeed,20)
	self.swayspeed = math.max(0.5,self.swayspeed)
	self.amplitude = math.max(2,Math:Curve(speed,self.amplitude,20))
	self.timeunits = self.timeunits + self.swayspeed*4*Time:GetSpeed()
	local sway = math.sin(self.timeunits/120.0) * self.amplitude * self.maxswayamplitude
	bob = (1-math.cos(self.timeunits/60.0)) * self.maxswayamplitude * 0.1 * self.amplitude
	local campos = self.player.camera:GetPosition(true)
	
	self.smoothedposition.x = campos.x
	self.smoothedposition.y = Math:Curve(campos.y,self.smoothedposition.y,2)
	self.smoothedposition.z = campos.z
	self.entity:SetRotation(self.rotation)	
	self.entity:SetPosition(sway*self.entity.scale.x,bob+jumpbob,0)
	self.entity:Translate(self.offset,false)
	
	self.animationmanager:Update()
end

function Script:Release()
	if self.emitter~=nil then
		self.emitter[0]:Release()
		self.emitter[2]:Release()
		self.emitter=nil
	end
	ReleaseTableObjects(self.sound)
end
