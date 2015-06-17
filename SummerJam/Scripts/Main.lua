--Initialize Steamworks (optional)
Steamworks:Initialize()

--Set the application title
title="SummerJam"

--Create a window
local windowstyle = Window.Titlebar
if System:GetProperty("fullscreen")=="1" then windowstyle=windowstyle+Window.FullScreen end
window=Window:Create(title,0,0,System:GetProperty("screenwidth","1024"),System:GetProperty("screenheight","768"),windowstyle)
window:HideMouse()

--Create the graphics context
context=Context:Create(window,0)
if context==nil then return end

--Create a world
world=World:Create()
world:SetLightQuality((System:GetProperty("lightquality","1")))

--Load a map
local mapfile = System:GetProperty("map","Maps/start.map")
if Map:Load(mapfile)==false then return end
	
while window:KeyDown(Key.Escape)==false do
	
	--If window has been closed, end the program
	if window:Closed() then break end
	
	--Handle map change
	if changemapname~=nil then
		
		--Clear all entities
		world:Clear()
		
		--Load the next map
		Time:Pause()
		if Map:Load("Maps/"..changemapname..".map")==false then return end
		Time:Resume()
		
		changemapname = nil
	end	
	
	--Update the app timing
	Time:Update()
	
	--Update the world
	world:Update()
	
	--Render the world
	world:Render()
		
	--Render statistics
	context:SetBlendMode(Blend.Alpha)
	if DEBUG then
		context:SetColor(1,0,0,1)
		context:DrawText("Debug Mode",2,2)
		context:SetColor(1,1,1,1)
		context:DrawStats(2,22)
		context:SetBlendMode(Blend.Solid)
	else
		--Toggle statistics on and off
		if (window:KeyHit(Key.F11)) then showstats = not showstats end
		if showstats then
			context:SetColor(1,1,1,1)
			context:DrawText("FPS: "..Math:Round(Time:UPS()),2,2)
		end
	end
	
	--Refresh the screen
	context:Sync(true)
	
end
