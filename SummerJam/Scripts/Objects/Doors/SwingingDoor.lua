Script.openstate=false--bool "Start Open"
Script.offset=Vec3()--vec3 "Offset"
Script.pin=Vec3(0,1,0)--vec3 "Pin"
Script.distance=90--float "Distance"
Script.movespeed=60--float "Turn speed"
Script.opensoundfile=""--path "Open Sound" "Wav File (*wav):wav|Sound"
Script.loopsoundfile=""--path "Loop Sound" "Wav File (*wav):wav|Sound"
Script.closesoundfile=""--path "Close Sound" "Wav File (*wav):wav|Sound"
Script.closedelay=2000--int "Close delay"
Script.enabled=true
Script.manualactivation=false--bool "Manual activate"
Script.opentime=0

function Script:Start()

	--Disable gravity
	self.entity:SetGravityMode(false)

	--Disable Use() function is manual activation is not allowed
	if self.manualactivation==false then self.Use=nil end	

	--Error check to make sure mass>0
	if self.entity:GetMass()==0 then Debug:Error("Entity mass must be greater than 0.") end
	
	--Load the sounds, if specified
	if self.opensoundfile~="" then self.opensound = Sound:Load(self.opensoundfile) end
	if self.loopsoundfile~="" then self.loopsound = Sound:Load(self.loopsoundfile) end
	if self.closesoundfile~="" then self.closesound = Sound:Load(self.closesoundfile) end
	
	--Create a motorized slider joint
	local position=self.entity:GetPosition(true)+self.offset
	self.joint=Joint:Hinge(position.x,position.y,position.z,self.pin.x,self.pin.y,self.pin.z,self.entity,nil)
	if self.openstate then
		self.openangle=0
		self.closedangle=-self.distance
	else
		self.openangle=self.distance
		self.closedangle=0
	end

	--Enable the motor
	self.joint:EnableMotor()

	--Set the motor speed
	self.joint:SetMotorSpeed(self.movespeed)
end

--Use function - this will be called when the player hits the "use" key when looking at this
function Script:Use()
	--Only allow this if the object is enabled
	if self.enabled then
		if self.openstate then
			--Make the door close
			self:Close()
		else
			--Make the door open
			self:Open()
		end
	end
end

function Script:Stop()
	if self.opensound then self.opensound:Release() end
	if self.loopsound then self.loopsound:Release() end
	if self.closesound then self.closesound:Release() end
	if self.loopsource then self.loopsource:Release() end
end


function Script:Open()--in
	if self.enabled then
		self.opentime = Time:GetCurrent()
		if self.openstate==false then
			self.openstate=true			
			if self.opensound then
				self.entity:EmitSound(self.opensound)
			end
			self.joint:SetAngle(self.openangle)		
			self.component:CallOutputs("Open")
		end
	end
end

function Script:Close()--in
	if self.enabled then
		if self.openstate then
			self.openstate=false
			if self.loopsource then
				self.loopsource:Release()
				self.loopsource=nil
			end
			if self.closesound then
				self.entity:EmitSound(self.closesound)
			end
			self.joint:SetAngle(self.closedangle)
			self.component:CallOutputs("Close")
		end
	end
end

function Script:Disable()--in
	self.enabled=false
end

function Script:Enable()--in
	self.enabled=true
end

function Script:UpdatePhysics()
	if self.closedelay>0 then
		if self.openstate then
			local time = Time:GetCurrent()
			if time-self.opentime>self.closedelay then
				self:Close()
			end
		end
	else
		self.UpdatePhysics=nil--This will remove the function and it won't get called again
	end
end
