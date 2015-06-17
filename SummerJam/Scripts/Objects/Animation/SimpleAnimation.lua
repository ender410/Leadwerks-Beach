Script.Speed=1.0--float
Script.Sequence=0--int

function Script:Draw()
	local t = Time:GetCurrent()
	self.entity:SetAnimationFrame(t/100.0*self.Speed,1,self.Sequence)
end
