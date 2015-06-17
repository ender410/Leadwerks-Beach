import "Scripts/AnimationManager.lua"
import "Scripts/Functions/GetEntityNeighbors.lua"

--Public values
Script.health=40--int "Health"
Script.enabled=true--bool "Enabled"
Script.target=nil--entity "Target"
Script.sightradius=30--float "Sight Range"
Script.senseradius=2--float "Hearing Range"
Script.teamid=2--choice "Team" "Neutral,Good,Bad"
Script.attackdelay=300--int "Attack delay"
Script.animspeedrun=0.04--float "Run anim speed"

--Private values
Script.damage=5
Script.attackrange=1.5
Script.updatefrequency=500
Script.lastupdatetime=0
Script.prevtarget=nil
Script.followingtarget=false
Script.maxaccel=15
Script.speed=6
Script.lastupdatetargettime=0
Script.attackmode=0
Script.attackbegan=0
Script.attack1sound=""--path "Attack 1 sound" "Wav file (*.wav):wav|Sound"
Script.attack2sound=""--path "Attack 2 sound" "Wav file (*.wav):wav|Sound"
Script.alertsound=""--path "Alert sound" "Wav file (*.wav):wav|Sound"
Script.deathsound=""--path "Death sound" "Wav file (*.wav):wav|Sound"
Script.idlesound=""--path "Idle sound" "Wav file (*.wav):wav|Sound"

function Script:Enable()--in
	if self.enabled==false then
		if self.health>0 then
			self.enabled=true
			if self.target~=nil then
				self:SetMode("roam")
			else
				self:SetMode("idle")
			end
		end
	end
end

function Script:ChooseTarget()
	local entities = GetEntityNeighbors(self.entity,self.sightradius,true)
	local k,entity
	for k,entity in pairs(entities) do
		if entity.script.teamid~=nil and entity.script.teamid~=0 and entity.script.teamid~=self.teamid then
			if entity.script.health>0 then
				local d = self.entity:GetDistance(entity)
				local pickinfo=PickInfo()
				if self.entity.world:Pick(self.entity:GetPosition()+Vec3(0,1.6,0),entity:GetPosition()+Vec3(0,1.6,0),pickinfo,0,false,Collision.LineOfSight)==false then
					return entity.script
				end
			end
		end
	end
end

function Script:DistanceToTarget()
	local pos = self.entity:GetPosition()
	local targetpos = self.target.entity:GetPosition()
	if math.abs(targetpos.y-pos.y)<1.5 then
		return pos:xz():DistanceToPoint(targetpos:xz())
	else
		return 100000--if they are on different vertical levels, assume they can't be reached
	end
end

function Script:TargetInRange()
	local pos = self.entity:GetPosition()
	local targetpos = self.target.entity:GetPosition()
	if math.abs(targetpos.y-pos.y)<1.5 then
		if pos:xz():DistanceToPoint(targetpos:xz())<self.attackrange then
			return true
		end
	end
	return false
end

function Script:Start()
	self.entity:SetPickMode(Entity.BoxPick,true)
	self.entity:SetPickMode(0,false)
	self.animationmanager = AnimationManager:Create(self.entity)
	if self.enabled then
		if self.target~=nil then
			self:SetMode("roam")
		else
			self:SetMode("idle")
		end
	end
	self.sound={}
	if self.alertsound then self.sound.alert = Sound:Load(self.alertsound) end
	self.sound.attack={}
	if self.attack1sound then self.sound.attack[1] = Sound:Load(self.attack1sound) end
	if self.attack2sound then self.sound.attack[2] = Sound:Load(self.attack2sound) end
	if self.idlesound then self.sound.idle = Sound:Load(self.idlesound) end
	self.lastidlesoundtime=Time:GetCurrent()+math.random(1,20000)
end

function Script:Hurt(damage,distributorOfPain)
	if self.health>0 then
		if self.target==nil then
			self.target=distributorOfPain
			self:SetMode("attack")
		end
		self.health = self.health - damage
		if self.health<=0 then
			self.entity:SetMass(0)
			self.entity:SetCollisionType(0)
			self.entity:SetPhysicsMode(Entity.RigidBodyPhysics)
			self:SetMode("dying")
		end
	end
end

function Script:EndDeath()
	self:SetMode("dead")
end

function Script:DirectMoveToTarget()
	self.entity:Stop()
	local targetpos = self.target.entity:GetPosition()
	local pos = self.entity:GetPosition()
	local dir = Vec2(targetpos.z-pos.z,targetpos.x-pos.x):Normalize()
	local angle = -Math:ATan2(dir.y,-dir.x)
	self.entity:SetInput(angle,self.speed)
end

function Script:SetMode(mode)
	if mode~=self.mode then
		local prevmode=self.mode
		self.mode=mode
		if mode=="idle" then
			self.target=nil
			self.animationmanager:SetAnimationSequence("Idle",0.02)
			self.animationmanager.animations[1].frameoffset = math.random(1,1000)
			self.entity:Stop()--stop following anything
		elseif mode=="roam" then
			if self.target~=nil then
				self.animationmanager:SetAnimationSequence("Run",self.animspeedrun)
				self.entity:GoToPoint(self.target:GetPosition(true),5,5)
			else
				self:SetMode("idle")
			end
		elseif mode=="attack" then
			self:EndAttack()
		elseif mode=="chase" then
			if self.entity:Follow(self.target.entity,self.speed,self.maxaccel) then
				if prevmode~="chase" then
					if self.sound.alert then self.entity:EmitSound(self.sound.alert) end
				end
				self.followingtarget=true
				self.animationmanager:SetAnimationSequence("Run",self.animspeedrun,300)
				if self:DistanceToTarget()<self.attackrange*2 then
					self.followingtarget=false
					self.entity:Stop()
					self:DirectMoveToTarget()
				end
			else
				self.target=nil
				self:SetMode("idle")
				return
			end
		elseif mode=="dying" then
			self.entity:Stop()
			self.animationmanager:SetAnimationSequence("Death",0.04,300,1,self,self.EndDeath)			
		elseif mode=="dead" then
			self.entity:SetCollisionType(0)
			self.entity:SetMass(0)
			self.entity:SetShape(nil)
			self.entity:SetPhysicsMode(Entity.RigidBodyPhysics)
			self.enabled=false
		end
	end
end

function Script:EndAttack()
	if self.mode=="attack" then	
		if self.target.health<=0 then
			self:SetMode("idle")
			return
		end
		local d = self:DistanceToTarget()
		if d>self.attackrange then
			self:SetMode("chase")
			return
		end
		self.entity:Stop()
		self.attackmode = 1-self.attackmode--switch between right and left attack modes	
		self.animationmanager:SetAnimationSequence("Attack"..tostring(1+self.attackmode),0.05,300,1,self,self.EndAttack)
		self.attackbegan = Time:GetCurrent()
		if self.sound.attack[self.attackmode+1] then
			if math.random()>0.75 then
				self.entity:EmitSound(self.sound.attack[self.attackmode+1])
			end
		end
	end
end

function Script:UpdatePhysics()
	if self.enabled==false then return end

	local t = Time:GetCurrent()
	self.entity:SetInput(self.entity:GetRotation().y,0)
	
	if self.sound.idle then
		if t-self.lastidlesoundtime>0 then
			self.lastidlesoundtime=t+20000*Math:Random(0.75,1.25)
			self.entity:EmitSound(self.sound.idle,20)
		end
	end
	
	if self.mode=="idle" then
		if t-self.lastupdatetargettime>250 then
			self.lastupdatetargettime=t
			self.target = self:ChooseTarget()
			if self.target then
				self:SetMode("chase")
			end
		end
	elseif self.mode=="roam" then
		if self.entity:GetDistance(self.target)<1 then
			self:SetMode("idle")
		end
	elseif self.mode=="chase" then
		if self.target.health<=0 then
			self:SetMode("idle")
			return
		end
		if self:TargetInRange() then
			self:SetMode("attack")
		elseif self:DistanceToTarget()<self.attackrange*2 then
			self.followingtarget=false
			self.entity:Stop()
			self:DirectMoveToTarget()
		else
			if self.followingtarget==false then
				if self.entity:Follow(self.target.entity,self.speed,self.maxaccel) then
					self:SetMode("idle")
				end
			end
		end
	elseif self.mode=="attack" then
		if self.attackbegan~=nil then
			if t-self.attackbegan>self.attackdelay then
				if self.target.entity:GetDistance(self.entity)<1.5 then
					self.attackbegan=nil
					self.target:Hurt(self.damage)
				end
			end
		end
		local pos = self.entity:GetPosition()
		local targetpos = self.target.entity:GetPosition()
		local dx=targetpos.x-pos.x
		local dz=targetpos.z-pos.z
		self.entity:AlignToVector(-dx,0,-dz)
	end
end

function Script:Draw()
	if self.enabled==false then return end
	self.animationmanager:Update()
end
