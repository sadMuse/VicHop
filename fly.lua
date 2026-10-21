local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local function notify(t, x)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t, Text = x, Duration = 3})
    end)
end

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

-- Ищем свободный улей: Owner.Value == nil
local function findFreeHive()
    local honeycombs = workspace:WaitForChild("Honeycombs", 10)
    if not honeycombs then return nil end

    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        local num = tonumber(hive.Name:match("%d+"))
        if owner and owner.Value == nil and num then
            return hive, num
        end
    end
    return nil
end

-- Позиция улья (SpawnPos, если есть, иначе центр модели)
local function getHivePosition(hive)
    local spawnPos = hive:FindFirstChild("SpawnPos")
    if spawnPos and spawnPos:IsA("BasePart") then
        return spawnPos.Position
    end
    return hive:GetPivot().Position
end

-- Полёт: вверх -> над ульем -> вниз (с постоянной скоростью)
local function flyTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end

    local speed = 120
    local height = 60

    local function tweenTo(pos)
        local dist = (hrp.Position - pos).Magnitude
        local tween = TweenService:Create(
            hrp,
            TweenInfo.new(math.max(dist / speed, 0.1), Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(pos)}
        )
        tween:Play()
        tween.Completed:Wait()
    end

    tweenTo(Vector3.new(hrp.Position.X, hrp.Position.Y + height, hrp.Position.Z))
    tweenTo(Vector3.new(targetPos.X, targetPos.Y + height, targetPos.Z))
    tweenTo(targetPos + Vector3.new(0, 4, 0))
end

task.spawn(function()
    task.wait(2)

    local events = ReplicatedStorage:WaitForChild("Events", 10)
    local claim = events and events:FindFirstChild("ClaimHive")
    if not claim then
        notify("Ошибка", "ClaimHive не найден")
        return
    end

    local hive, num = findFreeHive()
    if not hive then
        notify("Ошибка", "Свободных ульев нет")
        return
    end

    notify("Улей", "Лечу к " .. hive.Name)
    flyTo(getHivePosition(hive))
    task.wait(0.5)

    claim:FireServer(num)

    task.wait(1)
    local owner = hive:FindFirstChild("Owner")
    if owner and owner.Value == player then
        notify("Успех", "Улей " .. hive.Name .. " занят")
    else
        notify("Упс", "Не получилось занять " .. hive.Name)
    end
end)
