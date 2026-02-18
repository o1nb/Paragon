--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
-- Doors Vape Modules
-- Place ID: 6839171747
-- Game ID: 2440500124

local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local lightingService = cloneref(game:GetService('Lighting'))
local tweenService = cloneref(game:GetService('TweenService'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape

local store = {
	currentFloor = 'Unknown',
	hookSupported = false
}

-- Detect Floor
run(function()
	local gameData = replicatedStorage:FindFirstChild('GameData')
	if gameData then
		local floorValue = gameData:FindFirstChild('Floor')
		if floorValue then
			store.currentFloor = floorValue.Value
		end
	end
end)

-- Check hook support
run(function()
	pcall(function()
		local mt = getrawmetatable(game)
		if mt and mt.__namecall and hookmetamethod then
			store.hookSupported = true
		end
	end)
end)
for _, v in {'AntiRagdoll', 'TriggerBot', 'SilentAim', 'AutoRejoin', 'Rejoin', 'Disabler', 'Timer', 'ServerHop', 'MouseTP', 'MurderMystery', 'Killaura', 'HitBoxes', 'Triggerbot', 'Reach', 'AutoClicker', 'AimAssist', 'GamingChair', 'Tracers', 'PlayerModel', 'AntiFall', 'LongJump', 'Phase', 'TargetStrafe', 'Swim', 'Blink', 'ChatSpammer'} do
	vape:Remove(v)
end
-- Fullbright
run(function()
	local Fullbright
	local originalLighting = {}
	local lightingConnection
	
	Fullbright = vape.Categories.Render:CreateModule({
		Name = 'Fullbright',
		Function = function(callback)
			if callback then
				originalLighting = {
					Brightness = lightingService.Brightness,
					ClockTime = lightingService.ClockTime,
					FogEnd = lightingService.FogEnd,
					GlobalShadows = lightingService.GlobalShadows,
					Ambient = lightingService.Ambient
				}
				
				lightingService.Brightness = 2
				lightingService.ClockTime = 14
				lightingService.FogEnd = 100000
				lightingService.GlobalShadows = false
				lightingService.Ambient = Color3.fromRGB(178, 178, 178)
				
				Fullbright:Clean(lightingService.Changed:Connect(function(property)
					if not Fullbright.Enabled then return end
					if property == 'Brightness' and lightingService.Brightness ~= 2 then
						lightingService.Brightness = 2
					end
					if property == 'ClockTime' and lightingService.ClockTime ~= 14 then
						lightingService.ClockTime = 14
					end
					if property == 'FogEnd' and lightingService.FogEnd ~= 100000 then
						lightingService.FogEnd = 100000
					end
					if property == 'GlobalShadows' and lightingService.GlobalShadows ~= false then
						lightingService.GlobalShadows = false
					end
					if property == 'Ambient' and lightingService.Ambient ~= Color3.fromRGB(178, 178, 178) then
						lightingService.Ambient = Color3.fromRGB(178, 178, 178)
					end
				end))
			else
				if lightingConnection then 
					lightingConnection:Disconnect() 
				end
				for property, value in pairs(originalLighting) do 
					lightingService[property] = value 
				end
			end
		end,
		Tooltip = 'See clearly in dark areas'
	})
end)

-- FOV Changer
run(function()
	local FOVChanger
	local FOVValue
	local desiredFOV = 70
	
	FOVChanger = vape.Categories.Render:CreateModule({
		Name = 'FOVChanger',
		Function = function(callback)
			if callback then
				FOVChanger:Clean(runService.RenderStepped:Connect(function()
					if gameCamera and gameCamera.FieldOfView ~= desiredFOV then
						gameCamera.FieldOfView = desiredFOV
					end
				end))
			else
				if gameCamera then
					gameCamera.FieldOfView = 70
				end
			end
		end,
		Tooltip = 'Adjust field of view'
	})
	
	FOVValue = FOVChanger:CreateSlider({
		Name = 'FOV',
		Min = 70,
		Max = 120,
		Default = 70,
		Function = function(val)
			desiredFOV = val
		end
	})
end)

-- No Acceleration
run(function()
	local NoAcceleration
	local originalHrpProps
	
	NoAcceleration = vape.Categories.Utility:CreateModule({
		Name = 'NoAcceleration',
		Function = function(callback)
			if callback then
				local char = lplr.Character or lplr.CharacterAdded:Wait()
				local hrp = char:WaitForChild('HumanoidRootPart')
				if hrp then
					originalHrpProps = hrp.CustomPhysicalProperties
					hrp.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
				end
				
				NoAcceleration:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if character then
						local h = character:FindFirstChild('HumanoidRootPart')
						if h then
							local cpp = h.CustomPhysicalProperties
							if not cpp or cpp.Density ~= 100 then
								h.CustomPhysicalProperties = PhysicalProperties.new(100, 0.7, 0, 1, 1)
							end
						end
					end
				end))
			else
				local char = lplr.Character
				if char then
					local h = char:FindFirstChild('HumanoidRootPart')
					if h then 
						h.CustomPhysicalProperties = originalHrpProps 
					end
				end
				originalHrpProps = nil
			end
		end,
		Tooltip = 'Removes movement acceleration'
	})
end)

-- Fixed Speed Module with Working Bypass for Doors
-- Replace the existing Speed module in your Vape file with this

run(function()
	local Speed
	local SpeedValue
	local AntiSpeedBypass
	local speedValue = 16
	local originalWalkSpeed = 16
	local bypassEnabled = false
	local clonedCollision
	local bypassLoop
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			if callback then
				if not bypassEnabled then
					Speed:Toggle()
					vape:CreateNotification('Speed', 'Enable AntiSpeed Bypass first!', 3)
					return
				end
				
				local char = lplr.Character
				if char then
					local hum = char:FindFirstChild('Humanoid')
					if hum then 
						originalWalkSpeed = hum.WalkSpeed 
					end
				end
				
				Speed:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if character then
						local humanoid = character:FindFirstChild('Humanoid')
						if humanoid then
							humanoid.WalkSpeed = speedValue
						end
					end
				end))
			else
				local char = lplr.Character
				if char then
					local hum = char:FindFirstChild('Humanoid')
					if hum then 
						hum.WalkSpeed = originalWalkSpeed 
					end
				end
			end
		end,
		Tooltip = 'Increase walk speed - requires bypass'
	})
	
	SpeedValue = Speed:CreateSlider({
		Name = 'Speed',
		Min = 2,
		Max = store.currentFloor == 'Mines' and 75 or 250,
		Default = 16,
		Function = function(val)
			speedValue = val
		end
	})
	
	AntiSpeedBypass = Speed:CreateToggle({
		Name = 'AntiSpeed Bypass',
		Function = function(callback)
			bypassEnabled = callback
			if callback then
				local char = lplr.Character or lplr.CharacterAdded:Wait()
				local collisionPart = char:WaitForChild('CollisionPart')
				
				clonedCollision = collisionPart:Clone()
				clonedCollision.Name = '_CollisionClone'
				clonedCollision.Massless = true
				clonedCollision.Parent = char
				clonedCollision.CanCollide = false
				clonedCollision.CanQuery = false
				clonedCollision.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.7, 0, 1, 1)
				
				bypassLoop = task.spawn(function()
					while bypassEnabled do
						task.wait(0.23)
						pcall(function()
							if clonedCollision and clonedCollision.Parent then
								clonedCollision.Massless = false
								task.wait(0.23)
								local root = char:FindFirstChild('HumanoidRootPart')
								if root and root.Anchored then
									clonedCollision.Massless = true
									task.wait(1)
								end
								clonedCollision.Massless = true
							end
						end)
					end
				end)
				
				-- Handle character respawn
				Speed:Clean(lplr.CharacterAdded:Connect(function(newChar)
					task.wait(0.5)
					if bypassEnabled then
						if clonedCollision then 
							pcall(function() clonedCollision:Destroy() end)
						end
						
						local newCollisionPart = newChar:WaitForChild('CollisionPart', 5)
						if newCollisionPart then
							clonedCollision = newCollisionPart:Clone()
							clonedCollision.Name = '_CollisionClone'
							clonedCollision.Massless = true
							clonedCollision.Parent = newChar
							clonedCollision.CanCollide = false
							clonedCollision.CanQuery = false
							clonedCollision.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.7, 0, 1, 1)
						end
					end
				end))
			else
				bypassEnabled = false
				if bypassLoop then 
					task.cancel(bypassLoop)
					bypassLoop = nil
				end
				if clonedCollision then 
					pcall(function()
						clonedCollision:Destroy()
					end)
					clonedCollision = nil 
				end
			end
		end,
		Default = true
	})
end)

-- Door Reach
run(function()
	local DoorReach
	local ReachDistance
	local reachDistance = 25
	
	DoorReach = vape.Categories.Utility:CreateModule({
		Name = 'DoorReach',
		Function = function(callback)
			if callback then
				DoorReach:Clean(runService.Heartbeat:Connect(function()
					local char = lplr.Character
					if not char then return end
					local hrp = char:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if not currentRooms then return end
					
					local rooms = currentRooms:GetChildren()
					table.sort(rooms, function(a, b)
						return (tonumber(a.Name) or 0) > (tonumber(b.Name) or 0)
					end)
					
					for i = 1, math.min(3, #rooms) do
						local targetRoom = rooms[i]
						if not targetRoom then continue end
						local door = targetRoom:FindFirstChild('Door')
						if not door then continue end
						local remote = door:FindFirstChild('ClientOpen')
						if not remote then continue end
						local doorPart = door:IsA('BasePart') and door or door:FindFirstChildWhichIsA('BasePart')
						if doorPart then
							local distance = (hrp.Position - doorPart.Position).Magnitude
							if distance <= reachDistance then 
								remote:FireServer() 
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'Open doors from further away'
	})
	
	ReachDistance = DoorReach:CreateSlider({
		Name = 'Distance',
		Min = 10,
		Max = 75,
		Default = 25,
		Function = function(val)
			reachDistance = val
		end
	})
end)

-- Auto GodMode (Rush/Ambush Detection)
run(function()
	local AutoGodMode
	local godModeEnabled = false
	local godModeSaved = {}
	local GOD_COLLISION_SIZE = Vector3.new(1.01, 0.5, 0.5)
	local GODMODE_ENTITY_RANGE = 250
	
	local function applyGodMode(character)
		pcall(function()
			local humanoid = character:WaitForChild('Humanoid', 5)
			if not humanoid then return end
			
			local collision = character:FindFirstChild('Collision', true)
			if not collision or not collision:IsA('BasePart') then return end
			
			local collisionCrouch = collision:FindFirstChild('CollisionCrouch', true)
			
			godModeSaved = { hipHeight = humanoid.HipHeight, parts = {} }
			
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					godModeSaved.parts[part] = {
						Size = part.Size,
						CanCollide = part.CanCollide,
					}
				end
			end
			
			humanoid.HipHeight = 0.05
			collision.Size = GOD_COLLISION_SIZE
			collision.CanCollide = true
			if collisionCrouch and collisionCrouch:IsA('BasePart') then
				collisionCrouch.Size = GOD_COLLISION_SIZE
				collisionCrouch.CanCollide = true
			end
			
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA('BasePart') and part ~= collision and part ~= collisionCrouch then
					part.CanCollide = false
				end
			end
		end)
	end
	
	local function restoreGodMode(character)
		pcall(function()
			if not godModeSaved.parts then return end
			
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid and godModeSaved.hipHeight then
				humanoid.HipHeight = godModeSaved.hipHeight
			end
			
			for part, saved in pairs(godModeSaved.parts) do
				if part and part.Parent then
					part.Size = saved.Size
					part.CanCollide = saved.CanCollide
				end
			end
			
			godModeSaved = {}
		end)
	end
	
	local function enableGodMode()
		local character = lplr.Character
		if not character or godModeEnabled then return end
		godModeEnabled = true
		applyGodMode(character)
	end
	
	local function disableGodMode()
		local character = lplr.Character
		if not character or not godModeEnabled then return end
		godModeEnabled = false
		restoreGodMode(character)
	end
	
	AutoGodMode = vape.Categories.Blatant:CreateModule({
		Name = 'AutoGodMode',
		Function = function(callback)
			if callback then
				lplr.CharacterAdded:Connect(function(character)
					if godModeEnabled then
						godModeEnabled = false
						task.wait(0.5)
						enableGodMode()
					end
				end)
				
				AutoGodMode:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if not character then return end
					local hrp = character:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local shouldEnable = false
					for _, name in ipairs({'RushMoving', 'AmbushMoving', 'BackdoorRush'}) do
						local model = workspace:FindFirstChild(name)
						if model then
							local part = model:FindFirstChildWhichIsA('BasePart')
							if part and (hrp.Position - part.Position).Magnitude <= GODMODE_ENTITY_RANGE then
								shouldEnable = true
								break
							end
						end
					end
					
					if shouldEnable and not godModeEnabled then
						enableGodMode()
					elseif not shouldEnable and godModeEnabled then
						disableGodMode()
					end
				end))
			else
				if godModeEnabled then 
					disableGodMode() 
				end
			end
		end,
		Tooltip = 'Auto-enables GodMode when Rush/Ambush is within 250 studs'
	})
end)

-- Object Bypass
run(function()
	local ObjectBypass
	local disabledObjects = {}
	
	local function processRoom(room)
		pcall(function()
			local assets = room:FindFirstChild('Assets')
			if not assets then return end
			
			for _, chandelier in pairs(assets:GetChildren()) do
				if chandelier.Name == 'ChandelierObstruction' then
					local collision = chandelier:FindFirstChild('Collision')
					if collision and collision.CanTouch then
						collision.CanTouch = false
						collision.CanQuery = false
						if not table.find(disabledObjects, collision) then
							table.insert(disabledObjects, collision)
						end
					end
				end
			end
			
			for _, object in pairs(assets:GetDescendants()) do
				if object:IsA('Model') and object:GetAttribute('LoadModule') == 'AnimatedObstacleKill' then
					for _, part in pairs(object:GetDescendants()) do
						if part:IsA('BasePart') and part.CanTouch then
							part.CanTouch = false
							part.CanQuery = false
							if not table.find(disabledObjects, part) then
								table.insert(disabledObjects, part)
							end
						end
					end
				end
			end
		end)
	end
	
	ObjectBypass = vape.Categories.Utility:CreateModule({
		Name = 'ObjectBypass',
		Function = function(callback)
			if callback then
				local currentRooms = workspace:FindFirstChild('CurrentRooms')
				if currentRooms then
					for _, room in pairs(currentRooms:GetChildren()) do 
						processRoom(room) 
					end
				end
				
				task.spawn(function()
					while ObjectBypass.Enabled do
						task.wait(0.5)
						if currentRooms then
							for _, room in pairs(currentRooms:GetChildren()) do 
								processRoom(room) 
							end
						end
					end
				end)
			else
				for _, part in pairs(disabledObjects) do
					pcall(function()
						if part and part.Parent then 
							part.CanTouch = true 
							part.CanQuery = true 
						end
					end)
				end
				table.clear(disabledObjects)
			end
		end,
		Tooltip = 'Disables chandeliers and animated obstacles'
	})
end)

-- Anti-Dupe
run(function()
	local AntiDupe
	local disabledDupeCollisions = {}
	
	local function processRoom(room)
		pcall(function()
			local sideroomSpace = room:FindFirstChild('SideroomSpace')
			if sideroomSpace then
				local collision = sideroomSpace:FindFirstChild('Collision')
				if collision and collision:IsA('BasePart') and collision.CanCollide then
					collision.CanCollide = false
					collision.CanQuery = false
					collision.CanTouch = false
					if not table.find(disabledDupeCollisions, collision) then
						table.insert(disabledDupeCollisions, collision)
					end
				end
			end
			
			local sideroomDupe = room:FindFirstChild('SideroomDupe')
			if sideroomDupe then
				local doorFake = sideroomDupe:FindFirstChild('DoorFake')
				if doorFake then
					local hidden = doorFake:FindFirstChild('Hidden')
					if hidden and hidden:IsA('BasePart') and hidden.CanCollide then
						hidden.CanCollide = false
						hidden.CanQuery = false
						hidden.CanTouch = false
						if not table.find(disabledDupeCollisions, hidden) then
							table.insert(disabledDupeCollisions, hidden)
						end
					end
				end
				
				for _, part in pairs(sideroomDupe:GetDescendants()) do
					if part:IsA('BasePart') and part.Name:lower():find('collision') then
						part:Destroy()
					end
				end
			end
		end)
	end
	
	AntiDupe = vape.Categories.Blatant:CreateModule({
		Name = 'AntiDupe',
		Function = function(callback)
			if callback then
				local currentRooms = workspace:FindFirstChild('CurrentRooms')
				if currentRooms then
					for _, room in pairs(currentRooms:GetChildren()) do 
						processRoom(room) 
					end
				end
				
				task.spawn(function()
					while AntiDupe.Enabled do
						task.wait(0.5)
						if currentRooms then
							for _, room in pairs(currentRooms:GetChildren()) do 
								processRoom(room) 
							end
						end
					end
				end)
			else
				for _, part in pairs(disabledDupeCollisions) do
					pcall(function()
						if part and part.Parent then
							part.CanCollide = true
							part.CanQuery = true
							part.CanTouch = true
						end
					end)
				end
				table.clear(disabledDupeCollisions)
			end
		end,
		Tooltip = 'Disables dupe room collisions'
	})
end)

-- Spoof Crouch
run(function()
	local SpoofCrouch
	
	SpoofCrouch = vape.Categories.Blatant:CreateModule({
		Name = 'SpoofCrouch',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while SpoofCrouch.Enabled do
						pcall(function()
							replicatedStorage.RemotesFolder.Crouch:FireServer(true, true)
						end)
						task.wait(0.32)
					end
				end)
			end
		end,
		Tooltip = 'Tricks the game into thinking you are always crouching'
	})
end)
-- ESP Modules for Doors (Add to existing file)
-- Place these in vape.Categories.Render

-- Door ESP
run(function()
	local DoorESP
	local espHighlights = {}
	
	local function hasESPHighlight(obj, espName)
		if not obj then return true end
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA('Highlight') and child.Name == espName .. 'ESP' then
				return true
			end
		end
		return false
	end
	
	local function clearESP()
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				item:Destroy() 
			end
		end
		table.clear(espHighlights)
	end
	
	local function addESPToObject(obj)
		if not obj or hasESPHighlight(obj, 'Door') then return end
		
		local highlight = Instance.new('Highlight')
		highlight.Name = 'DoorESP'
		highlight.FillColor = Color3.fromRGB(0, 255, 0)
		highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = obj
		table.insert(espHighlights, highlight)
	end
	
	local function createDoorESP()
		pcall(function()
			local currentRooms = workspace:FindFirstChild('CurrentRooms')
			if currentRooms then
				for _, room in pairs(currentRooms:GetChildren()) do
					local door = room:FindFirstChild('Door')
					if door and door:IsA('Model') then
						addESPToObject(door)
					end
				end
			end
		end)
	end
	
	local function cleanupDestroyedESP()
		local validHighlights = {}
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				table.insert(validHighlights, item) 
			end
		end
		espHighlights = validHighlights
	end
	
	DoorESP = vape.Categories.Render:CreateModule({
		Name = 'DoorESP',
		Function = function(callback)
			if callback then
				createDoorESP()
				
				task.spawn(function()
					while DoorESP.Enabled do
						task.wait(0.5)
						cleanupDestroyedESP()
						createDoorESP()
					end
				end)
			else
				clearESP()
			end
		end,
		Tooltip = 'Highlights doors'
	})
end)

-- Objective ESP
run(function()
	local ObjectiveESP
	local espHighlights = {}
	
	local function hasESPHighlight(obj, espName)
		if not obj then return true end
		for _, child in pairs(obj:GetChildren()) do
			if (child:IsA('Highlight') or child:IsA('BillboardGui')) and child.Name == espName .. 'ESP' then
				return true
			end
		end
		return false
	end
	
	local function clearESP()
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				item:Destroy() 
			end
		end
		table.clear(espHighlights)
	end
	
	local function addESPToObject(obj, color, outlineColor, labelText)
		if not obj or hasESPHighlight(obj, 'Objective') then return end
		
		local highlight = Instance.new('Highlight')
		highlight.Name = 'ObjectiveESP'
		highlight.FillColor = color
		highlight.OutlineColor = outlineColor
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = obj
		table.insert(espHighlights, highlight)
		
		if labelText then
			local billboard = Instance.new('BillboardGui')
			billboard.Name = 'ObjectiveESP'
			billboard.AlwaysOnTop = true
			billboard.Size = UDim2.new(0, 100, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.Parent = obj
			
			local textLabel = Instance.new('TextLabel')
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Text = labelText
			textLabel.TextColor3 = color
			textLabel.TextStrokeTransparency = 0
			textLabel.TextScaled = true
			textLabel.Font = Enum.Font.GothamBold
			textLabel.Parent = billboard
			table.insert(espHighlights, billboard)
		end
	end
	
	local function createObjectiveESP()
		pcall(function()
			local currentRooms = workspace:FindFirstChild('CurrentRooms')
			if currentRooms then
				for _, room in pairs(currentRooms:GetChildren()) do
					for _, obj in pairs(room:GetDescendants()) do
						local nameMap = {
							KeyObtain = 'Key',
							FuseObtain = 'Fuse',
							FuseHolder = 'Fuse',
							LiveHintBook = 'Book',
							LeverForGate = 'Lever',
							LiveBreakerPolePickup = 'Breaker',
							TimerLever = 'Timer',
							Padlock = 'Lock',
						}
						local label = nameMap[obj.Name]
						if label then
							addESPToObject(obj, Color3.fromRGB(255, 255, 0), Color3.fromRGB(200, 200, 0), label)
						end
					end
				end
			end
		end)
	end
	
	local function cleanupDestroyedESP()
		local validHighlights = {}
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				table.insert(validHighlights, item) 
			end
		end
		espHighlights = validHighlights
	end
	
	ObjectiveESP = vape.Categories.Render:CreateModule({
		Name = 'ObjectiveESP',
		Function = function(callback)
			if callback then
				createObjectiveESP()
				
				task.spawn(function()
					while ObjectiveESP.Enabled do
						task.wait(0.5)
						cleanupDestroyedESP()
						createObjectiveESP()
					end
				end)
			else
				clearESP()
			end
		end,
		Tooltip = 'Highlights objectives (Keys, Fuses, Books, Levers, etc.)'
	})
end)

-- Entity ESP
run(function()
	local EntityESP
	local espHighlights = {}
	
	local function hasESPHighlight(obj, espName)
		if not obj then return true end
		for _, child in pairs(obj:GetChildren()) do
			if (child:IsA('Highlight') or child:IsA('BillboardGui')) and child.Name == espName .. 'ESP' then
				return true
			end
		end
		return false
	end
	
	local function clearESP()
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				item:Destroy() 
			end
		end
		table.clear(espHighlights)
	end
	
	local function addESPToObject(obj, color, outlineColor, labelText)
		if not obj or hasESPHighlight(obj, 'Entity') then return end
		
		local highlight = Instance.new('Highlight')
		highlight.Name = 'EntityESP'
		highlight.FillColor = color
		highlight.OutlineColor = outlineColor
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = obj
		table.insert(espHighlights, highlight)
		
		if labelText then
			local billboard = Instance.new('BillboardGui')
			billboard.Name = 'EntityESP'
			billboard.AlwaysOnTop = true
			billboard.Size = UDim2.new(0, 100, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.Parent = obj
			
			local textLabel = Instance.new('TextLabel')
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Text = labelText
			textLabel.TextColor3 = color
			textLabel.TextStrokeTransparency = 0
			textLabel.TextScaled = true
			textLabel.Font = Enum.Font.GothamBold
			textLabel.Parent = billboard
			table.insert(espHighlights, billboard)
		end
	end
	
	local function createEntityESP()
		pcall(function()
			local entityMap = {
				RushMoving = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(200, 0, 0), 'RUSH' },
				AmbushMoving = { Color3.fromRGB(255, 100, 0), Color3.fromRGB(200, 80, 0), 'AMBUSH' },
				Eyes = { Color3.fromRGB(150, 0, 255), Color3.fromRGB(120, 0, 200), 'EYES' },
				Halt = { Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 150, 200), 'HALT' },
				Screech = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), 'SCREECH' },
				A60 = { Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 30, 30), 'A60' },
				A120 = { Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 30, 30), 'A120' },
			}
			
			for _, child in pairs(workspace:GetChildren()) do
				local info = entityMap[child.Name]
				if info and child:IsA('Model') then
					addESPToObject(child, info[1], info[2], info[3])
				end
			end
			
			local currentRooms = workspace:FindFirstChild('CurrentRooms')
			if currentRooms then
				for _, room in pairs(currentRooms:GetChildren()) do
					-- Figure ESP
					local figureSetup = room:FindFirstChild('FigureSetup')
					if figureSetup then
						local figureRig = figureSetup:FindFirstChild('FigureRig')
						if figureRig then
							addESPToObject(figureRig, Color3.fromRGB(255, 0, 0), Color3.fromRGB(200, 0, 0), 'FIGURE')
						end
					end
					
					-- Seek ESP
					local seekSetup = room:FindFirstChild('SeekSetup') or room:FindFirstChild('Seek')
					if seekSetup then
						local seekModel = seekSetup:FindFirstChild('SeekRig') or seekSetup:FindFirstChild('Seek') or seekSetup
						if seekModel and seekModel:IsA('Model') then
							addESPToObject(seekModel, Color3.fromRGB(0, 0, 0), Color3.fromRGB(100, 100, 100), 'SEEK')
						end
					end
					
					-- Snare ESP
					local assets = room:FindFirstChild('Assets')
					if assets then
						for _, obj in pairs(assets:GetChildren()) do
							if obj.Name == 'Snare' then
								addESPToObject(obj, Color3.fromRGB(255, 100, 100), Color3.fromRGB(200, 80, 80), 'SNARE')
							end
						end
					end
				end
			end
		end)
	end
	
	local function cleanupDestroyedESP()
		local validHighlights = {}
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				table.insert(validHighlights, item) 
			end
		end
		espHighlights = validHighlights
	end
	
	EntityESP = vape.Categories.Render:CreateModule({
		Name = 'EntityESP',
		Function = function(callback)
			if callback then
				createEntityESP()
				
				task.spawn(function()
					while EntityESP.Enabled do
						task.wait(0.5)
						cleanupDestroyedESP()
						createEntityESP()
					end
				end)
			else
				clearESP()
			end
		end,
		Tooltip = 'Highlights entities (Rush, Ambush, Eyes, Figure, Seek, etc.)'
	})
end)

-- Chest ESP
run(function()
	local ChestESP
	local espHighlights = {}
	
	local function hasESPHighlight(obj, espName)
		if not obj then return true end
		for _, child in pairs(obj:GetChildren()) do
			if (child:IsA('Highlight') or child:IsA('BillboardGui')) and child.Name == espName .. 'ESP' then
				return true
			end
		end
		return false
	end
	
	local function clearESP()
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				item:Destroy() 
			end
		end
		table.clear(espHighlights)
	end
	
	local function createChestESP(chest)
		if hasESPHighlight(chest, 'Chest') then return end
		
		local highlight = Instance.new('Highlight')
		highlight.Name = 'ChestESP'
		highlight.FillColor = Color3.fromRGB(255, 215, 0)
		highlight.OutlineColor = Color3.fromRGB(200, 170, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Parent = chest
		table.insert(espHighlights, highlight)
		
		local billboard = Instance.new('BillboardGui')
		billboard.Name = 'ChestESP'
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.new(0, 100, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.Parent = chest
		
		local textLabel = Instance.new('TextLabel')
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = 'Chest'
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		textLabel.TextStrokeTransparency = 0
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.Parent = billboard
		
		table.insert(espHighlights, billboard)
	end
	
	local function findChests()
		pcall(function()
			for _, chest in pairs(workspace:GetDescendants()) do
				if chest.Name:lower():find('chest') and chest:IsA('Model') then
					createChestESP(chest)
				end
			end
		end)
	end
	
	local function cleanupDestroyedESP()
		local validHighlights = {}
		for _, item in pairs(espHighlights) do
			if item and item.Parent then 
				table.insert(validHighlights, item) 
			end
		end
		espHighlights = validHighlights
	end
	
	ChestESP = vape.Categories.Render:CreateModule({
		Name = 'ChestESP',
		Function = function(callback)
			if callback then
				findChests()
				
				task.spawn(function()
					while ChestESP.Enabled do
						task.wait(1)
						cleanupDestroyedESP()
						findChests()
					end
				end)
			else
				clearESP()
			end
		end,
		Tooltip = 'Highlights chests'
	})
end)
-- Anti Eyes
run(function()
	local AntiEyes
	
	AntiEyes = vape.Categories.Blatant:CreateModule({
		Name = 'AntiEyes',
		Function = function(callback)
			if callback then
				AntiEyes:Clean(runService.Heartbeat:Connect(function()
					pcall(function()
						for _, v in pairs(workspace:GetChildren()) do
							if v.Name == 'Eyes' and v:FindFirstChild('Core') then
								local core = v.Core
								if core:FindFirstChild('Ambience') and core.Ambience.Playing then
									replicatedStorage.RemotesFolder.MotorReplication:FireServer(-650)
									break
								end
							end
						end
					end)
				end))
			end
		end,
		Tooltip = 'Automatically looks away from Eyes'
	})
end)

-- Disable Screech
run(function()
	local DisableScreech
	local screechOriginalParent
	
	DisableScreech = vape.Categories.Blatant:CreateModule({
		Name = 'DisableScreech',
		Function = function(callback)
			pcall(function()
				local screech = replicatedStorage.Entities:FindFirstChild('Screech')
				if callback and screech then
					local zeScriptStuff = replicatedStorage:FindFirstChild('ZeScript_Stuff')
					if not zeScriptStuff then
						zeScriptStuff = Instance.new('Folder')
						zeScriptStuff.Name = 'ZeScript_Stuff'
						zeScriptStuff.Parent = replicatedStorage
					end
					local disabledEntity = zeScriptStuff:FindFirstChild('DisabledEntity')
					if not disabledEntity then
						disabledEntity = Instance.new('Folder')
						disabledEntity.Name = 'DisabledEntity'
						disabledEntity.Parent = zeScriptStuff
					end
					screechOriginalParent = screech.Parent
					screech.Parent = disabledEntity
				elseif not callback and screech and screechOriginalParent then
					screech.Parent = screechOriginalParent
				end
			end)
		end,
		Tooltip = 'Prevents Screech from spawning'
	})
end)

-- Disable Snare
run(function()
	local DisableSnare
	local snareHitboxes = {}
	
	DisableSnare = vape.Categories.Blatant:CreateModule({
		Name = 'DisableSnare',
		Function = function(callback)
			if callback then
				local currentRooms = workspace:FindFirstChild('CurrentRooms')
				if currentRooms then
					for _, room in pairs(currentRooms:GetChildren()) do
						pcall(function()
							local assets = room:FindFirstChild('Assets')
							if assets then
								for _, snare in pairs(assets:GetChildren()) do
									if snare.Name == 'Snare' then
										local hitbox = snare:FindFirstChild('Hitbox')
										if hitbox then
											hitbox.CanTouch = false
											table.insert(snareHitboxes, hitbox)
										end
									end
								end
							end
						end)
					end
				end
				
				task.spawn(function()
					while DisableSnare.Enabled do
						task.wait(0.5)
						if currentRooms then
							for _, room in pairs(currentRooms:GetChildren()) do
								pcall(function()
									local assets = room:FindFirstChild('Assets')
									if assets then
										for _, snare in pairs(assets:GetChildren()) do
											if snare.Name == 'Snare' then
												local hitbox = snare:FindFirstChild('Hitbox')
												if hitbox and hitbox.CanTouch then
													hitbox.CanTouch = false
													if not table.find(snareHitboxes, hitbox) then
														table.insert(snareHitboxes, hitbox)
													end
												end
											end
										end
									end
								end)
							end
						end
					end
				end)
			else
				for _, hitbox in pairs(snareHitboxes) do
					pcall(function()
						if hitbox and hitbox.Parent then 
							hitbox.CanTouch = true 
						end
					end)
				end
				table.clear(snareHitboxes)
			end
		end,
		Tooltip = 'Disables Snare traps'
	})
end)

-- Auto Proximity Interact
run(function()
	local AutoProxi
	local InstantInteract
	local isAutoProxiKeyHeld = false
	local autoProxiCooldowns = {}
	local autoProxiKey = Enum.KeyCode.R
	
	inputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == autoProxiKey and not gameProcessed then
			isAutoProxiKeyHeld = true
		end
	end)
	
	inputService.InputEnded:Connect(function(input)
		if input.KeyCode == autoProxiKey then
			isAutoProxiKeyHeld = false
		end
	end)
	
	local function shouldInteract(prompt)
		if not prompt or not prompt.Enabled then return false end
		local actionText = (prompt.ActionText or ''):lower()
		if actionText:find('close') then return false end
		if actionText:find('leave') then return false end
		if actionText:find('exit') and not actionText:find('door') then return false end
		if actionText:find('hide') then return false end
		return true
	end
	
	local function getAllProximityPrompts()
		local prompts = {}
		pcall(function()
			local currentRooms = workspace:FindFirstChild('CurrentRooms')
			if currentRooms then
				for _, prompt in pairs(currentRooms:GetDescendants()) do
					if prompt:IsA('ProximityPrompt') then 
						table.insert(prompts, prompt) 
					end
				end
			end
			local playerGui = lplr:FindFirstChild('PlayerGui')
			if playerGui then
				for _, prompt in pairs(playerGui:GetDescendants()) do
					if prompt:IsA('ProximityPrompt') then 
						table.insert(prompts, prompt) 
					end
				end
			end
		end)
		return prompts
	end
	
	local function runAutoProxi()
		pcall(function()
			local prompts = getAllProximityPrompts()
			for _, prompt in pairs(prompts) do
				if shouldInteract(prompt) then
					local promptId = tostring(prompt:GetFullName())
					local now = tick()
					if autoProxiCooldowns[promptId] and (now - autoProxiCooldowns[promptId]) < 0.1 then 
						continue 
					end
					autoProxiCooldowns[promptId] = now
					
					task.spawn(function()
						pcall(function()
							if InstantInteract.Enabled and prompt.HoldDuration > 0 then
								local originalHold = prompt.HoldDuration
								prompt.HoldDuration = 0
								fireproximityprompt(prompt)
								task.delay(0.05, function()
									if prompt and prompt.Parent then 
										prompt.HoldDuration = originalHold 
									end
								end)
							else
								fireproximityprompt(prompt)
							end
						end)
					end)
				end
			end
			
			for id, time in pairs(autoProxiCooldowns) do
				if tick() - time > 5 then 
					autoProxiCooldowns[id] = nil 
				end
			end
		end)
	end
	
	AutoProxi = vape.Categories.Utility:CreateModule({
		Name = 'AutoProxi',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while AutoProxi.Enabled do
						if isAutoProxiKeyHeld then 
							runAutoProxi() 
						end
						task.wait(0.05)
					end
				end)
			else
				table.clear(autoProxiCooldowns)
			end
		end,
		Tooltip = 'Hold R to auto-interact with proximity prompts'
	})
	
	InstantInteract = AutoProxi:CreateToggle({
		Name = 'Instant',
		Default = true
	})
end)

-- Entity Notifier
run(function()
	local EntityNotifier
	local notifiedEntities = {}
	
	EntityNotifier = vape.Categories.Render:CreateModule({
		Name = 'EntityNotifier',
		Function = function(callback)
			if callback then
				task.spawn(function()
					local entityNotifyList = {
						{ name = 'RushMoving', text = 'Rush is coming!' },
						{ name = 'AmbushMoving', text = 'Ambush is coming!' },
						{ name = 'Eyes', text = 'Eyes has appeared!' },
						{ name = 'Halt', text = 'Halt has appeared!' },
					}
					
					while EntityNotifier.Enabled do
						task.wait(0.5)
						pcall(function()
							for _, e in ipairs(entityNotifyList) do
								local model = workspace:FindFirstChild(e.name)
								if model and not notifiedEntities[e.name] then
									notifiedEntities[e.name] = true
									vape:CreateNotification('Entity', e.text, 5)
								elseif not model and notifiedEntities[e.name] then
									notifiedEntities[e.name] = nil
								end
							end
						end)
					end
				end)
			else
				table.clear(notifiedEntities)
			end
		end,
		Tooltip = 'Get notifications when entities spawn'
	})
end)

-- Mines Anticheat Bypass
if store.currentFloor == 'Mines' or store.currentFloor == 'Unknown' then
	run(function()
		local MinesBypass
		local ladderESP = {}
		
		MinesBypass = vape.Categories.Minigames:CreateModule({
			Name = 'MinesBypass',
			Function = function(callback)
				if callback then
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if currentRooms then
						for _, room in pairs(currentRooms:GetChildren()) do
							pcall(function()
								local ladder = room:FindFirstChild('Ladder', true)
								if ladder then
									local highlight = Instance.new('Highlight')
									highlight.FillColor = Color3.fromRGB(0, 100, 255)
									highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
									highlight.FillTransparency = 0.5
									highlight.OutlineTransparency = 0
									highlight.Parent = ladder
									table.insert(ladderESP, highlight)
								end
							end)
						end
					end
					
					task.spawn(function()
						while MinesBypass.Enabled do
							task.wait(0.1)
							pcall(function()
								local character = lplr.Character
								if character then
									local climbingAttr = character:GetAttribute('Climbing')
									if climbingAttr == true then
										task.wait(0.5)
										character:SetAttribute('Climbing', false)
									end
								end
							end)
						end
					end)
				else
					for _, highlight in pairs(ladderESP) do
						pcall(function()
							if highlight and highlight.Parent then 
								highlight:Destroy() 
							end
						end)
					end
					table.clear(ladderESP)
				end
			end,
			Tooltip = 'Prevents ladder detection in Mines'
		})
	end)
end

-- Figure GodMode
run(function()
	local FigureGodMode
	local isFigureGodModeActive = false
	local fakeCameraConnection
	
	local function getFigurePosition(figureRig)
		if not figureRig then return nil end
		local ok, pivot = pcall(function() return figureRig:GetPivot() end)
		if ok and pivot then return pivot.Position end
		local part = figureRig:FindFirstChildWhichIsA('BasePart', true)
		return part and part.Position or nil
	end
	
	local function enableFakeCamera(character)
		if fakeCameraConnection then return end
		local head = character:FindFirstChild('Head')
		if not head then return end
		gameCamera.CameraType = Enum.CameraType.Scriptable
		fakeCameraConnection = runService.RenderStepped:Connect(function()
			if not head or not head.Parent then return end
			gameCamera.CFrame = head.CFrame * CFrame.new(0, -10, 0)
		end)
	end
	
	local function disableFakeCamera()
		if fakeCameraConnection then
			fakeCameraConnection:Disconnect()
			fakeCameraConnection = nil
		end
		gameCamera.CameraType = Enum.CameraType.Custom
	end
	
	local function enableFigureGodMode(character)
		pcall(function()
			if isFigureGodModeActive then return end
			local humanoid = character:FindFirstChild('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not (humanoid and hrp) then return end
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 13, 0)
			humanoid.HipHeight = 13
			enableFakeCamera(character)
			isFigureGodModeActive = true
		end)
	end
	
	local function disableFigureGodMode(character)
		pcall(function()
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then humanoid.HipHeight = 2 end
			disableFakeCamera()
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 13, 0) end
			isFigureGodModeActive = false
		end)
	end
	
	FigureGodMode = vape.Categories.Blatant:CreateModule({
		Name = 'FigureGodMode',
		Function = function(callback)
			if callback then
				lplr.CharacterAdded:Connect(function()
					isFigureGodModeActive = false
					disableFakeCamera()
				end)
				
				FigureGodMode:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if not character then return end
					local hrp = character:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local figureNearby = false
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if currentRooms then
						for _, room in pairs(currentRooms:GetChildren()) do
							local setup = room:FindFirstChild('FigureSetup')
							if setup then
								local rig = setup:FindFirstChild('FigureRig')
								if rig then
									local pos = getFigurePosition(rig)
									if pos and (hrp.Position - pos).Magnitude <= 30 then
										figureNearby = true
										break
									end
								end
							end
						end
					end
					
					if figureNearby and not isFigureGodModeActive then
						enableFigureGodMode(character)
					elseif not figureNearby and isFigureGodModeActive then
						disableFigureGodMode(character)
					end
				end))
			else
				if isFigureGodModeActive then
					local character = lplr.Character
					if character then disableFigureGodMode(character) end
				end
			end
		end,
		Tooltip = 'Auto-enables godmode when Figure is nearby'
	})
end)

-- Anti-Groundskeeper
run(function()
	local AntiGroundskeeper
	local isAntiGKActive = false
	local fakeGKCameraConn
	
	local function getModelPosition(model)
		if not model then return nil end
		local ok, pivot = pcall(function() return model:GetPivot() end)
		if ok and pivot then return pivot.Position end
		local part = model:FindFirstChildWhichIsA('BasePart', true)
		return part and part.Position or nil
	end
	
	local function enableFakeGKCamera(character)
		if fakeGKCameraConn then return end
		local head = character:FindFirstChild('Head')
		if not head then return end
		gameCamera.CameraType = Enum.CameraType.Scriptable
		fakeGKCameraConn = runService.RenderStepped:Connect(function()
			if not head or not head.Parent then return end
			gameCamera.CFrame = head.CFrame * CFrame.new(0, -2, 0)
		end)
	end
	
	local function disableFakeGKCamera()
		if fakeGKCameraConn then
			fakeGKCameraConn:Disconnect()
			fakeGKCameraConn = nil
		end
		gameCamera.CameraType = Enum.CameraType.Custom
	end
	
	local function enableAntiGroundskeeper(character)
		pcall(function()
			if isAntiGKActive then return end
			local humanoid = character:FindFirstChild('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not (humanoid and hrp) then return end
			hrp.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
			humanoid.HipHeight = 5
			enableFakeGKCamera(character)
			isAntiGKActive = true
		end)
	end
	
	local function disableAntiGroundskeeper(character)
		pcall(function()
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then humanoid.HipHeight = 2 end
			disableFakeGKCamera()
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 2, 0) end
			isAntiGKActive = false
		end)
	end
	
	AntiGroundskeeper = vape.Categories.Blatant:CreateModule({
		Name = 'AntiGroundskeeper',
		Function = function(callback)
			if callback then
				lplr.CharacterAdded:Connect(function()
					isAntiGKActive = false
					disableFakeGKCamera()
				end)
				
				AntiGroundskeeper:Clean(runService.Heartbeat:Connect(function()
					local character = lplr.Character
					if not character then return end
					local hrp = character:FindFirstChild('HumanoidRootPart')
					if not hrp then return end
					
					local gkFound = false
					local currentRooms = workspace:FindFirstChild('CurrentRooms')
					if currentRooms then
						for _, room in pairs(currentRooms:GetChildren()) do
							local gk = room:FindFirstChild('Groundskeeper')
							if gk and gk:IsA('Model') then
								local gkPos = getModelPosition(gk)
								if gkPos and (hrp.Position - gkPos).Magnitude <= 300 then
									gkFound = true
									break
								end
							end
						end
					end
					
					if gkFound and not isAntiGKActive then
						enableAntiGroundskeeper(character)
					elseif not gkFound and isAntiGKActive then
						disableAntiGroundskeeper(character)
					end
				end))
			else
				if isAntiGKActive then
					local character = lplr.Character
					if character then disableAntiGroundskeeper(character) end
				end
			end
		end,
		Tooltip = 'Auto-enables protection when Groundskeeper is nearby'
	})
end)

-- Anticheat Manipulation
run(function()
	local AnticheatManip
	local isAnticheatKeyHeld = false
	local anticheatManipKey = Enum.KeyCode.T
	
	inputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == anticheatManipKey and not gameProcessed then
			isAnticheatKeyHeld = true
		end
	end)
	
	inputService.InputEnded:Connect(function(input)
		if input.KeyCode == anticheatManipKey then
			isAnticheatKeyHeld = false
		end
	end)
	
	AnticheatManip = vape.Categories.Blatant:CreateModule({
		Name = 'AnticheatManip',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while AnticheatManip.Enabled do
						task.wait(0.00001)
						pcall(function()
							if isAnticheatKeyHeld and lplr.Character then
								lplr.Character:PivotTo(lplr.Character:GetPivot() + gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1) * -100)
							end
						end)
					end
				end)
			end
		end,
		Tooltip = 'Hold T to use anticheat to teleport forward'
	})
end)

-- Hook-based modules
if store.hookSupported then
	run(function()
		local AntiHeartbeat
		local AntiA90
		local hooksInitialized = false
		
		local function initHooks()
			if hooksInitialized then return end
			pcall(function()
				local HideMonster = replicatedStorage:WaitForChild('RemotesFolder'):WaitForChild('HideMonster')
				local A90Remote = replicatedStorage:WaitForChild('RemotesFolder'):WaitForChild('A90')
				
				local oldNamecall
				oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
					local method = getnamecallmethod()
					if method == 'FireServer' then
						if AntiHeartbeat.Enabled and self == HideMonster then
							return
						end
						if AntiA90.Enabled and self == A90Remote then
							local args = {...}
							if args[1] == 'moved' then
								return oldNamecall(self, 'didnt')
							end
						end
					end
					return oldNamecall(self, ...)
				end)
				hooksInitialized = true
			end)
		end
		
		AntiHeartbeat = vape.Categories.Blatant:CreateModule({
			Name = 'AntiHeartbeat',
			Function = function(callback)
				if callback then initHooks() end
			end,
			Tooltip = 'Blocks Figure heartbeat minigame'
		})
		
		AntiA90 = vape.Categories.Blatant:CreateModule({
			Name = 'AntiA90',
			Function = function(callback)
				if callback then initHooks() end
			end,
			Tooltip = 'Replaces A-90 death signal'
		})
	end)
end
-- Phase Module with Multiple Modes for Doors
-- Works with Speed to phase through doors and gates

run(function()
	local Phase
	local PhaseMode
	local VelocityBoost
	local AutoPhase
	local phaseMode = 'Normal'
	local velocityBoost = 50
	local autoPhaseEnabled = false
	local originalCollisions = {}
	local phaseActive = false
	
	local function saveOriginalCollisions(character)
		originalCollisions = {}
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA('BasePart') then
				originalCollisions[part] = part.CanCollide
			end
		end
	end
	
	local function restoreCollisions(character)
		for part, canCollide in pairs(originalCollisions) do
			if part and part.Parent then
				part.CanCollide = canCollide
			end
		end
		table.clear(originalCollisions)
	end
	
	local function enableNormalPhase(character)
		pcall(function()
			saveOriginalCollisions(character)
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					part.CanCollide = false
				end
			end
			phaseActive = true
		end)
	end
	
	local function enableVelocityPhase(character)
		pcall(function()
			enableNormalPhase(character)
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if hrp then
				local humanoid = character:FindFirstChild('Humanoid')
				if humanoid and humanoid.MoveDirection.Magnitude > 0 then
					hrp.Velocity = hrp.Velocity + (humanoid.MoveDirection * velocityBoost)
				end
			end
		end)
	end
	
	local function enableSmartPhase(character)
		pcall(function()
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not hrp then return end
			
			-- Check if there's an obstacle in front
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid and humanoid.MoveDirection.Magnitude > 0 then
				local direction = humanoid.MoveDirection * 5
				local result = workspace:Raycast(hrp.Position, direction, rayParams)
				
				if result and result.Instance then
					-- Check if it's a door, gate, or obstacle
					local hitName = result.Instance.Name:lower()
					if hitName:find('door') or hitName:find('gate') or hitName:find('wall') or 
					   hitName:find('collision') or result.Instance.Parent.Name:lower():find('door') then
						if not phaseActive then
							enableNormalPhase(character)
						end
						return
					end
				end
			end
			
			-- No obstacle, restore collisions
			if phaseActive then
				restoreCollisions(character)
				phaseActive = false
			end
		end)
	end
	
	local function enablePartialPhase(character)
		pcall(function()
			saveOriginalCollisions(character)
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
					-- Keep HumanoidRootPart collision to not fall through floor
					part.CanCollide = false
				end
			end
			phaseActive = true
		end)
	end
	
	local function applyPhaseMode(character)
		if phaseMode == 'Normal' then
			enableNormalPhase(character)
		elseif phaseMode == 'Velocity' then
			enableVelocityPhase(character)
		elseif phaseMode == 'Smart' then
			enableSmartPhase(character)
		elseif phaseMode == 'Partial' then
			enablePartialPhase(character)
		end
	end
	
	Phase = vape.Categories.Combat:CreateModule({
		Name = 'Phase',
		Function = function(callback)
			if callback then
				local character = lplr.Character
				if character then
					applyPhaseMode(character)
				end
				
				-- Continuous phase update
				Phase:Clean(runService.Heartbeat:Connect(function()
					local char = lplr.Character
					if char then
						if phaseMode == 'Velocity' then
							-- Reapply velocity phase each frame if moving
							local humanoid = char:FindFirstChild('Humanoid')
							if humanoid and humanoid.MoveDirection.Magnitude > 0 then
								enableVelocityPhase(char)
							end
						elseif phaseMode == 'Smart' then
							-- Smart mode checks every frame
							enableSmartPhase(char)
						elseif phaseMode == 'Normal' or phaseMode == 'Partial' then
							-- Ensure phase stays active
							if not phaseActive then
								applyPhaseMode(char)
							end
						end
					end
				end))
				
				-- Handle character respawn
				Phase:Clean(lplr.CharacterAdded:Connect(function(newChar)
					task.wait(0.5)
					if Phase.Enabled then
						phaseActive = false
						applyPhaseMode(newChar)
					end
				end))
			else
				local character = lplr.Character
				if character then
					restoreCollisions(character)
				end
				phaseActive = false
			end
		end,
		Tooltip = 'Walk through doors, gates, and walls'
	})
	
	PhaseMode = Phase:CreateDropdown({
		Name = 'Mode',
		List = {'Normal', 'Velocity', 'Smart', 'Partial'},
		Default = 'Normal',
		Function = function(val)
			phaseMode = val
			if Phase.Enabled then
				local character = lplr.Character
				if character then
					restoreCollisions(character)
					phaseActive = false
					applyPhaseMode(character)
				end
			end
		end,
		Tooltip = 'Normal: Always phase | Velocity: Phase with speed boost | Smart: Auto phase near obstacles | Partial: Phase upper body only'
	})
	
	VelocityBoost = Phase:CreateSlider({
		Name = 'Velocity Boost',
		Min = 0,
		Max = 200,
		Default = 50,
		Function = function(val)
			velocityBoost = val
		end,
		Tooltip = 'Velocity boost amount (Velocity mode only)'
	})
end)

-- Phase Clip (Alternative phase using CFrame)
run(function()
	local PhaseClip
	local ClipDistance
	local ClipKey
	local clipDistance = 10
	local isClipKeyHeld = false
	local clipKey = Enum.KeyCode.C
	
	inputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == clipKey and not gameProcessed then
			isClipKeyHeld = true
		end
	end)
	
	inputService.InputEnded:Connect(function(input)
		if input.KeyCode == clipKey then
			isClipKeyHeld = false
		end
	end)
	
	PhaseClip = vape.Categories.Combat:CreateModule({
		Name = 'PhaseClip',
		Function = function(callback)
			if callback then
				PhaseClip:Clean(runService.Heartbeat:Connect(function()
					if isClipKeyHeld then
						pcall(function()
							local character = lplr.Character
							if character then
								local hrp = character:FindFirstChild('HumanoidRootPart')
								local humanoid = character:FindFirstChild('Humanoid')
								if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
									-- Clip forward through obstacles
									local clipVector = humanoid.MoveDirection * clipDistance
									hrp.CFrame = hrp.CFrame + clipVector
								end
							end
						end)
					end
				end))
			end
		end,
		Tooltip = 'Hold C to clip through obstacles'
	})
	
	ClipDistance = PhaseClip:CreateSlider({
		Name = 'Clip Distance',
		Min = 5,
		Max = 50,
		Default = 10,
		Function = function(val)
			clipDistance = val
		end,
		Tooltip = 'How far to clip each tick'
	})
	
	ClipKey = PhaseClip:CreateDropdown({
		Name = 'Clip Key',
		List = {'C', 'V', 'X', 'Z'},
		Default = 'C',
		Function = function(val)
			clipKey = Enum.KeyCode[val]
		end
	})
end)

-- Door Clip (Specific for doors)
run(function()
	local DoorClip
	local AutoClipDoors
	local ClipRange
	local autoClipDoors = true
	local clipRange = 15
	
	local function clipThroughDoor(door)
		pcall(function()
			local character = lplr.Character
			if not character then return end
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not hrp then return end
			
			-- Find door position
			local doorPart = door:IsA('BasePart') and door or door:FindFirstChildWhichIsA('BasePart')
			if doorPart then
				local doorPos = doorPart.Position
				local charPos = hrp.Position
				
				-- Teleport to other side of door
				local direction = (doorPos - charPos).Unit
				local targetPos = doorPos + (direction * 10)
				hrp.CFrame = CFrame.new(targetPos)
			end
		end)
	end
	
	DoorClip = vape.Categories.Combat:CreateModule({
		Name = 'DoorClip',
		Function = function(callback)
			if callback then
				DoorClip:Clean(runService.Heartbeat:Connect(function()
					if not autoClipDoors then return end
					
					pcall(function()
						local character = lplr.Character
						if not character then return end
						local hrp = character:FindFirstChild('HumanoidRootPart')
						if not hrp then return end
						
						local currentRooms = workspace:FindFirstChild('CurrentRooms')
						if not currentRooms then return end
						
						-- Find nearby locked doors
						for _, room in pairs(currentRooms:GetChildren()) do
							local door = room:FindFirstChild('Door')
							if door then
								local doorPart = door:IsA('BasePart') and door or door:FindFirstChildWhichIsA('BasePart')
								if doorPart then
									local distance = (hrp.Position - doorPart.Position).Magnitude
									if distance <= clipRange then
										-- Check if door is locked (no ClientOpen or door is locked)
										local clientOpen = door:FindFirstChild('ClientOpen')
										local lockPart = door:FindFirstChild('Lock')
										if not clientOpen or lockPart then
											clipThroughDoor(door)
										end
									end
								end
							end
						end
					end)
				end))
			end
		end,
		Tooltip = 'Automatically clips through locked doors'
	})
	
	AutoClipDoors = DoorClip:CreateToggle({
		Name = 'Auto Clip',
		Default = true,
		Function = function(val)
			autoClipDoors = val
		end
	})
	
	ClipRange = DoorClip:CreateSlider({
		Name = 'Range',
		Min = 5,
		Max = 30,
		Default = 15,
		Function = function(val)
			clipRange = val
		end,
		Tooltip = 'How close you need to be to auto-clip'
	})
end)
run(function()
	local AutoInteract
	local autoInteractConnection
	local pickupRange = 20
	
	local function isInRange(obj)
		if not entitylib.isAlive then return false end
		if not obj or not obj:IsA('BasePart') and not obj:IsA('Model') then return false end
		
		local objPos
		if obj:IsA('Model') then
			objPos = obj:GetPivot().Position
		else
			objPos = obj.Position
		end
		
		local charPos = entitylib.character.RootPart.Position
		return (charPos - objPos).Magnitude <= pickupRange
	end
	
	local function interactWithObject(obj)
		-- Find ProximityPrompt in object or its descendants
		local prompt = obj:FindFirstChildOfClass('ProximityPrompt')
		if not prompt then
			for _, child in obj:GetDescendants() do
				if child:IsA('ProximityPrompt') then
					prompt = child
					break
				end
			end
		end
		
		if prompt and prompt.Enabled and isInRange(obj) then
			if prompt.HoldDuration > 0 then
				local originalHold = prompt.HoldDuration
				prompt.HoldDuration = 0
				fireproximityprompt(prompt)
				task.delay(0.05, function()
					if prompt and prompt.Parent then
						prompt.HoldDuration = originalHold
					end
				end)
			else
				fireproximityprompt(prompt)
			end
			return true
		end
		return false
	end
	
	local function autoInteract()
		if not entitylib.isAlive then return end
		
		local currentRooms = workspace:FindFirstChild('CurrentRooms')
		if not currentRooms then return end
		
		-- Auto open locked doors
		for _, room in currentRooms:GetChildren() do
			local door = room:FindFirstChild('Door')
			if door then
				local locked = door:FindFirstChild('Lock')
				if locked and isInRange(door) then
					interactWithObject(locked)
				end
				
				-- Also try the main door model
				interactWithObject(door)
			end
		end
		
		-- Auto pickup gold coins
		for _, obj in workspace:GetDescendants() do
			if obj.Name == 'GoldPile' or obj.Name == 'Gold' or (obj:IsA('Model') and obj.Name:lower():find('coin')) then
				if isInRange(obj) then
					interactWithObject(obj)
				end
			end
		end
		
		-- Auto pickup keys
		for _, room in currentRooms:GetChildren() do
			for _, obj in room:GetDescendants() do
				if obj.Name == 'KeyObtain' or obj.Name == 'Key' then
					if isInRange(obj) then
						interactWithObject(obj)
					end
				end
			end
		end
		
		-- Check for any other interactable items with ProximityPrompts
		for _, obj in currentRooms:GetDescendants() do
			if obj:IsA('ProximityPrompt') and obj.Enabled then
				local actionText = (obj.ActionText or ''):lower()
				-- Auto-interact with pickup/unlock actions
				if actionText:find('pick') or actionText:find('unlock') or actionText:find('collect') or actionText:find('take') then
					if isInRange(obj.Parent) then
						if obj.HoldDuration > 0 then
							local originalHold = obj.HoldDuration
							obj.HoldDuration = 0
							fireproximityprompt(obj)
							task.delay(0.05, function()
								if obj and obj.Parent then
									obj.HoldDuration = originalHold
								end
							end)
						else
							fireproximityprompt(obj)
						end
					end
				end
			end
		end
	end
	
	AutoInteract = vape.Categories.Utility:CreateModule({
		Name = 'AutoInteract',
		Function = function(callback)
			if callback then
				autoInteractConnection = runService.Heartbeat:Connect(autoInteract)
				AutoInteract:Clean(autoInteractConnection)
			end
		end,
		Tooltip = 'Auto opens doors, picks up gold and keys'
	})
	
	vape.Categories.Utility:CreateSlider({
		Name = 'Pickup Range',
		Min = 10,
		Max = 50,
		Default = 20,
		Function = function(val)
			pickupRange = val
		end,
		Suffix = function(val)
			return ' studs'
		end
	})
end)
