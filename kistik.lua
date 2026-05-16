local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

-- Создаем инструмент Grab
local grabTool = Instance.new("Tool")
grabTool.Name = "Grab"
grabTool.ToolTip = "Grab parts"
grabTool.CanBeDropped = false
grabTool.RequiresHandle = false

-- Переменные для управления
local currentPart = nil
local bodyPosition = nil
local bodyGyro = nil
local connection = nil

local function cleanupForces()
	if bodyPosition then 
		bodyPosition:Destroy()
		bodyPosition = nil
	end
	if bodyGyro then 
		bodyGyro:Destroy()
		bodyGyro = nil
	end
	if connection then 
		connection:Disconnect()
		connection = nil
	end
	currentPart = nil
end

local function createBodyForces(part)
	-- Сначала очищаем старые силы если есть
	if part:FindFirstChild("BodyPosition") then
		part.BodyPosition:Destroy()
	end
	if part:FindFirstChild("BodyGyro") then
		part.BodyGyro:Destroy()
	end
	
	-- УВЕЛИЧИЛИ СИЛУ BodyPosition для поднятия тяжелых объектов
	local bp = Instance.new("BodyPosition")
	bp.MaxForce = Vector3.new(1000000, 1000000, 1000000)  -- УВЕЛИЧЕНО С 40000
	bp.P = 10000  -- УВЕЛИЧЕНО
	bp.D = 1000   -- УВЕЛИЧЕНО
	
	-- УВЕЛИЧИЛИ СИЛУ BodyGyro для лучшей стабилизации
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1000000, 1000000, 1000000)  -- УВЕЛИЧЕНО С 40000
	bg.P = 16000  -- УВЕЛИЧЕНО
	bg.D = 1600   -- УВЕЛИЧЕНО
	
	bp.Parent = part
	bg.Parent = part
	
	return bp, bg
end

local function getFollowPosition()
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			-- Позиция перед игроком
			return root.Position + root.CFrame.LookVector * 5 + Vector3.new(0, 2, 0)
		end
	end
	return Vector3.new(0, 0, 0)
end

local function updatePartPosition()
	if not currentPart or not bodyPosition then return end
	
	local targetPos = getFollowPosition()
	bodyPosition.Position = targetPos
	
	-- Мягко останавливаем физику
	currentPart.Velocity = currentPart.Velocity * 0.5
	currentPart.RotVelocity = currentPart.RotVelocity * 0.5
end

-- Улучшенная функция поиска части
local function findPartNearCharacter()
	local character = player.Character
	if not character then return nil end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	
	local closestPart = nil
	local closestDistance = 15
	
	-- Ищем самую близкую часть
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj.Anchored and obj.Parent ~= character then
			local distance = (obj.Position - root.Position).Magnitude
			if distance < closestDistance then
				-- Проверяем что часть не из другого персонажа
				local isInCharacter = false
				local parent = obj.Parent
				while parent do
					if parent:FindFirstChild("Humanoid") then
						isInCharacter = true
						break
					end
					parent = parent.Parent
				end
				
				if not isInCharacter then
					closestPart = obj
					closestDistance = distance
				end
			end
		end
	end
	
	return closestPart
end

-- Когда инструмент берут в руки
grabTool.Equipped:Connect(function()
	-- Автоматически берем ближайшую часть при взятии инструмента в руки
	local targetPart = findPartNearCharacter()
	if targetPart then
		cleanupForces()
		
		currentPart = targetPart
		bodyPosition, bodyGyro = createBodyForces(currentPart)
		
		-- Немедленно устанавливаем позицию
		bodyPosition.Position = getFollowPosition()
		
		connection = RunService.Heartbeat:Connect(updatePartPosition)
		grabTool.TextureId = "rbxassetid://"
		print("Part automatically grabbed: " .. targetPart.Name)
	else
		print("No parts found nearby when equipping tool")
	end
end)

-- Когда инструмент убирают из рук
grabTool.Unequipped:Connect(function()
	-- Автоматически отпускаем часть при убирании инструмента
	cleanupForces()
	print("Part automatically dropped when unequipping tool")
end)

-- Очистка при смерти
player.CharacterAdded:Connect(function(character)
	cleanupForces()
end)

-- Очистка при удалении инструмента
grabTool.Destroying:Connect(function()
	cleanupForces()
end)

-- Помещаем инструмент в инвентарь
grabTool.Parent = backpack

print("Grab tool installed - auto grab/ungrab when equipping/unequipping")
