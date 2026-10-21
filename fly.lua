local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- режим: _G.HiveRun = true -> бег, иначе полёт
local RUN_MODE = (_G.HiveRun == true)
local RUN_SPEED = 50   -- скорость бега (WalkSpeed)
local FLY_SPEED = 150  -- скорость полёта (studs/сек)

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

-- Центр текстуры (localpatharrow) улья
local function getHivePosition(hive)
    local arrow = hive:FindFirstChild("localpatharrow")
    if arrow then
        if arrow:IsA("Model") then
            local cf = arrow:GetBoundingBox()
            return cf.Position
        elseif arrow:IsA("BasePart") then
            return arrow.Position
        end
    end

    local spawnPos = hive:FindFirstChild("SpawnPos")
    if spawnPos and spawnPos:IsA("BasePart") then
        return spawnPos.Position
    end
    return hive:GetPivot().Position
end

-- Ближайший свободный улей
local function findNearestFreeHive()
    local hrp = getHRP()
    local honeycombs = workspace:WaitForChild("Honeycombs", 10)
    if not hrp or not honeycombs then return nil end

    local bestHive, bestNum, bestDist = nil, nil, math.huge

    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        local num = tonumber(hive.Name:match("%d+"))
        if owner and owner.Value == nil and num then
            local dist = (getHivePosition(hive) - hrp.Position).Magnitude
            if dist < bestDist then
                bestHive, bestNum, bestDist = hive, num, dist
            end
        end
    end

    return bestHive, bestNum
end

-- Прямой полёт к точке сквозь стены
local function flyTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local char = hrp.Parent

    local accel = 0.15
    local dest = targetPos + Vector3.new(0, 3, 0)

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

        if dist < 1 then
            done = true
            return
        end

        local wanted = math.min(FLY_SPEED, dist * 5)
        currentSpeed = currentSpeed + (wanted - currentSpeed) * accel

        local step = math.min(currentSpeed * dt, dist)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(hrp.Position + diff.Unit * step)
    end)

    while not done do
        task.wait()
    end

    if hrp.Parent then
        hrp.CFrame = CFrame.new(dest)
    end

    conn:Disconnect()
    noclip:Disconnect()
    hrp.AssemblyLinearVelocity = Vector3.zero
end

-- Бег к точке (обычная ходьба по земле)
local function runTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = RUN_SPEED

    local started = tick()
    local lastPos = hrp.Position
    local lastCheck = tick()

    while not _G.HiveFlyStop and hrp.Parent do
        local flat = Vector3.new(targetPos.X - hrp.Position.X, 0, targetPos.Z - hrp.Position.Z)
        if flat.Magnitude < 3 then break end

        hum:MoveTo(targetPos)

        -- если застрял, прыгаем
        if tick() - lastCheck > 1 then
            if (hrp.Position - lastPos).Magnitude < 2 then
                hum.Jump = true
            end
            lastPos = hrp.Position
            lastCheck = tick()
        end

        -- предохранитель, чтобы не бежать вечно
        if tick() - started > 30 then break end

        task.wait(0.1)
    end

    hum.WalkSpeed = oldSpeed
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

    local hive, num = findNearestFreeHive()
    if not hive then
        notify("Ошибка", "Свободных ульев нет")
        _G.HiveFlyRunning = false
        return
    end

    local pos = getHivePosition(hive)

    if RUN_MODE then
        notify("Улей", "Бегу к " .. hive.Name)
        runTo(pos)
    else
        notify("Улей", "Лечу к " .. hive.Name)
        flyTo(pos)
    end

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
