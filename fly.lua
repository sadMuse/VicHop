local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- защита от двойного запуска
if _G.HiveFlyRunning then
    _G.HiveFlyStop = true
    task.wait(0.3)
end
_G.HiveFlyRunning = true
_G.HiveFlyStop = false

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

-- Прямой полёт к точке сквозь стены
local function flyTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local char = hrp.Parent

    local maxSpeed = 15    -- studs/сек
    local accel = 0.15
    local dest = targetPos + Vector3.new(0, 4, 0)

    local noclip = RunService.Stepped:Connect(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    local currentSpeed = 0
    local done = false

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if _G.HiveFlyStop or not hrp.Parent then
            done = true
            return
        end

        local diff = dest - hrp.Position
        local dist = diff.Magnitude

        if dist < 1.5 then
            done = true
            return
        end

        local wanted = math.min(maxSpeed, dist * 3)
        currentSpeed = currentSpeed + (wanted - currentSpeed) * accel

        local step = math.min(currentSpeed * dt, dist)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(hrp.Position + diff.Unit * step)
    end)

    while not done do
        task.wait()
    end

    conn:Disconnect()
    noclip:Disconnect()
    hrp.AssemblyLinearVelocity = Vector3.zero
end

task.spawn(function()
    task.wait(2)

    local events = ReplicatedStorage:WaitForChild("Events", 10)
    local claim = events and events:FindFirstChild("ClaimHive")
    if not claim then
        notify("Ошибка", "ClaimHive не найден")
        _G.HiveFlyRunning = false
        return
    end

    local hive, num = findFreeHive()
    if not hive then
        notify("Ошибка", "Свободных ульев нет")
        _G.HiveFlyRunning = false
        return
    end

    notify("Улей", "Лечу к " .. hive.Name)
    flyTo(getHivePosition(hive))

    -- сразу после прилёта
    claim:FireServer(num)

    task.wait(1)
    local owner = hive:FindFirstChild("Owner")
    if owner and owner.Value == player then
        notify("Успех", "Улей " .. hive.Name .. " занят")
    else
        notify("Упс", "Не получилось занять " .. hive.Name)
    end

    _G.HiveFlyRunning = false
end)
