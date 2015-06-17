Script.enabled = true --bool "Enabled"
Script.speed  = 10 --float "Speed"
Script.target = "" --entity "Target waypoint"
Script.originPosition = nil
Script.targetPosition = nil
Script.currentPosition = nil
Script.currentRotation = nil	
Script.moving = nil
Script.oldMass = nil

function Script:Start()
	self.originalrotation = self.entity:GetRotation()

	self.oldMass = self.entity:GetMass()

	if self.entity:GetShadowMode()>0 then
		self.entity:SetShadowMode(2)--Light.Dynamic
	end

	if self.enabled then
		if self.entity:GetMass()==0 then
			Debug:Error("Entity mass must be greater than zero.")
		end
	else
		self.entity:SetMass(0)
	end
	self.entity:SetGravityMode(false) 	
	self.entity:SetCollisionType(Collision.Scene)

	if self.target == nil then
		Debug:Error("No target assigned")
	end
	
	self:SetTarget(self.target)
end

function Script:SetTarget(newTarget)
	self.currentPosition = self.entity:GetPosition()
	self.originPosition = self.entity:GetPosition()	
	self.targetPosition = newTarget:GetPosition()
	--self.distance = self.originPosition:DistanceToPoint(self.targetPosition)
	self.target = newTarget
	
	local pos = self.entity:GetPosition(true)
	local targetpos = self.target:GetPosition(true)
	local pin = pos - targetpos
	self.distance = pin:Length()
	pin = pin:Normalize()
	
	if self.joint then
		self.joint:DisableMotor()
		self.joint:Release()
	end
	self.joint=Joint:Slider(targetpos.x,targetpos.y,targetpos.z,pin.x,pin.y,pin.z,self.entity,nil)
	self.joint:EnableMotor()
	self.joint:SetMotorSpeed(self.speed)
	self.joint:SetAngle(-self.distance)
end

function Script:Enable()--in
	self.enabled = true
end

function Script:Disable()--in
	self.enabled = false
	self.entity:SetMass(0)
end

function Script:UpdatePhysics()
	if self.enabled then
		
		--Calculate movement
		local currentpos = self.entity:GetPosition(true)
		local targetpos = self.target:GetPosition(true)
		local d = currentpos:DistanceToPoint(targetpos)
		if d<0.1 then
			--When the target has been reached
			--self.entity:PhysicsSetPosition(self.targetPosition.x, self.targetPosition.y, self.targetPosition.z)
			--self.enabled = false
			self.component:CallOutputs("WaypointReached")
			--Check if the target that we have reached also has a target, which is then our new target/waypoint	
			if self.target.script.target ~= nil then	
				self:SetTarget(self.target.script.target)
			end
		end
	else
		--self.entity:PhysicsSetPosition(self.currentPosition.x, self.currentPosition.y, self.currentPosition.z)
		--self.entity:PhysicsSetRotation(self.currentRotation.x, self.currentRotation.y, self.currentRotation.z)
	end
end
