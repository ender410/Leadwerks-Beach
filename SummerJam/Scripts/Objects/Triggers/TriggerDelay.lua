Script.delay=1000--int "Delay"
Script.activatetime=0

function Script:Activate()--in
	self.activatetime = Time:GetCurrent()+self.delay
end

function Script:UpdatePhysics()
	if self.activatetime>0 then
		if Time:GetCurrent()>self.activatetime then
			self.activatetime=0
			self.component:CallOutputs("Activate")
		end
	end
end
