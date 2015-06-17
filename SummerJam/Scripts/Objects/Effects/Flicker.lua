Script.frequency=200--int "Frequency" 0 10000
Script.variation=0.25--float "Variation" 0 1
Script.strength=0.5--float "Strength" 0 1
Script.Recursive=true--bool
Script.nextupdatetime=0
Script.state=false

function Script:Draw()
	if self.color==nil then
		self.color = self.entity:GetColor()
	end

	local t = Time:GetCurrent()
	
	if t>self.nextupdatetime then
		self.nextupdatetime=t + self.frequency + math.random(-self.frequency*self.variation,self.frequency*self.variation)

		--Update the light
		self.state = not self.state
		if self.state then
			self.entity:SetColor(self.color,Color.Diffuse,self.Recursive)
		else
			self.entity:SetColor(self.color*(1.0-self.strength),Color.Diffuse,self.Recursive)
		end

	end
end
