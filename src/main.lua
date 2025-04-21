local galaxy, gscript = unpack(require("galaxy"))
local filename = ""
local vm = nil
local font_height = 16
local commands_per_tick = 1

local speed = 0

local bgcolor = {0,0,0}

--[[
	0 = Step
	1 = With update
	2 = As fast as possible
]]
local run_mode = 0

function love.load()
	local inconsolata = love.graphics.newFont("font/Inconsolata-Regular.ttf", 16)
	font_height = inconsolata:getHeight()
	love.graphics.setFont(inconsolata)
end

local screen = {
	pos = { math.floor(love.graphics.getWidth() / 2) - 128, math.floor(love.graphics.getHeight() / 2) - 128 },
	pixels = {}
}

local peripherals = {
	{
		Name = "Input",
		Takes = 1,
		Run = function(mode)
			if mode == 1 then
				local x = love.mouse.getX() - screen.pos[1]
				local y = love.mouse.getY() - screen.pos[2]
				if x < 0 then x = 0 elseif x > 255 then x = 255 end
				if y < 0 then y = 0 elseif y > 255 then y = 255 end
				vm.Input(x)
				vm.Input(y)
			end
		end
	},
	{
		Name = "Graphics",
		Takes = 5,
		Run = function(x, y, r, g, b)
			local i = x + 256 * y
			--print(r, g, b)

			screen.pixels[i] = {
				r = r / 255,
				g = g / 255,
				b = b / 255
			}
		end
	}
}

function love.update(dt)
	if vm then
		if run_mode == 1 and vm.IsReady() then
			for i = 1, commands_per_tick do
				vm.Step()
			end
		end

		speed = math.floor(1 / dt) * commands_per_tick
	end
end

function love.draw()
	love.graphics.clear(bgcolor)

	-- Draw screen background
	love.graphics.setColor(0, 30/255, 5/255)
	love.graphics.rectangle("line", screen.pos[1], screen.pos[2], 255, 255)
	love.graphics.rectangle("fill", screen.pos[1], screen.pos[2], 255, 255)

	-- Draw screen pixels
	local pixels = screen.pixels
	for i, px in pairs(pixels) do
		local x = i % 256
		local y = math.floor(i / 256)

		love.graphics.setColor(px.r, px.g, px.b)
		love.graphics.points(screen.pos[1] + x, screen.pos[2] + y)
	end

	love.graphics.setColor(1, 1, 1)

	local lines = setmetatable({}, {
		["__index"] = {
			["push"] = function(this, val)
				this[#this + 1] = val
			end,
			["pop"] = function(this)
				local ret = this[#this]
				this[#this] = nil
				return ret
			end
		}
	})

	if not vm then
		lines:push("Drag and drop a .b/.bf or .gsc file into here!")
	else
		local status = vm.GetStatus()
		local mem = vm.GetMemoryIndex()

		lines:push("Loaded " .. filename .. ".")
		lines:push("Code position: " .. tostring(vm.GetCodeIndex()))
		lines:push("Memory position: " .. tostring(mem))
		lines:push("Value at location: " .. tostring(vm.Peek(mem)))
		
		local array = "[ "
		local spaces = ""

		for i = mem - 4, mem + 4 do
			if i == mem then
				spaces = string.rep(" ", #array)
			end

			array = array .. tostring(vm.Peek(i) .. " ")
		end

		lines:push(array .. "]")
		lines:push(spaces .. "^")
		lines:push("Last executed: " .. tostring(vm.GetLastExecuted()))
		lines:push("Next to execute: " .. tostring(vm.GetNextToExecute()))

		if selected ~= 0 then
			--lines:push("Selected peripheral: " .. peripherals[selected].Name)
		end

		if status == "Pause" then
			if run_mode == 1 then
				lines:push("Running VM at ~" .. tostring(speed) .. " chars/sec.")
			elseif run_mode == 0 then
				lines:push("VM is paused.")
			end
		elseif status == "Done" then
			lines:push("VM has finished execution.")
		elseif status == "Input" then
			lines:push("VM is awaiting input. Press a key...")
		elseif status == "Error" then
			lines:push("VM has encountered an error: " .. vm.GetError())
		end

		--[[lines:push("Output buffer:")
		lines:push(vm.GetBuffer())]]
	end

	for i, v in ipairs(lines) do
		love.graphics.print(v, 2, 2 + font_height * (i - 1))
	end
end

local selected = 0
local args = {}

function setUpPeripherals(machine)
	machine.SetOutputHandler(function(byte)
		if selected == 0 and byte <= #peripherals then
			selected = byte
			--print("Selected peripheral " .. tostring(byte))
		else
			local p = peripherals[selected]

			if p then
				args[#args + 1] = byte

				if #args == p.Takes then
					selected = 0
					--print("Calling peripheral " .. p.Name)
					p.Run(unpack(args))
					args = {}
				end
			end
		end
	end)
end

function love.filedropped(file)
	local filename = file:getFilename()
	local code

	if filename:sub(-2, -1) == ".b" or filename:sub(-3, -1) == ".bf" then
		print("Brainfuck file dropped. Reading...")
		file:open("r")
		code = file:read()
	elseif #filename > 4 and filename:sub(-4, -1) == ".gsc" then
		print("GScript file dropped. Reading...")
		file:open("r")
		local script = file:read()

		print("Compiling...")
		code = gscript.CompileBF(script)
		print(code)
	else
		print("Not a Brainfuck or GSC file.")
		return
	end

	file:close()

	print("Creating vm...")
	vm = galaxy.CreateVM()
	vm.SetCode(code)

	setUpPeripherals(vm)

	print("Done.")
end

function love.textinput(t)
	if vm and vm.GetStatus() == "Input" then
		vm.Input(t)
	end
end

function love.keypressed(key, code, isrepeat)
	if vm then
		if vm.GetStatus() ~= "Input" then
			if key == "right" and run_mode == 0 then
				vm.Step()
			elseif key == "space" then
				if run_mode == 0 then
					run_mode = 1
				else
					run_mode = 0
				end
			elseif key == "up" then
				commands_per_tick = commands_per_tick + 1
			elseif key == "down" and commands_per_tick > 1 then
				commands_per_tick = commands_per_tick - 1
			end
		elseif love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl") then
			if key == "z" then
				vm.Input(string.char(0))
			end
		end
	end
end