--[[
This script will spin any entity around an axis using physics forces.
]]--
Script.enabled=true--bool "Enabled"
Script.axis = 1--choice "Axis" "X,Y,Z"
Script.motorspeed = 60--float "Speed"
Script.angle = 0

function Script:Start()
	if self.entity:GetMass()==0 then
		Debug:Error("Entity mass must be greater than zero.")
	end
	local axisx=0
	local axisy=0
	local axisz=0
	if self.axis==0 then axisx=1 end
	if self.axis==1 then axisy=1 end
	if self.axis==2 then axisz=1 end	
	self.joint=Joint:Hinge(self.entity.position.x,self.entity.position.y,self.entity.position.z,axisx,axisy,axisz,self.entity,nil)
	self.joint:EnableMotor()
	self.joint:SetMotorSpeed(math.abs(self.motorspeed))
end

function Script:UpdatePhysics()
	if self.enabled then
		self.angle = self.angle + self.motorspeed / 60.0
		self.joint:SetAngle(self.angle)
	end
end

function Script:Disable()--in
	self.enabled=false
end

function Script:Enable()--in
	self.enabled=true
end

function Script:Release()
	if self.joint then
		self.joint:Release()
		self.joint=nil
	end
end
