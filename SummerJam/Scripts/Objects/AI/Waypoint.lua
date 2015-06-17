Script.target0 = nil--entity "Target 1"
Script.target1 = nil--entity "Target 2"
Script.target2 = nil--entity "Target 3"
Script.target3 = nil--entity "Target 4"
Script.range = 2--float "Range"

function Script:Start()
	self.targets={self.target0,self.target1,self.target2,self.target3}
end

function Script:GetNextTarget(entity)
	local k,v
	local temp={}
	for k,v in pairs(self.targets) do
		if v~=entity then
			temp[#temp+1]=v
		end
	end
	if #temp==0 then return nil end
	return temp[math.random(#temp)]
end
