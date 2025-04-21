local function CreateVM()
	local State = {
		Status = "Pause",
		Error = nil,
		Input = {},
		Buffer = {},
		OutputHandler = nil,
		Code = "",
		CodeIndex = 1,
		Memory = {0},
		MemoryIndex = 1,
		LastExecuted = "",
		NextToExecute = "",
		ReturnStack = setmetatable({}, {
			["__index"] = {
				["push"] = function(this, val)
					-- print("Push to return stack " .. tostring(val))
					this[#this + 1] = val
				end,
				["pop"] = function(this)
					local ret = this[#this]
					-- print("Pop return stack " .. tostring(ret))
					this[#this] = nil
					return ret
				end
			}
		})
	}

	local function IsReady()
		return State.Status == "Pause"
	end

	local function Input(t)
		State.Input[#State.Input + 1] = t
		
		if State.Status == "Input" then
			State.Status = "Pause"
		end
	end

	local function ClearBuffer()
		State.Buffer = ""
	end

	local function SetOutputHandler(fn)
		State.OutputHandler = fn
	end

	local function SetCode(code)
		-- Pre-process to remove non-brainfuck characters
		-- Significantly speeds up execution for commented files
		local new_code = {}
		
		for i = 1, #code do
			local c = code:sub(i, i)
			if string.find("+-<>[],.", c, 1, true) ~= nil then
				new_code[#new_code + 1] = c
			end
		end
		
		State.Code = table.concat(new_code)
		State.NextToExecute = new_code[1]
	end

	local function Peek(location)
		if location < 1 then return 0 end
		local val = State.Memory[location]
		if not val then val = 0 end
		return val
	end

	local function GetStatus()
		return State.Status
	end

	local function GetBuffer()
		return State.Buffer
	end

	local function GetError()
		return State.Error
	end

	local function GetCodeIndex()
		return State.CodeIndex
	end

	local function GetMemoryIndex()
		return State.MemoryIndex
	end

	local function GetLastExecuted()
		return State.LastExecuted
	end

	local function GetNextToExecute()
		return State.NextToExecute
	end

	local function Step()
		if not IsReady() then
			return
		end

		local memory = State.Memory
		local mem_ptr = State.MemoryIndex
		local code_ptr = State.CodeIndex
		local command = State.Code:sub(code_ptr, code_ptr)

		if command == "+" then
			memory[mem_ptr] = memory[mem_ptr] + 1

			if memory[mem_ptr] == 256 then
				memory[mem_ptr] = 0
			end
		elseif command == "-" then
			memory[mem_ptr] = memory[mem_ptr] - 1

			if memory[mem_ptr] == -1 then
				memory[mem_ptr] = 255
			end
		elseif command == ">" then
			mem_ptr = mem_ptr + 1

			if mem_ptr > 30000 then
				mem_ptr = 1
			end

			if memory[mem_ptr] == nil then
				memory[mem_ptr] = 0
			end

			State.MemoryIndex = mem_ptr
		elseif command == "<" then
			mem_ptr = mem_ptr - 1

			if mem_ptr < 1 then
				mem_ptr = 30000
			end

			State.MemoryIndex = mem_ptr
		elseif command == "[" then
			if memory[mem_ptr] == 0 then
				local count = 0

				repeat
					code_ptr = code_ptr + 1
					local c = State.Code:sub(code_ptr, code_ptr)

					if c == "[" then
						count = count + 1
					elseif c == "]" then
						count = count - 1
					end
				until count == -1
			else
				State.ReturnStack:push(code_ptr - 1)
			end
		elseif command == "]" then
			if #State.ReturnStack > 0 then
				local popped = State.ReturnStack:pop()

				if memory[mem_ptr] ~= 0 then
					code_ptr = popped
				end
			else
				State.Error = "Return stack underflow (too many closing brackets?)"
				State.Status = "Error"
			end
		elseif command == "," then
			local input = State.Input

			if #input == 0 then
				State.Status = "Input"
				return
			end

			memory[mem_ptr] = table.remove(State.Input, 1)
		elseif command == "." then
			if State.OutputHandler then
				State.OutputHandler(memory[mem_ptr])
			else
				State.Buffer[#State.Buffer + 1] = memory[mem_ptr]
			end
		end

		State.CodeIndex = code_ptr + 1
		State.LastExecuted = command
		State.NextToExecute = State.Code:sub(State.CodeIndex, State.CodeIndex)

		if State.CodeIndex > #State.Code then
			State.Status = "Done"
		end
	end

	return {
		["IsReady"] = IsReady,
		["Input"] = Input,
		["ClearBuffer"] = ClearBuffer,
		["SetOutputHandler"] = SetOutputHandler,
		["SetCode"] = SetCode,
		["AddPeripheral"] = AddPeripheral,
		["Peek"] = Peek,
		["GetStatus"] = GetStatus,
		["GetBuffer"] = GetBuffer,
		["GetError"] = GetError,
		["GetCodeIndex"] = GetCodeIndex,
		["GetMemoryIndex"] = GetMemoryIndex,
		["GetLastExecuted"] = GetLastExecuted,
		["GetNextToExecute"] = GetNextToExecute,
		["Step"] = Step
	}
end

return {
	["CreateVM"] = CreateVM
}