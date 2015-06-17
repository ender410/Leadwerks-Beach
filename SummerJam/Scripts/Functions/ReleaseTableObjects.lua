function ReleaseTableObjects(t)
	if type(t)=="table" then
		local key,value
		for key,value in pairs(t) do
			if type(value)=="table" then
				ReleaseTableObjects(value)		
			elseif type(value)=="userdata" then
				value:Release()
			end
		end
	end
end
