local function split(str, sep)
	local sep, fields = sep or "\n", {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

local function closestFactors(val)
	local test = math.ceil(math.sqrt(val))
	while val % test ~= 0 do
		test = test - 1
	end

	return test, val / test
end

local function CompileBF(gscript)
	gscript = gscript:gsub("\r", "")

	-- Finished brainfuck code
	local bf = ""
	-- Split the gscript into lines
	local lines = split(gscript, "\n")

	-- amt is the amount we want to move by
	local function move(amt)
		local str = ">"
		
		if amt < 0 then
			amt = amt * -1
			str = "<"
		end

		-- Move > or < using that relative position
		bf = bf .. string.rep(str, amt)
		-- Set our memory location to the new one
	end

	-- Set cell to specific value
	local function set(val, preserve)
		-- TODO: Optimize out zeroing for cells that are already zero
		bf = bf .. "[-]"

		if val > 7 and not preserve then
			local f1, f2 = closestFactors(val)

			if f1 == 1 then
				f1, f2 = closestFactors(val - 1)
				bf = bf .. "+"
			end

			--[[
				Steps:
				1. Move to scratch space (mem + 1)
				2. Zero the scratch space
				3. Set the scratch space to the first factor
				4. Move back to target cell and add second factor
				5. Move to scratch space and decrement
				6. Repeat from 4 until the scratch space is zero again
				7. Move back to target space
			]]
			bf = bf .. ">[-]" .. string.rep("+", f1) .. "[<" .. string.rep("+", f2) .. ">-]<"
		else
			bf = bf .. string.rep("+", val)
		end
	end

	-- Go over each line
	for num, line in ipairs(lines) do
		local parts = split(line, " ")
		local cmd = parts[1]
		
		if cmd == "set" then
			-- Clobbers the next memory location over if setting a val > 7
			local v = tonumber(parts[2])
			set(v, false)
		elseif cmd == "setp" then
			-- Does not clobber but is annoying to read
			local v = tonumber(parts[2])
			set(v, true)
		elseif cmd == "sets" then
			-- Set memory locations to a string
			table.remove(parts, 1)
			local str = table.concat(parts, " ")
			local vals = {string.byte(str, 1, #str)}

			for i, v in ipairs(vals) do
				set(v, false)
				bf = bf .. ">"
			end
			-- Memory pointer ends up at the null byte, unlike set and setp
			-- Since the null byte is the end of the string
		elseif cmd == "zero" then
			bf = bf .. "[-]"
		elseif cmd == "inc" then
			bf = bf .. "+"
		elseif cmd == "dec" then
			bf = bf .. "-"
		elseif cmd == "left" then
			bf = bf .. "<"
		elseif cmd == "right" then
			bf = bf .. ">"
		elseif cmd == "tape" then
			local t = tonumber(parts[2])
			move(t)
		elseif cmd == "ff" then
			-- Fast forward to next empty block
			bf = bf .. "[>]"
		elseif cmd == "rw" then
			-- Rewind to furthest back empty block
			bf = bf .. "[<]"
		elseif cmd == "prints" then
			bf = bf .. "[.>]"
		elseif string.find("+-<>[],.", cmd) then
			bf = bf .. cmd
		else
			print("Unknown command: '" .. cmd .. "'")
		end
	end

	-- Optimization
	local lenB = #bf
	bf = bf:gsub("<>", ""):gsub("><", "")
	local lenA = #bf
	print("Optimized away " .. tostring(lenB - lenA) .. " commands")

	return bf
end

return {
	["CompileBF"] = CompileBF
}