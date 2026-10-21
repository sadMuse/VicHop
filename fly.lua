local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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

local function getHivePosition(hive)
    local spawnPos = hive:FindFirstChild("SpawnPos")
    if spawnPos and spawnPos:IsA("BasePart") then
        return spawnPos.Position
    end
    return hive:GetPivot().Position
end

-- Плавный прямой полёт сквозь стены
local function flyTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local char = hrp.Parent

    local speed = 100 -- studs в секунду, меняй под себя

    -- noclip на время полёта
    local noclip = RunService.Stepped:Connect(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    hrp.Anchored = true -- чтобы гравитация не мешала

    local dest = targetPos + Vector3.new(0, 4, 0)
    local dist = (hrp.Position - dest).Magnitude
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(math.max(dist / speed, 0.1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {CFrame = CFrame.new(dest)}
    )
    tween:Play()
    tween.Completed:Wait()

    hrp.Anchored = false
    hrp.AssemblyLinearVelocity = Vector3.zero
    noclip:Disconnect()
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
