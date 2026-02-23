--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

-- ═══════════════════════════════════════════════════════════════
-- Arsenal Game Store
-- ═══════════════════════════════════════════════════════════════
local store = {
	hand = {},
	matchState = 0,
	currentWeapon = '',
	currentGun = nil,
	killstreak = 0,
	gunLevel = 0,
	teamColor = nil,
}
local arsenal = {}

-- ═══════════════════════════════════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════════════════════════════════
local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('Paragonv4/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...)
	return vape:CreateNotification(...)
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do
		ind += 1
	end
	return ind
end

local function waitForChildOfType(obj, name, timeout, prop)
	local check, returned = tick() + timeout
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned and returned.Name ~= 'UpperTorso' or check < tick() then
			break
		end
		task.wait()
	until false
	return returned
end

-- ═══════════════════════════════════════════════════════════════
-- Arsenal-specific helpers
-- ═══════════════════════════════════════════════════════════════
local function getArsenalTeam(plr)
	-- Arsenal uses TeamColor or Team attribute depending on mode
	local team = plr:GetAttribute('Team')
	if team then return team end

	-- Fallback: check leaderstats or TeamColor
	if plr.Team then
		return plr.Team.Name
	end
	if plr.Neutral then
		return 'FFA'
	end
	return nil
end

local function isSameTeam(plr)
	if not plr or plr == lplr then return true end
	-- FFA mode = everyone is an enemy
	if lplr.Neutral and plr.Neutral then return false end
	-- Team mode
	if lplr.Team and plr.Team then
		return lplr.Team == plr.Team
	end
	return false
end

local function getPlayerWeapon(plr)
	if not plr or not plr.Character then return 'None' end
	-- Arsenal stores current weapon as a Tool in the character
	for _, v in plr.Character:GetChildren() do
		if v:IsA('Tool') then
			return v.Name
		end
	end
	-- Check backpack for gun name via attributes
	local gunAttr = plr.Character:GetAttribute('CurrentGun') or plr.Character:GetAttribute('Gun')
	if gunAttr then return tostring(gunAttr) end
	return 'None'
end

local function getPlayerHealth(char)
	local hum = char:FindFirstChildOfClass('Humanoid')
	if hum then
		return hum.Health, hum.MaxHealth
	end
	return 100, 100
end

local function getGunLevel(plr)
	-- Arsenal tracks gun level via leaderstats or attributes
	local ls = plr:FindFirstChild('leaderstats')
	if ls then
		local level = ls:FindFirstChild('Level') or ls:FindFirstChild('Kills')
		if level then return level.Value end
	end
	return 0
end

-- ═══════════════════════════════════════════════════════════════
-- Friction / Velocity system (same as Bedwars V4)
-- ═══════════════════════════════════════════════════════════════
local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(v)
	if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
		oldfrict[v] = v.CustomPhysicalProperties or 'none'
		v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end
		if newState then
			if entitylib.isAlive then
				for _, v in entitylib.character.Character:GetDescendants() do
					modifyVelocity(v)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for i, v in oldfrict do
				i.CustomPhysicalProperties = v ~= 'none' and v or nil
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

-- ═══════════════════════════════════════════════════════════════
-- Sort methods for targeting (visual modules use these)
-- ═══════════════════════════════════════════════════════════════
local sortmethods = {
	Health = function(a, b)
		return a.Entity.Health < b.Entity.Health
	end,
	Angle = function(a, b)
		local selfrootpos = entitylib.character.RootPart.Position
		local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		local angle = math.acos(localfacing:Dot(((a.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		local angle2 = math.acos(localfacing:Dot(((b.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		return angle < angle2
	end,
	Weapon = function(a, b)
		-- Prioritize players with better weapons (higher gun level)
		local aLevel = a.Entity.Player and getGunLevel(a.Entity.Player) or 0
		local bLevel = b.Entity.Player and getGunLevel(b.Entity.Player) or 0
		return aLevel > bLevel
	end
}

-- ═══════════════════════════════════════════════════════════════
-- Entity System Override (Arsenal-specific)
-- ═══════════════════════════════════════════════════════════════
run(function()
	local oldstart = entitylib.start

	entitylib.start = function()
		oldstart()
	end

	entitylib.addPlayer = function(plr)
		if plr.Character then
			entitylib.refreshEntity(plr.Character, plr)
		end
		entitylib.PlayerConnections[plr] = {
			plr.CharacterAdded:Connect(function(char)
				entitylib.refreshEntity(char, plr)
			end),
			plr.CharacterRemoving:Connect(function(char)
				entitylib.removeEntity(char, plr == lplr)
			end),
			-- Arsenal team changes (round resets, team swaps)
			plr:GetPropertyChangedSignal('Team'):Connect(function()
				for _, v in entitylib.List do
					if v.Targetable ~= entitylib.targetCheck(v) then
						entitylib.refreshEntity(v.Character, v.Player)
					end
				end

				if plr == lplr then
					entitylib.start()
				else
					entitylib.refreshEntity(plr.Character, plr)
				end
			end)
		}
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = hum and waitForChildOfType(hum, 'RootPart', 10, true)
			local head = char:WaitForChild('Head', 10) or humrootpart

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = hum.Health,
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					Jumps = 0,
					JumpTick = tick(),
					Jumping = false,
					LandTick = tick(),
					MaxHealth = hum.MaxHealth,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc,
					Weapon = 'None'
				}

				if plr == lplr then
					entity.AirTime = tick()
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
				else
					entity.Targetable = entitylib.targetCheck(entity)

					-- Health tracking
					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entity.Health = hum.Health
							entity.MaxHealth = hum.MaxHealth
							entity.Weapon = getPlayerWeapon(plr)
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					-- Jump detection
					if plr then
						local anim = char:FindFirstChild('Animate')
						if anim then
							pcall(function()
								anim = anim.jump:FindFirstChildWhichIsA('Animation').AnimationId
								table.insert(entity.Connections, hum.Animator.AnimationPlayed:Connect(function(playedanim)
									if playedanim.Animation.AnimationId == anim then
										entity.JumpTick = tick()
										entity.Jumps += 1
										entity.LandTick = tick() + 1
										entity.Jumping = entity.Jumps > 1
									end
								end))
							end)
						end
					end

					-- Weapon change tracking via Tool added/removed
					table.insert(entity.Connections, char.ChildAdded:Connect(function(child)
						if child:IsA('Tool') then
							entity.Weapon = child.Name
							entitylib.Events.EntityUpdated:Fire(entity)
						end
					end))
					table.insert(entity.Connections, char.ChildRemoved:Connect(function(child)
						if child:IsA('Tool') then
							task.wait()
							entity.Weapon = getPlayerWeapon(plr)
							entitylib.Events.EntityUpdated:Fire(entity)
						end
					end))

					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end

				-- Part removal safety
				table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
					if part == humrootpart or part == hum or part == head then
						if part == humrootpart and hum.RootPart then
							humrootpart = hum.RootPart
							entity.RootPart = hum.RootPart
							entity.HumanoidRootPart = hum.RootPart
							return
						end
						entitylib.removeEntity(char, plr == lplr)
					end
				end))
			end
			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.getUpdateConnections = function(ent)
		local char = ent.Character
		local hum = ent.Humanoid
		local tab = {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}
		return tab
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		return not isSameTeam(ent.Player)
	end

	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
end)
entitylib.start()

-- ═══════════════════════════════════════════════════════════════
-- Arsenal Game Framework Hook
-- ═══════════════════════════════════════════════════════════════
run(function()
	-- Try to grab Arsenal's internal framework
	-- Arsenal uses a mix of RemoteEvents and module scripts
	local arsenalLoaded = false

	pcall(function()
		-- Wait for Arsenal's game systems to load
		local events = replicatedStorage:WaitForChild('Events', 10)
		local modules = replicatedStorage:WaitForChild('Modules', 10) or replicatedStorage:WaitForChild('GameModules', 10)

		if events then
			arsenal.Events = events
			arsenalLoaded = true
		end

		-- Grab weapon data if available
		pcall(function()
			local gunModule = require(replicatedStorage:FindFirstChild('GunModule', true) or replicatedStorage:FindFirstChild('Guns', true))
			if gunModule then
				arsenal.GunData = gunModule
			end
		end)
	end)

	-- ═══════════════════════════════════════════════════════════
	-- Kill Feed & Death Tracking
	-- ═══════════════════════════════════════════════════════════
	local function hookKillFeed()
		-- Arsenal fires kill events through various methods
		-- Method 1: Listen for leaderstats changes
		local ls = lplr:WaitForChild('leaderstats', 10)
		if ls then
			local killsStat = ls:FindFirstChild('Kills') or ls:FindFirstChild('Level')
			if killsStat then
				vape:Clean(killsStat:GetPropertyChangedSignal('Value'):Connect(function()
					store.gunLevel = killsStat.Value
					vapeEvents.GunLevelChanged:Fire(killsStat.Value)
				end))
			end
		end

		-- Method 2: Listen for kill notification events
		pcall(function()
			if arsenal.Events then
				local killEvent = arsenal.Events:FindFirstChild('KillEvent')
					or arsenal.Events:FindFirstChild('Killed')
					or arsenal.Events:FindFirstChild('PlayerKilled')

				if killEvent and killEvent:IsA('RemoteEvent') then
					vape:Clean(killEvent.OnClientEvent:Connect(function(killer, killed, weapon)
						vapeEvents.ArsenalKillEvent:Fire({
							killer = killer,
							killed = killed,
							weapon = weapon
						})
					end))
				end
			end
		end)

		-- Method 3: Humanoid.Died for local death tracking
		local function trackLocalDeath()
			if entitylib.isAlive and entitylib.character.Humanoid then
				entitylib.character.Humanoid.Died:Connect(function()
					vapeEvents.LocalPlayerDied:Fire()
				end)
			end
		end
		vape:Clean(entitylib.Events.LocalAdded:Connect(trackLocalDeath))
	end

	-- ═══════════════════════════════════════════════════════════
	-- Local weapon tracking
	-- ═══════════════════════════════════════════════════════════
	local function trackLocalWeapon()
		if not entitylib.isAlive then return end
		local char = entitylib.character.Character

		local function updateWeapon()
			for _, v in char:GetChildren() do
				if v:IsA('Tool') then
					store.currentWeapon = v.Name
					store.currentGun = v
					store.hand = {
						tool = v,
						toolType = 'gun'
					}
					vapeEvents.WeaponChanged:Fire(v.Name)
					return
				end
			end
			store.currentWeapon = 'None'
			store.currentGun = nil
			store.hand = {toolType = ''}
		end

		updateWeapon()
		vape:Clean(char.ChildAdded:Connect(function(child)
			if child:IsA('Tool') then
				updateWeapon()
			end
		end))
		vape:Clean(char.ChildRemoved:Connect(function(child)
			if child:IsA('Tool') then
				task.wait()
				updateWeapon()
			end
		end))
	end

	vape:Clean(entitylib.Events.LocalAdded:Connect(trackLocalWeapon))

	-- ═══════════════════════════════════════════════════════════
	-- Session Info (kill/death/win tracking)
	-- ═══════════════════════════════════════════════════════════
	local kills = sessioninfo:AddItem('Kills')
	local deaths = sessioninfo:AddItem('Deaths')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	sessioninfo:AddItem('Weapon', 0, function()
		return store.currentWeapon
	end, false)

	task.delay(1, function()
		games:Increment()
	end)

	-- Map detection
	task.spawn(function()
		pcall(function()
			-- Arsenal maps are usually in workspace.Map or workspace
			local map = workspace:FindFirstChild('Map') or workspace:FindFirstChild('GameMap')
			if map then
				mapname = map.Name
			else
				-- Try to find map from game state
				for _, v in workspace:GetChildren() do
					if v:IsA('Folder') and v.Name ~= 'Terrain' and #v:GetChildren() > 20 then
						mapname = v.Name
						break
					end
				end
			end
		end)
	end)

	-- Kill tracking via various methods
	vape:Clean(vapeEvents.ArsenalKillEvent.Event:Connect(function(data)
		if data.killer and data.killer == lplr then
			kills:Increment()
			store.killstreak += 1
		end
		if data.killed and data.killed == lplr then
			deaths:Increment()
			store.killstreak = 0
		end
	end))

	vape:Clean(vapeEvents.LocalPlayerDied.Event:Connect(function()
		deaths:Increment()
		store.killstreak = 0
	end))

	hookKillFeed()

	-- ═══════════════════════════════════════════════════════════
	-- Jump / AirTime tracking loop
	-- ═══════════════════════════════════════════════════════════
	task.spawn(function()
		repeat
			if entitylib.isAlive then
				entitylib.character.AirTime = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entitylib.character.AirTime
			end

			for _, v in entitylib.List do
				v.LandTick = math.abs(v.RootPart.Velocity.Y) < 0.1 and v.LandTick or tick()
				if (tick() - v.LandTick) > 0.2 and v.Jumps ~= 0 then
					v.Jumps = 0
					v.Jumping = false
				end
			end
			task.wait()
		until vape.Loaded == nil
	end)

	-- ═══════════════════════════════════════════════════════════
	-- Cleanup
	-- ═══════════════════════════════════════════════════════════
	vape:Clean(function()
		for _, v in vapeEvents do
			v:Destroy()
		end
		table.clear(vapeEvents)
		table.clear(arsenal)
		table.clear(store)
	end)
end)

-- ═══════════════════════════════════════════════════════════════
-- Remove modules that don't apply to Arsenal
-- ═══════════════════════════════════════════════════════════════
for _, v in {
	'AutoCharge', 'AutoBridge', 'BedNuker', 'BlockPlacer',
	'Scaffold', 'Timer', 'MurderMystery'
} do
	vape:Remove(v)
end

-- ═══════════════════════════════════════════════════════════════
-- AimAssist (Visual only - camera smoothing, no hit manipulation)
-- ═══════════════════════════════════════════════════════════════
run(function()
	local AimAssist
	local Targets
	local Sort
	local AimSpeed
	local Distance
	local AngleSlider
	local ClickAim

	AimAssist = vape.Categories.Combat:CreateModule({
		Name = 'AimAssist',
		Function = function(callback)
			if callback then
				AimAssist:Clean(runService.Heartbeat:Connect(function(dt)
					if entitylib.isAlive and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
						local ent = entitylib.EntityPosition({
							Range = Distance.Value,
							Part = 'Head',
							Wallcheck = Targets.Walls.Enabled,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Sort = sortmethods[Sort.Value]
						})

						if ent then
							local delta = (ent.Head.Position - entitylib.character.RootPart.Position)
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
							local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
							if angle >= (math.rad(AngleSlider.Value) / 2) then return end
							targetinfo.Targets[ent] = tick() + 1
							gameCamera.CFrame = gameCamera.CFrame:Lerp(
								CFrame.lookAt(gameCamera.CFrame.p, ent.Head.Position),
								AimSpeed.Value * dt
							)
						end
					end
				end))
			end
		end,
		Tooltip = 'Smoothly aims camera toward nearest enemy (visual camera assist only)'
	})
	Targets = AimAssist:CreateTargets({
		Players = true,
		Walls = true
	})
	Sort = AimAssist:CreateDropdown({
		Name = 'Target Mode',
		List = {'Distance', 'Health', 'Angle', 'Weapon'}
	})
	AimSpeed = AimAssist:CreateSlider({
		Name = 'Aim Speed',
		Min = 1,
		Max = 20,
		Default = 6
	})
	Distance = AimAssist:CreateSlider({
		Name = 'Distance',
		Min = 1,
		Max = 200,
		Default = 100,
		Suffx = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = AimAssist:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 90
	})
	ClickAim = AimAssist:CreateToggle({
		Name = 'Click Aim',
		Default = true
	})
end)

-- ═══════════════════════════════════════════════════════════════
-- ESP Module
-- ═══════════════════════════════════════════════════════════════
run(function()
	local ESP
	local ESPTargets
	local ShowWeapon
	local ShowDistance
	local ShowHealth
	local ESPColor
	local EnemyColor
	local FriendColor
	local MaxDist
	local TextSize
	local espObjects = {}

	local function createESP(entity)
		local billboard = Instance.new('BillboardGui')
		billboard.Name = 'VapeESP'
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(200, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.LightInfluence = 0
		billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local nameLabel = Instance.new('TextLabel')
		nameLabel.Name = 'Name'
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 13
		nameLabel.Parent = billboard

		local healthLabel = Instance.new('TextLabel')
		healthLabel.Name = 'Health'
		healthLabel.Size = UDim2.new(1, 0, 0, 14)
		healthLabel.Position = UDim2.fromOffset(0, 16)
		healthLabel.BackgroundTransparency = 1
		healthLabel.TextColor3 = Color3.new(0, 1, 0)
		healthLabel.TextStrokeTransparency = 0.5
		healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		healthLabel.Font = Enum.Font.Gotham
		healthLabel.TextSize = 11
		healthLabel.Parent = billboard

		local weaponLabel = Instance.new('TextLabel')
		weaponLabel.Name = 'Weapon'
		weaponLabel.Size = UDim2.new(1, 0, 0, 14)
		weaponLabel.Position = UDim2.fromOffset(0, 30)
		weaponLabel.BackgroundTransparency = 1
		weaponLabel.TextColor3 = Color3.new(1, 0.8, 0.2)
		weaponLabel.TextStrokeTransparency = 0.5
		weaponLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		weaponLabel.Font = Enum.Font.Gotham
		weaponLabel.TextSize = 11
		weaponLabel.Parent = billboard

		billboard.Adornee = entity.Head
		billboard.Parent = coreGui

		espObjects[entity] = {
			billboard = billboard,
			nameLabel = nameLabel,
			healthLabel = healthLabel,
			weaponLabel = weaponLabel
		}
	end

	local function removeESP(entity)
		if espObjects[entity] then
			espObjects[entity].billboard:Destroy()
			espObjects[entity] = nil
		end
	end

	local function updateESP()
		if not entitylib.isAlive then return end
		local selfPos = entitylib.character.RootPart.Position

		for entity, obj in espObjects do
			if not entity.RootPart or not entity.RootPart.Parent then
				removeESP(entity)
				continue
			end

			local dist = (entity.RootPart.Position - selfPos).Magnitude
			if dist > MaxDist.Value then
				obj.billboard.Enabled = false
				continue
			end

			obj.billboard.Enabled = true

			-- Color based on team
			local isEnemy = entity.Targetable
			local espColor = isEnemy and EnemyColor:GetColor() or FriendColor:GetColor()
			if entity.Friend then
				espColor = Color3.new(0, 0.6, 1)
			end
			if entity.Target then
				espColor = Color3.new(1, 0.2, 0.2)
			end

			-- Name
			local name = entity.Player and entity.Player.DisplayName or 'Unknown'
			local distText = ShowDistance.Enabled and string.format(' [%dm]', math.floor(dist)) or ''
			obj.nameLabel.Text = name .. distText
			obj.nameLabel.TextColor3 = espColor
			obj.nameLabel.TextSize = TextSize.Value

			-- Health
			if ShowHealth.Enabled then
				local hp, maxhp = entity.Health, entity.MaxHealth
				local pct = math.clamp(hp / maxhp, 0, 1)
				obj.healthLabel.Text = string.format('%d/%d', math.floor(hp), math.floor(maxhp))
				obj.healthLabel.TextColor3 = Color3.new(1 - pct, pct, 0)
				obj.healthLabel.Visible = true
			else
				obj.healthLabel.Visible = false
			end

			-- Weapon
			if ShowWeapon.Enabled then
				obj.weaponLabel.Text = entity.Weapon or getPlayerWeapon(entity.Player)
				obj.weaponLabel.Visible = true
			else
				obj.weaponLabel.Visible = false
			end
		end
	end

	ESP = vape.Categories.Render:CreateModule({
		Name = 'ESP',
		Function = function(callback)
			if callback then
				-- Create ESP for existing entities
				for _, v in entitylib.List do
					createESP(v)
				end

				ESP:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					createESP(ent)
				end))

				ESP:Clean(entitylib.Events.EntityRemoved:Connect(function(ent)
					removeESP(ent)
				end))

				ESP:Clean(runService.RenderStepped:Connect(updateESP))
			else
				for entity in espObjects do
					removeESP(entity)
				end
				table.clear(espObjects)
			end
		end,
		Tooltip = 'Shows player names, health, weapons, and distance through walls'
	})
	ESPTargets = ESP:CreateTargets({
		Players = true,
		Walls = true
	})
	ShowWeapon = ESP:CreateToggle({
		Name = 'Show Weapon',
		Default = true
	})
	ShowDistance = ESP:CreateToggle({
		Name = 'Show Distance',
		Default = true
	})
	ShowHealth = ESP:CreateToggle({
		Name = 'Show Health',
		Default = true
	})
	TextSize = ESP:CreateSlider({
		Name = 'Text Size',
		Min = 8,
		Max = 20,
		Default = 13
	})
	MaxDist = ESP:CreateSlider({
		Name = 'Max Distance',
		Min = 50,
		Max = 1000,
		Default = 500,
		Suffx = function(val)
			return 'studs'
		end
	})
	EnemyColor = ESP:CreateColorSlider({
		Name = 'Enemy Color',
		Default = Color3.fromRGB(255, 50, 50)
	})
	FriendColor = ESP:CreateColorSlider({
		Name = 'Team Color',
		Default = Color3.fromRGB(50, 255, 50)
	})
end)

-- ═══════════════════════════════════════════════════════════════
-- Chams Module (Character Highlights)
-- ═══════════════════════════════════════════════════════════════
run(function()
	local Chams
	local ChamsTargets
	local ChamTransparency
	local ChamEnemyColor
	local ChamFriendColor
	local MaxDist
	local chamObjects = {}

	local function createChams(entity)
		local highlight = Instance.new('Highlight')
		highlight.Name = 'VapeChams'
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = entity.Character
		highlight.Parent = coreGui

		chamObjects[entity] = highlight
	end

	local function removeChams(entity)
		if chamObjects[entity] then
			chamObjects[entity]:Destroy()
			chamObjects[entity] = nil
		end
	end

	local function updateChams()
		if not entitylib.isAlive then return end
		local selfPos = entitylib.character.RootPart.Position

		for entity, highlight in chamObjects do
			if not entity.RootPart or not entity.RootPart.Parent then
				removeChams(entity)
				continue
			end

			local dist = (entity.RootPart.Position - selfPos).Magnitude
			if dist > MaxDist.Value then
				highlight.Enabled = false
				continue
			end

			highlight.Enabled = true
			highlight.FillTransparency = ChamTransparency.Value / 100

			local isEnemy = entity.Targetable
			local chamColor = isEnemy and ChamEnemyColor:GetColor() or ChamFriendColor:GetColor()
			if entity.Friend then
				chamColor = Color3.new(0, 0.6, 1)
			end
			if entity.Target then
				chamColor = Color3.new(1, 0.2, 0.2)
			end

			highlight.FillColor = chamColor
			highlight.OutlineColor = chamColor
		end
	end

	Chams = vape.Categories.Render:CreateModule({
		Name = 'Chams',
		Function = function(callback)
			if callback then
				for _, v in entitylib.List do
					createChams(v)
				end

				Chams:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					createChams(ent)
				end))

				Chams:Clean(entitylib.Events.EntityRemoved:Connect(function(ent)
					removeChams(ent)
				end))

				Chams:Clean(runService.RenderStepped:Connect(updateChams))
			else
				for entity in chamObjects do
					removeChams(entity)
				end
				table.clear(chamObjects)
			end
		end,
		Tooltip = 'Highlights players through walls with colored outlines'
	})
	ChamsTargets = Chams:CreateTargets({
		Players = true,
		Walls = true
	})
	ChamTransparency = Chams:CreateSlider({
		Name = 'Fill Transparency',
		Min = 0,
		Max = 100,
		Default = 50
	})
	MaxDist = Chams:CreateSlider({
		Name = 'Max Distance',
		Min = 50,
		Max = 1000,
		Default = 500,
		Suffx = function(val)
			return 'studs'
		end
	})
	ChamEnemyColor = Chams:CreateColorSlider({
		Name = 'Enemy Color',
		Default = Color3.fromRGB(255, 50, 50)
	})
	ChamFriendColor = Chams:CreateColorSlider({
		Name = 'Team Color',
		Default = Color3.fromRGB(50, 255, 50)
	})
end)

-- ═══════════════════════════════════════════════════════════════
-- Tracers Module
-- ═══════════════════════════════════════════════════════════════
run(function()
	local Tracers
	local TracerTargets
	local TracerOrigin
	local TracerThickness
	local TracerEnemyColor
	local TracerFriendColor
	local MaxDist
	local tracerObjects = {}

	local function createTracer(entity)
		local line = Drawing.new('Line')
		line.Visible = false
		line.Thickness = 1
		line.Transparency = 1
		tracerObjects[entity] = line
	end

	local function removeTracer(entity)
		if tracerObjects[entity] then
			tracerObjects[entity]:Remove()
			tracerObjects[entity] = nil
		end
	end

	local function updateTracers()
		if not entitylib.isAlive then return end
		local selfPos = entitylib.character.RootPart.Position
		local viewportSize = gameCamera.ViewportSize

		for entity, line in tracerObjects do
			if not entity.RootPart or not entity.RootPart.Parent then
				line.Visible = false
				continue
			end

			local dist = (entity.RootPart.Position - selfPos).Magnitude
			if dist > MaxDist.Value then
				line.Visible = false
				continue
			end

			local screenPos, onScreen = gameCamera:WorldToViewportPoint(entity.RootPart.Position)
			if not onScreen then
				line.Visible = false
				continue
			end

			line.Visible = true
			line.Thickness = TracerThickness.Value

			-- Origin point
			local origin
			if TracerOrigin.Value == 'Bottom' then
				origin = Vector2.new(viewportSize.X / 2, viewportSize.Y)
			elseif TracerOrigin.Value == 'Center' then
				origin = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
			else -- Top
				origin = Vector2.new(viewportSize.X / 2, 0)
			end

			line.From = origin
			line.To = Vector2.new(screenPos.X, screenPos.Y)

			local isEnemy = entity.Targetable
			local tracerColor = isEnemy and TracerEnemyColor:GetColor() or TracerFriendColor:GetColor()
			if entity.Friend then
				tracerColor = Color3.new(0, 0.6, 1)
			end
			if entity.Target then
				tracerColor = Color3.new(1, 0.2, 0.2)
			end
			line.Color = tracerColor
		end
	end

	Tracers = vape.Categories.Render:CreateModule({
		Name = 'Tracers',
		Function = function(callback)
			if callback then
				for _, v in entitylib.List do
					createTracer(v)
				end

				Tracers:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					createTracer(ent)
				end))

				Tracers:Clean(entitylib.Events.EntityRemoved:Connect(function(ent)
					removeTracer(ent)
				end))

				Tracers:Clean(runService.RenderStepped:Connect(updateTracers))
			else
				for entity in tracerObjects do
					removeTracer(entity)
				end
				table.clear(tracerObjects)
			end
		end,
		Tooltip = 'Draws lines from screen to player positions'
	})
	TracerTargets = Tracers:CreateTargets({
		Players = true,
		Walls = true
	})
	TracerOrigin = Tracers:CreateDropdown({
		Name = 'Origin',
		List = {'Bottom', 'Center', 'Top'}
	})
	TracerThickness = Tracers:CreateSlider({
		Name = 'Thickness',
		Min = 1,
		Max = 5,
		Default = 1
	})
	MaxDist = Tracers:CreateSlider({
		Name = 'Max Distance',
		Min = 50,
		Max = 1000,
		Default = 500,
		Suffx = function(val)
			return 'studs'
		end
	})
	TracerEnemyColor = Tracers:CreateColorSlider({
		Name = 'Enemy Color',
		Default = Color3.fromRGB(255, 50, 50)
	})
	TracerFriendColor = Tracers:CreateColorSlider({
		Name = 'Team Color',
		Default = Color3.fromRGB(50, 255, 50)
	})
end)

-- ═══════════════════════════════════════════════════════════════
-- Nametags Module (Custom styled nametags)
-- ═══════════════════════════════════════════════════════════════
run(function()
	local Nametags
	local NametagTargets
	local ShowWeapon
	local ShowHealth
	local ShowHealthBar
	local NametagScale
	local MaxDist
	local nametagObjects = {}

	local function createNametag(entity)
		local billboard = Instance.new('BillboardGui')
		billboard.Name = 'VapeNametag'
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(200, 48)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.LightInfluence = 0
		billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local frame = Instance.new('Frame')
		frame.Name = 'Container'
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.4
		frame.Parent = billboard

		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame

		local nameLabel = Instance.new('TextLabel')
		nameLabel.Name = 'Name'
		nameLabel.Size = UDim2.new(1, -8, 0, 16)
		nameLabel.Position = UDim2.fromOffset(4, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 12
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = frame

		local healthBar = Instance.new('Frame')
		healthBar.Name = 'HealthBarBG'
		healthBar.Size = UDim2.new(1, -8, 0, 4)
		healthBar.Position = UDim2.new(0, 4, 1, -8)
		healthBar.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
		healthBar.BorderSizePixel = 0
		healthBar.Parent = frame

		local healthBarCorner = Instance.new('UICorner')
		healthBarCorner.CornerRadius = UDim.new(0, 2)
		healthBarCorner.Parent = healthBar

		local healthFill = Instance.new('Frame')
		healthFill.Name = 'Fill'
		healthFill.Size = UDim2.new(1, 0, 1, 0)
		healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
		healthFill.BorderSizePixel = 0
		healthFill.Parent = healthBar

		local healthFillCorner = Instance.new('UICorner')
		healthFillCorner.CornerRadius = UDim.new(0, 2)
		healthFillCorner.Parent = healthFill

		local weaponLabel = Instance.new('TextLabel')
		weaponLabel.Name = 'Weapon'
		weaponLabel.Size = UDim2.new(1, -8, 0, 14)
		weaponLabel.Position = UDim2.fromOffset(4, 18)
		weaponLabel.BackgroundTransparency = 1
		weaponLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		weaponLabel.Font = Enum.Font.Gotham
		weaponLabel.TextSize = 10
		weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
		weaponLabel.Parent = frame

		billboard.Adornee = entity.Head
		billboard.Parent = coreGui

		-- Hide default nametag
		pcall(function()
			if entity.Character:FindFirstChild('NameTag') then
				entity.Character.NameTag.Enabled = false
			end
		end)

		nametagObjects[entity] = {
			billboard = billboard,
			frame = frame,
			nameLabel = nameLabel,
			healthBar = healthBar,
			healthFill = healthFill,
			weaponLabel = weaponLabel
		}
	end

	local function removeNametag(entity)
		if nametagObjects[entity] then
			nametagObjects[entity].billboard:Destroy()
			-- Restore default nametag
			pcall(function()
				if entity.Character and entity.Character:FindFirstChild('NameTag') then
					entity.Character.NameTag.Enabled = true
				end
			end)
			nametagObjects[entity] = nil
		end
	end

	local function updateNametags()
		if not entitylib.isAlive then return end
		local selfPos = entitylib.character.RootPart.Position

		for entity, obj in nametagObjects do
			if not entity.RootPart or not entity.RootPart.Parent then
				removeNametag(entity)
				continue
			end

			local dist = (entity.RootPart.Position - selfPos).Magnitude
			if dist > MaxDist.Value then
				obj.billboard.Enabled = false
				continue
			end

			obj.billboard.Enabled = true

			-- Scale based on distance
			local scale = math.clamp(NametagScale.Value / math.max(dist, 1), 0.3, 2)
			obj.billboard.Size = UDim2.fromOffset(200 * scale, 48 * scale)

			-- Name
			local name = entity.Player and entity.Player.DisplayName or 'Unknown'
			obj.nameLabel.Text = name

			-- Health bar
			if ShowHealthBar.Enabled then
				local pct = math.clamp(entity.Health / entity.MaxHealth, 0, 1)
				obj.healthFill.Size = UDim2.new(pct, 0, 1, 0)
				obj.healthFill.BackgroundColor3 = Color3.new(1 - pct, pct, 0)
				obj.healthBar.Visible = true
			else
				obj.healthBar.Visible = false
			end

			-- Weapon
			if ShowWeapon.Enabled then
				obj.weaponLabel.Text = entity.Weapon or getPlayerWeapon(entity.Player)
				obj.weaponLabel.Visible = true
			else
				obj.weaponLabel.Visible = false
			end
		end
	end

	Nametags = vape.Categories.Render:CreateModule({
		Name = 'NameTags',
		Function = function(callback)
			if callback then
				for _, v in entitylib.List do
					createNametag(v)
				end

				Nametags:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					createNametag(ent)
				end))

				Nametags:Clean(entitylib.Events.EntityRemoved:Connect(function(ent)
					removeNametag(ent)
				end))

				Nametags:Clean(runService.RenderStepped:Connect(updateNametags))
			else
				for entity in nametagObjects do
					removeNametag(entity)
				end
				table.clear(nametagObjects)
			end
		end,
		Tooltip = 'Custom styled nametags showing player info through walls'
	})
	NametagTargets = Nametags:CreateTargets({
		Players = true,
		Walls = true
	})
	ShowWeapon = Nametags:CreateToggle({
		Name = 'Show Weapon',
		Default = true
	})
	ShowHealth = Nametags:CreateToggle({
		Name = 'Show Health Text',
		Default = false
	})
	ShowHealthBar = Nametags:CreateToggle({
		Name = 'Show Health Bar',
		Default = true
	})
	NametagScale = Nametags:CreateSlider({
		Name = 'Scale',
		Min = 10,
		Max = 200,
		Default = 80
	})
	MaxDist = Nametags:CreateSlider({
		Name = 'Max Distance',
		Min = 50,
		Max = 1000,
		Default = 500,
		Suffx = function(val)
			return 'studs'
		end
	})
end)
