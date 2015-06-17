Script.health=100
Script.levelcomplete=false
Script.coinscollected=0
if TotalCoins==nil then
	TotalCoins=0
end

function Script:Start()
	self.camera = Camera:Create()
	self.startposition = self.entity:GetPosition(true)
	self.font = Font:Load("Fonts/Ranchers-Regular.ttf",32)
	if self.font==nil then
		local context = Context:GetCurrent()
		self.font = context:GetFont()
	end
	self:Respawn()
end

function Script:SetLevelComplete(nextmapname)
	self.nextmapname=nextmapname
	self.levelcomplete=true
	self.levelcompletetime=Time:GetCurrent()
end

function Script:TakeDamage(damage)
	self.health = self.health - damage
	if self.health<=0 then
		self:Respawn()
	end
end

function Script:CollectCoin()
	self.coinscollected=self.coinscollected+1
end

function Script:Respawn()
	self.health=100
	self.entity:SetPosition(self.startposition)
	self.entity:SetRotation(0,0,0)
	self.entity:SetVelocity(Vec3(0,0,0))
	self.entity:SetOmega(Vec3(0,0,0))
	self.gamestarttime = Time:GetCurrent()+2000
end

function Script:UpdateWorld()
	self.camera:SetRotation(45,0,0)
	self.camera:SetPosition(self.entity:GetPosition())
	self.camera:Move(0,0,-4)
end

function Script:UpdatePhysics()
	local window = Window:GetCurrent()
	local movex=0
	local movey=0
	local movez=0
	local force=10
	local jumpforce=800
	
	if Time:GetCurrent()<self.gamestarttime then
		return
	end
	
	if self.levelcomplete then
		self.entity:SetMass(0)
		return
	end
	
	if window:KeyDown(Key.A) then
		movex = movex - force
	end
	if window:KeyDown(Key.D) then
		movex = movex + force
	end
	if window:KeyDown(Key.S) then
		movez = movez - force
	end
	if window:KeyDown(Key.W) then
		movez = movez + force
	end	
	self.entity:AddForce(movex,movey,movez,true)
end

function Script:Collision(entity, position, normal, speed)

end

function Script:PostRender(context)
	local t = Time:GetCurrent()
	local timetostart = self.gamestarttime-t
	context:SetBlendMode(Blend.Alpha)
	context:SetColor(1,0,0,1)
	local text
	local prevfont = context:GetFont()
	prevfont:AddRef()
	context:SetFont(self.font)
	local fh=self.font:GetHeight()
	local timestring
	
	if self.levelcomplete==false then
		self.timeelapsed = t - self.gamestarttime
		if self.timeelapsed>0 then
			local seconds = math.floor(self.timeelapsed/1000)
			local minutes = math.floor(seconds / 60)
			seconds = seconds - minutes * 60
			if seconds<10 then
				seconds = "0"..seconds
			end
			text = minutes..":"..seconds
		else
			text = "0:00"
		end
		self.timestring=text
	end
	
	if self.levelcomplete then
		if t-self.levelcompletetime>3000 then
			changemapname=self.nextmapname
		end
		text="Level Complete"
		context:DrawText(text,(context:GetWidth()-self.font:GetTextWidth(text))/2,(context:GetHeight()-fh)/2-fh*1.5)
		text="Time: "..self.timestring
		context:DrawText(text,(context:GetWidth()-self.font:GetTextWidth(text))/2,(context:GetHeight()-fh)/2)
		text="Coins: "..self.coinscollected.."/"..TotalCoins
		context:DrawText(text,(context:GetWidth()-self.font:GetTextWidth(text))/2,(context:GetHeight()-self.font:GetHeight())/2+fh*1.5)		
	else
		if timetostart>-1000 then
			text="Go!"
			if timetostart>0 then
				text="Get Ready..."
			end
			context:DrawText(text,(context:GetWidth()-self.font:GetTextWidth(text))/2,(context:GetHeight()-self.font:GetHeight())/2)
		else
			text="Time: "..self.timestring
			context:DrawText(text,context:GetWidth()-self.font:GetTextWidth(text)-8,8)
			text="Coins: "..self.coinscollected.."/"..TotalCoins
			context:DrawText(text,context:GetWidth()-self.font:GetTextWidth(text)-8,8+fh*1.5)
		end	
	end
	
	context:SetFont(prevfont)
	prevfont:Release()
	context:SetBlendMode(Blend.Solid)
	context:SetColor(1,1,1,1)
end