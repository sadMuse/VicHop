local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local args = {...}  -- аргументы из loadstring(...)("run")

local function detectRunMode()
    -- 1) аргумент: loadstring(...)("run")
    if args[1] == "run" or args[1] == true then return true end

    -- 2) getgenv (общее окружение executor'а)
    local okEnv, env = pcall(function() return getgenv and getgenv() end)
    if okEnv and env and (env.HiveRun == true or env.HiveRun == "run") then
        return true
    end

    -- 3) _G и shared
    if _G.HiveRun == true or (shared and shared.HiveRun == true) then
        return true
    end

    return false
end

local RUN_MODE = detectRunMode()
local RUN_SPEED = 50   -- скорость бега (WalkSpeed)
local FLY_SPEED = 150  -- скорость полёта (studs/сек)

-- защита от двойного запуска
if _G.HiveFlyRunning then
    _G.HiveFlyStop = true
    task.wait(0.3)
end
_G.HiveFlyRunning = true
_G.HiveFlyStop = false

------------------------------------------------------------
-- Кастомные уведомления (liquid glass)
------------------------------------------------------------
local GLASS_TRANSPARENCY = 0.4   -- прозрачность стекла (больше = прозрачнее)
local STROKE_TRANSPARENCY = 0.45

local ACCENTS = {
    ["Ошибка"] = Color3.fromRGB(255, 99, 99),
    ["Упс"]    = Color3.fromRGB(255, 99, 99),
    ["Успех"]  = Color3.fromRGB(110, 231, 160),
}
local DEFAULT_ACCENT = Color3.fromRGB(130, 190, 255)

local notifHolder
local notifOrder = 0

local function getHolder()
    if notifHolder and notifHolder.Parent then return notifHolder end

    if _G.HiveNotifGui then
        pcall(function() _G.HiveNotifGui:Destroy() end)
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "HiveNotifications"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- пробуем gethui -> CoreGui -> PlayerGui
    local okHui, hui = pcall(function() return gethui and gethui() end)
    if okHui and hui then
        pcall(function() gui.Parent = hui end)
    end
    if not gui.Parent then
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
    end
    if not gui.Parent then
        gui.Parent = player:WaitForChild("PlayerGui")
    end
    _G.HiveNotifGui = gui

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.Position = UDim2.new(1, -16, 0, 12)
    holder.Size = UDim2.new(0, 300, 1, -24)
    holder.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = holder

    notifHolder = holder
    return holder
end

local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function notify(title, text, duration)
    duration = duration or 3

    task.spawn(function()
        local ok = pcall(function()
            local holder = getHolder()
            notifOrder += 1

            local wrapper = Instance.new("Frame")
            wrapper.BackgroundTransparency = 1
            wrapper.Size = UDim2.new(1, 0, 0, 66)
            wrapper.LayoutOrder = notifOrder
            wrapper.Parent = holder

            -- стеклянная карточка
            local card = Instance.new("Frame")
            card.BackgroundColor3 = Color3.new(1, 1, 1)
            card.BackgroundTransparency = 1
            card.BorderSizePixel = 0
            card.Size = UDim2.new(1, 0, 1, 0)
            card.Position = UDim2.new(0, 320, 0, 0)
            card.Parent = wrapper

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 18)
            corner.Parent = card

            -- градиент стекла: светлее сверху-слева, темнее снизу-справа
            local glassGradient = Instance.new("UIGradient")
            glassGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 118, 150)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 28, 40)),
            })
            glassGradient.Rotation = 60
            glassGradient.Parent = card

            -- светящаяся обводка с бликами по краям
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.new(1, 1, 1)
            stroke.Thickness = 1.2
            stroke.Transparency = 1
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = card

            local strokeGradient = Instance.new("UIGradient")
            strokeGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.4, 0.75),
                NumberSequenceKeypoint.new(0.6, 0.75),
                NumberSequenceKeypoint.new(1, 0.1),
            })
            strokeGradient.Rotation = 45
            strokeGradient.Parent = stroke

            -- цветная полоска слева
            local pill = Instance.new("Frame")
            pill.BackgroundColor3 = ACCENTS[title] or DEFAULT_ACCENT
            pill.BackgroundTransparency = 1
            pill.BorderSizePixel = 0
            pill.AnchorPoint = Vector2.new(0, 0.5)
            pill.Position = UDim2.new(0, 12, 0.5, 0)
            pill.Size = UDim2.new(0, 4, 0, 34)
            pill.Parent = card

            local pillCorner = Instance.new("UICorner")
            pillCorner.CornerRadius = UDim.new(1, 0)
            pillCorner.Parent = pill

            local titleLabel = Instance.new("TextLabel")
            titleLabel.BackgroundTransparency = 1
            titleLabel.Position = UDim2.new(0, 26, 0, 10)
            titleLabel.Size = UDim2.new(1, -40, 0, 20)
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 15
            titleLabel.TextColor3 = Color3.new(1, 1, 1)
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextTransparency = 1
            titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
            titleLabel.Text = tostring(title)
            titleLabel.Parent = card

            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Position = UDim2.new(0, 26, 0, 31)
            textLabel.Size = UDim2.new(1, -40, 0, 22)
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextSize = 13
            textLabel.TextColor3 = Color3.fromRGB(225, 230, 240)
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.TextTransparency = 1
            textLabel.TextTruncate = Enum.TextTruncate.AtEnd
            textLabel.Text = tostring(text)
            textLabel.Parent = card

            -- появление
            tween(card, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = GLASS_TRANSPARENCY}, 0.4)
            tween(stroke, {Transparency = STROKE_TRANSPARENCY}, 0.4)
            tween(pill, {BackgroundTransparency = 0.05}, 0.4)
            tween(titleLabel, {TextTransparency = 0}, 0.4)
            tween(textLabel, {TextTransparency = 0.05}, 0.4)

            task.wait(duration)

            -- исчезновение
            tween(card, {Position = UDim2.new(0, 320, 0, 0), BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            tween(stroke, {Transparency = 1}, 0.35)
            tween(pill, {BackgroundTransparency = 1}, 0.35)
            tween(titleLabel, {TextTransparency = 1}, 0.35)
            tween(textLabel, {TextTransparency = 1}, 0.35)

            task.wait(0.4)
            wrapper:Destroy()
        end)

        -- если кастомное уведомление не создалось, показываем стандартное
        if not ok then
            pcall(function()
                StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration})
            end)
        end
    end)
end

------------------------------------------------------------
-- Основная логика
------------------------------------------------------------
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

-- Координаты точек назначения для ульев
local HIVE_POSITIONS = {
    [1] = Vector3.new(-3.02, 5.93, 331.00),
    [2] = Vector3.new(-40.13, 5.93, 331.00),
    [3] = Vector3.new(-76.26, 5.93, 331.00),
    [4] = Vector3.new(-112.95, 5.93, 331.00),
    [5] = Vector3.new(-150.17, 5.93, 331.00),
    [6] = Vector3.new(-186.59, 5.93, 331.00),
}

-- Возвращает заданные координаты для Hive 1–6.
-- Если номер улья не распознан или он вне списка, использует позицию из игры.
local function getHivePosition(hive)
    local num = tonumber(tostring(hive.Name):match("%d+"))
    if num and HIVE_POSITIONS[num] then
        return HIVE_POSITIONS[num]
    end

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

-- расстояние по горизонтали
local function flatDist(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Бег к точке через PathfindingService
local function runTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = RUN_SPEED

    local started = tick()

    while not _G.HiveFlyStop and hrp.Parent and tick() - started < 40 do
        if flatDist(hrp.Position, targetPos) < 3 then break end

        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = false,
        })

        local ok = pcall(function()
            path:ComputeAsync(hrp.Position, targetPos)
        end)

        if ok and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()

            for i = 2, #waypoints do
                if _G.HiveFlyStop or not hrp.Parent then break end

                local wp = waypoints[i]
                if wp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end

                hum:MoveTo(wp.Position)

                local t0 = tick()
                local lastPos = hrp.Position
                local lastCheck = tick()
                while tick() - t0 < 2.5 and flatDist(hrp.Position, wp.Position) > 3 do
                    if tick() - lastCheck > 0.6 then
                        if (hrp.Position - lastPos).Magnitude < 1 then
                            hum.Jump = true
                        end
                        lastPos = hrp.Position
                        lastCheck = tick()
                    end
                    task.wait(0.05)
                end

                if flatDist(hrp.Position, wp.Position) > 5 then
                    break
                end
            end
        else
            hum:MoveTo(targetPos)
            local lastPos = hrp.Position
            task.wait(0.6)
            if (hrp.Position - lastPos).Magnitude < 1 then
                hum.Jump = true
            end
        end

        task.wait()
    end

    if hum.Parent then
        hum.WalkSpeed = oldSpeed
    end
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

    notify("Режим", RUN_MODE and "БЕГ" or "ПОЛЁТ")

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
