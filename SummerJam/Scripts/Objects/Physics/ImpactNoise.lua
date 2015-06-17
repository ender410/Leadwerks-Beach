--[[-------------------------------------------------------------------

This is a simple script to provide an impact sound for a physically
interactive object.

]]---------------------------------------------------------------------

Script.soundfile1=""--path "Sound 1" "Wac file (*.wav):wav|Sound"
Script.soundfile2=""--path "Sound 2" "Wac file (*.wav):wav|Sound"
Script.soundfile3=""--path "Sound 3" "Wac file (*.wav):wav|Sound"
Script.soundfile4=""--path "Sound 4" "Wac file (*.wav):wav|Sound"
Script.threshhold=2--float "Threshhold"
Script.maxfrequency=300--minimum delay between sound plays
Script.range=20--float "Range"

--Global values
ImpactNoiseLastSoundTime=0-- This will be shared among all instances of this script and ensure we don't play too many sounds

function Script:Start()
	self.sound={}
	for n=1,4 do
		local filepath = self["soundfile"..tostring(n)]
		if filepath~="" then
			local noise = Sound:Load(filepath)
			if noise~=nil then
				table.insert(self.sound,noise)
				--self.sound[#self.sound+1]=noise
			end
		end
	end
end

function Script:Collision(entity, position, normal, speed)
	if speed>self.threshhold then
		if #self.sound>0 then
			local collisiontype = entity:GetCollisionType()
			if collisiontype==Collision.Prop or collisiontype==Collision.Scene then
				local t = Time:GetCurrent()
				if t-ImpactNoiseLastSoundTime>self.maxfrequency then
					ImpactNoiseLastSoundTime=t
					local n=math.random(#self.sound)
					local noise = self.sound[n]
					self.entity:EmitSound(noise,self.range)
				end
			end
		end
	end
end
