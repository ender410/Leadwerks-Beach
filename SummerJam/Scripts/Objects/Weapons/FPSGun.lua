import "Scripts/AnimationManager.lua"

Script.index=1--int "Weapon slot"
Script.offset=Vec3(0,0,0)--Vec3 "Offset"
Script.rotation=Vec3(0,0,0)--Vec3 "Rotation"
Script.clipsize=6--int "Clip size"
Script.ammo=200--int "Ammunition"
Script.maxswayamplitude=0.01
Script.amplitude=0
Script.swayspeed=0
Script.timeunits=0
Script.smoothedposition=Vec3(0)
Script.smoothedrotation=Vec3(0)
Script.verticalbob=0
Script.jumpoffset=0
Script.bulletspeed=200--float "Bullet speed"
Script.landoffset=0
Script.pellets=1--int "Pellets"
Script.scatter=0.01--float "Scatter"
Script.firetime=0
Script.refirerate=100--int "Refire rate"
Script.bulletrange=1000
Script.muzzleflashscale=0.2--float "Flash size"
Script.bulletforce=500--float "Force"
Script.bulletdamage=10--int "Damage"
Script.automatic=true--bool "Automatic"
Script.dryfiresoundfile=""--path "Dry fire" "Wav File (*wav):wav|Sound"
Script.fire1soundfile=""--path "Fire sound 1" "Wav File (*wav):wav|Sound"
Script.fire2soundfile=""--path "Fire sound 2" "Wav File (*wav):wav|Sound"
Script.fire3soundfile=""--path "Fire sound 3" "Wav File (*wav):wav|Sound"
Script.pumpsoundfile=""--path "Pump sound" "Wav File (*wav):wav|Sound"
Script.ricochet1soundfile=Sound:Load("Sound/Ricochet/bullet_impact_dirt_01.wav")
Script.ricochet2soundfile=Sound:Load("Sound/Ricochet/bullet_impact_dirt_02.wav")
Script.ricochet3soundfile=Sound:Load("Sound/Ricochet/bullet_impact_dirt_03.wav")
Script.reloadsoundfile=""--path "Reload sound" "Wav File (*wav):wav|Sound"
Script.reloadspeed=0.05--float "Reload speed"
Script.firespeed=0.05--float "Fire speed"
Script.tracer = Sprite:Create()
Script.tracer:Hide()
Script.currentaction=nil

function Script:Start()
	if self.started then return end
	self.started=true

	self.entity:SetPickMode(0,true)

	self.entity:SetAnimationFrame(0,1,"fire")

	self.entity:Hide()
	
	self.bullets = {}
	
	self.entity:SetShadowMode(0)
	self.entity:SetOcclusionCullingMode(false)
	
	self.tracer:SetViewMode(6)--Rotate around z axis
	self.tracer:SetSize(0.1,2)
	local mtl = Material:Load("Materials/Effects/tracer.mat")
	if mtl then
		self.tracer:SetMaterial(mtl)
		mtl:Release()
	end

	self.currentaction=nil
	self.clipammo=self.clipsize

	self.ammo = self.ammo - self.clipammo
	self.muzzle = self.entity:FindChild("muzzle")
	
	self.sound={}
	if self.sound.dryfiresoundfile~="" then self.sound.dryfire=Sound:Load(self.dryfiresoundfile) end
	self.sound.fire={}
	if self.pumpsoundfile~="" then self.sound.pump=Sound:Load(self.pumpsoundfile) end
	if self.fire1soundfile~="" then self.sound.fire[1]=Sound:Load(self.fire1soundfile) end
	if self.fire2soundfile~="" then self.sound.fire[2]=Sound:Load(self.fire2soundfile) end
	if self.fire3soundfile~="" then self.sound.fire[3]=Sound:Load(self.fire3soundfile) end
	if self.reloadsoundfile~="" then
		self.sound.reload=Sound:Load(self.reloadsoundfile)
	end
	self.sound.ricochet={}
	self.sound.ricochet[1]=Sound:Load("Sound/Ricochet/bullet_impact_dirt_01.wav")
	self.sound.ricochet[2]=Sound:Load("Sound/Ricochet/bullet_impact_dirt_02.wav")
	self.sound.ricochet[3]=Sound:Load("Sound/Ricochet/bullet_impact_dirt_03.wav")
	
	self.entity:SetPickMode(0)
	
	self.muzzleflash = Sprite:Create()
	self.muzzleflash:SetSize(self.muzzleflashscale,self.muzzleflashscale)
	self.muzzleflash:SetCollisionType(0)
	local material = Material:Load("Materials/Effects/muzzleflash.mat")
	self.muzzleflash:SetMaterial(material)
	self.muzzlelight = PointLight:Create()
	self.muzzlelight:SetColor(1,0.75,0)
	self.muzzlelight:SetRange(4)
	self.muzzleflash:SetShadowMode(0)
	local tag = self.entity:FindChild("muzzle")
	self.muzzlelight:SetParent(tag)
	self.muzzlelight:SetPosition(0,0,0)
	self.muzzlelight:Hide()
	self.muzzleflash:SetParent(self.muzzlelight,false)
	self.animationmanager = AnimationManager:Create(self.entity)
	self.originalposition = self.entity:GetPosition()
	self.originalrotation = self.entity:GetRotation()
	self.emitter={}

	--[[
	--Debris emitter - This will throw chunks off of walls and make it look like they are breaking
	self.emitter[0]=Emitter:Create()
	self.emitter[0]:SetMaterial("Materials/Effects/tracer.mat")
	self.emitter[0]:SetEmissionVolume(0.05,0.05,0.05)	
	self.emitter[0]:SetColor(1,1,1,1)
	self.emitter[0]:SetVelocity(10,10,10,1)
	self.emitter[0]:SetParticleCount(5)
	self.emitter[0]:SetReleaseQuantity(5)
	self.emitter[0]:SetMaxScale(0.25,1)
	self.emitter[0]:SetDuration(150)
	self.emitter[0]:SetRotationByVelocityMode(true)
	self.emitter[0]:Hide()
	]]--
	
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
	
	--Smoke emitter - This will provide a soft dust effect around bullet impacts
	self.emitter[1]=Emitter:Create()
	self.emitter[1]:SetColor(1,1,1,0.25)
	self.emitter[1]:SetMaterial("Materials/Effects/smoke.mat")
	self.emitter[1]:SetEmissionVolume(0.1,0.1,0.1)
	self.emitter[1]:SetVelocity(0.3,0.3,0.3,1)
	self.emitter[1]:SetParticleCount(3)
	self.emitter[1]:SetReleaseQuantity(3)
	self.emitter[1]:SetMaxScale(4)
	self.emitter[1]:SetDuration(2500)
	self.emitter[1]:AddScaleControlPoint(0,0.5)
	self.emitter[1]:AddScaleControlPoint(1,1)
	self.emitter[1]:SetRotationSpeed(10)
	self.emitter[1]:Hide()
	
	--Blood emitter - This will provide a visual cue when an enemy is shot
	self.emitter[2]=self.emitter[1]:Instance()
	self.emitter[2] = tolua.cast(self.emitter[2],"Emitter")
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

function Script:Holster()
	if self.entity:FindAnimationSequence("holster")>-1 then
		self.animationmanager:SetAnimationSequence("holster",self.reloadspeed,0,1)--,self,self.EndHolster,25)		
	end
end

function Script:Unholster()
	if self.entity:FindAnimationSequence("unholster")>-1 then
		self.animationmanager:SetAnimationSequence("unholster",self.reloadspeed,0,1)
		self.currentaction="unholster"
	end
end

function Script:Hide()
	self.entity:Hide()
	self.muzzlelight:Hide()
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

function Script:FinalizeReload()
	self.currentaction=nil
	if self.cancelreload then
		self.cancelreload=false
	end
end

function Script:EndReload()
	if self.entity:FindAnimationSequence("ReloadLoop")>-1 then
		if self.ammo>0 and self.clipammo<self.clipsize and (self.reloadedshells==0 or self.cancelreload==false) then
			if self.sound.reload~=nil then
				self.sound.reload:Play()
			end
			self.animationmanager:SetAnimationSequence("ReloadLoop",self.reloadspeed,300,1,self,self.EndReload)
			self.clipammo = self.clipammo + 1
			self.ammo = self.ammo - 1
			self.reloadedshells = self.reloadedshells + 1
		else
			self.animationmanager:SetAnimationSequence("ReloadEnd",self.reloadspeed,300,1,self,self.FinalizeReload)
		end
	else
		self.currentaction=nil
		local rounds = self.clipsize - self.clipammo
		rounds = math.min(self.ammo,rounds)
		self.ammo = self.ammo - rounds
		self.clipammo = self.clipammo + rounds
	end
end

function Script:CanReload()
	if self.currentaction==nil then return true else return false end
end

function Script:Reload()
	if self.currentaction==nil then
		self.cancelreload=false
		if self.clipammo<self.clipsize and self.ammo>0 and self.currentaction==nil then
			self.currentaction="reload"
			self.reloadedshells=0
			if self.entity:FindAnimationSequence("Reload")>-1 then
				self.animationmanager:SetAnimationSequence("Reload",self.reloadspeed,300,1,self,self.EndReload)
				self.reloadstarttime=Time:GetCurrent()
				if self.sound.reload~=nil then self.sound.reload:Play() end
			elseif self.entity:FindAnimationSequence("ReloadStart")>-1 then
				self.animationmanager:SetAnimationSequence("ReloadStart",self.reloadspeed,300,1,self,self.EndReload)
			end				
		end
	end
end

function Script:FinalizeFire()
	self.currentaction=nil
end

function Script:EndFire()
	if self.entity:FindAnimationSequence("Pump")>-1 then
		self.animationmanager:SetAnimationSequence("Pump",0.03,300,1,self,self.FinalizeFire)
		if self.sound.pump~=nil then self.sound.pump:Play() end
	else
		self.currentaction=nil
	end
end

function Script:UpdateWorld()
	local bullet,n,dist
	local pickinfo=PickInfo()
	local firstbullet=true
	local travel
	
	for n,bullet in ipairs(self.bullets) do
		
		--Check how far the bullet has travelled
		dist = (bullet.position-bullet.origin):Length()
		if dist>self.bulletrange then
			table.remove(self.bullets,n)
			bullet.sprite:Release()
			bullet=nil
		end
		
		if bullet~=nil then
			travel = bullet.velocity/60.0*Time:GetSpeed()
			if self.entity.world:Pick(bullet.position,bullet.position+travel,pickinfo,0,true,Collision.Projectile) then
				
				table.remove(self.bullets,n)
				bullet.sprite:Release()
				
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
					
					--Smoke emitter
					e = self.emitter[1]:Instance()
					e = tolua.cast(e,"Emitter")
					e:Show()
					e:SetLoopMode(false,true)
					e:SetPosition(pickinfo.position+pickinfo.normal*0.1)
					local v=0.2
					e:SetVelocity(pickinfo.normal.x*v,pickinfo.normal.y*v,pickinfo.normal.z*v,0)
					
					--Play bullet impact noise
					e:EmitSound(self.sound.ricochet[math.random(#self.sound.ricochet)],30)
					
					if pickinfo.entity~=nil then
						
						--Add impulse to the hit object
						if pickinfo.entity:GetMass()>0 then
							--local force = pickinfo.normal*-1*self.bulletforce
							local dir = bullet.velocity:Normalize()
							local force = dir * self.bulletforce * math.max(0,-pickinfo.normal:Dot(dir))
							--force = force * math.max(0,-pickinfo.normal:Dot(d))--multiply by dot product of velocity and collided normal, to weaken glancing blows
							pickinfo.entity:AddPointForce(force,pickinfo.position)
						end
						
						--Extract a partial surface from the hit surface and make a bullet mark
						--To be added later
						--if pickinfo.surface~=nil then
						--	local aabb = AABB(pickinfo.position-radius,pickinfo.position+radius)	
						--	local surf = pickinfo.surface:Extract(aabb)
						--end
					end
				end
				
			else
				bullet.position = bullet.position+travel
				bullet.sprite:SetPosition(bullet.position - bullet.velocity:Normalize()*1)
				if bullet.sprite:Hidden() then
					dist = (bullet.position-bullet.origin):Length()
					if dist>bullet.sprite:GetSize().y then
						bullet.sprite:Show()
					end
				end
			end
		end
		firstbullet = false
	end
end

function Script:Fire()
	if self.player.weaponlowerangle==0 then
		local currenttime=Time:GetCurrent()
		if self.lastfiretime==nil then self.lastfiretime=0 end
		if currenttime-self.lastfiretime>self.refirerate then
			if self.currentaction==nil then			
				self.lastfiretime = currenttime
				if self.clipammo==0 then
					if self.sound.dryfire then
						if self.suspenddryfire~=true then
							self.sound.dryfire:Play()
						end
					end
				else
					self.currentaction="fire"
					if #self.sound.fire>0 then
						self.sound.fire[math.random(#self.sound.fire)]:Play()					
					end
					self.clipammo = self.clipammo - 1
					self.firetime = Time:GetCurrent()
					self.muzzlelight:Point(self.player.camera,1)
					self.muzzlelight:Show()
					self.muzzleflash:SetAngle(math.random(0,360))
					self.animationmanager:SetAnimationSequence("Fire",self.firespeed,300,1,self,self.EndFire)
					
					--Spawn bullet
					local n
					for n=1,self.pellets do
						local d = Transform:Normal(0,0,1,self.player.camera,nil)
						d = d + Vec3(math.random(-1,1),math.random(-1,1),math.random(-1,1)) * self.scatter
						d = d:Normalize()
						local p
						if self.muzzle then
							p=self.muzzle:GetPosition(true)
							self:SpawnBullet(p,d*self.bulletspeed)
						else
							System:Print("Warning: Muzzle entity not found.")
						end												
					end
				end
			else
				self.cancelreload=true
			end
		end
	end
end

--Creates a bullet
function Script:SpawnBullet(position,velocity)
	local bullet = {}
	bullet.sprite = tolua.cast(self.tracer:Instance(),"Sprite")
	bullet.sprite:SetPosition(position)
	bullet.sprite:AlignToVector(velocity)
	bullet.sprite:Hide()
	bullet.position = position
	bullet.origin = Vec3(position.x,position.y,position.z)
	bullet.velocity = velocity
	table.insert(self.bullets,bullet)
end

function Script:Draw()
	
	local t = Time:GetCurrent()

	if self.muzzlelight:Hidden()==false then
		if t-self.firetime>50 then
			self.muzzlelight:Hide()
		end
	end
	
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
		self.emitter[1]:Release()
		self.emitter[2]:Release()
		self.emitter=nil
	end
	if self.sound~=nil then
		ReleaseTableObjects(self.sound)
		self.sound=nil
	end
end

function Script:Cleanup()
	self.tracer:Release()
end
