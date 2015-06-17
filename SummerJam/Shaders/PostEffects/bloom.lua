--------------------------------------------------------
--Bloom effect by Josh and Shadmar
--------------------------------------------------------

--Called once at start
function Script:Start()
	
	--Load this script's shaders
	self.shader={}
	self.shader[0] = Shader:Load("Shaders/PostEffects/Bloom/bloom.shader")
	self.shader[1] = Shader:Load("Shaders/PostEffects/Bloom/hblur.shader")
	self.shader[2] = Shader:Load("Shaders/PostEffects/Bloom/vblur.shader")

end

--Called each time the camera is rendered
function Script:Render(camera,context,buffer,depth,diffuse,normals,emission)
	
	--Check if downsample buffers match current resolution
	if self.buffer~=nil then
			if self.buffer[0]:GetWidth()~=Math:Round(self.w/2) or self.buffer[0]:GetHeight()~=Math:Round(self.h/2) then
				self.buffer[0]:Release()
				self.buffer[1]:Release()
				self.buffer=nil
			end
	end
	
	--Create downsample buffers if they don't exist
	if self.buffer==nil then
			self.buffer={}	
			self.w=buffer:GetWidth()
			self.h=buffer:GetHeight()
			self.buffer[0]=Buffer:Create(Math:Round(self.w/2),Math:Round(self.h/2),1,0)
			self.buffer[1]=Buffer:Create(Math:Round(self.w/4),Math:Round(self.h/4),1,0)
			self.buffer[0]:GetColorTexture():SetFilter(Texture.Smooth)
			self.buffer[1]:GetColorTexture():SetFilter(Texture.Smooth)
	end
	
	--Perform horizontal blur
	self.buffer[0]:Enable()
	if self.shader[1] then self.shader[1]:Enable() end
	context:DrawImage(diffuse,0,0,self.buffer[0]:GetWidth(),self.buffer[0]:GetHeight())
	
	--Perform vertical blur
	self.buffer[1]:Enable()
	if self.shader[2] then self.shader[2]:Enable() end
	context:DrawImage(self.buffer[0]:GetColorTexture(),0,0,self.buffer[1]:GetWidth(),self.buffer[1]:GetHeight())
	
	--Bind the downsampled image
	buffer:Enable()
	diffuse:Bind(0)
	self.buffer[1]:GetColorTexture():Bind(1)
	
	--Enable the shader and draw the diffuse image onscreen
	if self.shader[0] then self.shader[0]:Enable() end
	context:DrawRect(0,0,buffer:GetWidth(),buffer:GetHeight())
	
end

--Called when the effect is detached or the camera is deleted
function Script:Detach()
	
	local index,o
	
	--Release shaders
	for index,o in ipairs(self.shader) do
		o:Release()
	end
	self.shader = nil	
	
	--Release buffers
	for index,o in ipairs(self.buffer) do
		o:Release()
	end
	self.buffer = nil	      
	
end
