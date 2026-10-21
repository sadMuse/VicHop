local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local args = {...}  -- аргументы из loadstring(...)("run")

local function detectRunMode()
    if args[1] == "run" or args[1] == true then return true end

    local okEnv, env = pcall(function() return getgenv and getgenv() end)
    if okEnv and env and (env.HiveRun == true or env.HiveRun == "run") then
        return true
    end

    if _G.HiveRun == true or (shared and shared.HiveRun == true) then
        return true
    end

    return false
end

local RUN_MODE = detectRunMode()
local RUN_SPEED = 50   -- скорость бега (WalkSpeed)
local FLY_SPEED = 150  -- скорость полёта (studs/сек)

-- защита от двойного запуска (старая копия останавливается и не берёт улей)
if _G.HiveFlyRunning then
    _G.HiveFlyStop = true
    task.wait(0.3)
end
_G.HiveFlyRunning = true
_G.HiveFlyStop = false
_G.HiveRunId = (_G.HiveRunId or 0) + 1
local MY_RUN_ID = _G.HiveRunId

local function isStale()
    return _G.HiveRunId ~= MY_RUN_ID
end

-- статус для меню
local hiveStatus = "запуск..."
local hiveTarget = "-"

------------------------------------------------------------
-- Кастомные уведомления (liquid glass)
------------------------------------------------------------
local GLASS_TRANSPARENCY = 0.4
local STROKE_TRANSPARENCY = 0.45

local ACCENTS = {
    ["Ошибка"] = Color3.fromRGB(255, 99, 99),
    ["Упс"]    = Color3.fromRGB(255, 99, 99),
    ["Успех"]  = Color3.fromRGB(110, 231, 160),
}
local DEFAULT_ACCENT = Color3.fromRGB(130, 190, 255)

local notifHolder
local notifOrder = 0

-- parent для GUI: gethui -> CoreGui -> PlayerGui
local function parentGui(gui)
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
end

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
    parentGui(gui)
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

            local glassGradient = Instance.new("UIGradient")
            glassGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 118, 150)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 28, 40)),
            })
            glassGradient.Rotation = 60
            glassGradient.Parent = card

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

            tween(card, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = GLASS_TRANSPARENCY}, 0.4)
            tween(stroke, {Transparency = STROKE_TRANSPARENCY}, 0.4)
            tween(pill, {BackgroundTransparency = 0.05}, 0.4)
            tween(titleLabel, {TextTransparency = 0}, 0.4)
            tween(textLabel, {TextTransparency = 0.05}, 0.4)

            task.wait(duration)

            tween(card, {Position = UDim2.new(0, 320, 0, 0), BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            tween(stroke, {Transparency = 1}, 0.35)
            tween(pill, {BackgroundTransparency = 1}, 0.35)
            tween(titleLabel, {TextTransparency = 1}, 0.35)
            tween(textLabel, {TextTransparency = 1}, 0.35)

            task.wait(0.4)
            wrapper:Destroy()
        end)

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

local HIVE_POSITIONS = {
    [1] = Vector3.new(-3.02, 5.93, 331.00),
    [2] = Vector3.new(-40.13, 5.93, 331.00),
    [3] = Vector3.new(-76.26, 5.93, 331.00),
    [4] = Vector3.new(-112.95, 5.93, 331.00),
    [5] = Vector3.new(-150.17, 5.93, 331.00),
    [6] = Vector3.new(-186.59, 5.93, 331.00),
}

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

-- Уже есть мой улей?
local function findOwnedHive()
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return nil end
    for _, hive in ipairs(honeycombs:GetChildren()) do
        local owner = hive:FindFirstChild("Owner")
        if owner and owner.Value == player then
            return hive
        end
    end
    return nil
end

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

    if hrp.Parent and not _G.HiveFlyStop then
        hrp.CFrame = CFrame.new(dest)
    end

    conn:Disconnect()
    noclip:Disconnect()
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local function flatDist(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

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

------------------------------------------------------------
-- HIVE MENU
------------------------------------------------------------
if _G.HiveMenuGui then
    pcall(function() _G.HiveMenuGui:Destroy() end)
end

local okMenu, menuErr = pcall(function()
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "HiveMenu"
    menuGui.ResetOnSpawn = false
    menuGui.IgnoreGuiInset = true
    menuGui.DisplayOrder = 1000
    menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentGui(menuGui)
    _G.HiveMenuGui = menuGui

    local BG = Color3.fromRGB(17, 18, 25)
    local PANEL = Color3.fromRGB(24, 25, 35)
    local ACCENT = Color3.fromRGB(155, 112, 255)
    local FG = Color3.fromRGB(239, 239, 248)
    local MUTED = Color3.fromRGB(151, 153, 173)

    local function create(class, props, parent)
        local obj = Instance.new(class)
        for key, value in pairs(props) do
            obj[key] = value
        end
        obj.Parent = parent
        return obj
    end

    local function corner(obj, radius)
        create("UICorner", {CornerRadius = UDim.new(0, radius)}, obj)
    end

    local function label(parent, text, size, position, dimensions, color)
        return create("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = size,
            TextColor3 = color or FG,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Position = position,
            Size = dimensions,
            TextWrapped = true
        }, parent)
    end

    -- надёжный клик (мышь и тач), не зависит от Activated
    local function onClick(btn, fn)
        local down, startPos = false, nil
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                down = true
                startPos = input.Position
            end
        end)
        btn.InputEnded:Connect(function(input)
            if down and (input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch) then
                down = false
                if (input.Position - startPos).Magnitude < 10 then
                    fn()
                end
            end
        end)
    end

    local window = create("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 660, 0, 410),
        Position = UDim2.new(0.5, -330, 0.5, -205),
        BackgroundColor3 = BG,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, menuGui)
    corner(window, 14)

    create("UIStroke", {
        Color = ACCENT,
        Transparency = 0.55,
        Thickness = 1.2
    }, window)

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0
    }, window)
    corner(header, 14)

    label(header, "HIVE", 20, UDim2.new(0, 18, 0, 0), UDim2.new(0, 90, 1, 0), ACCENT)
    label(header, "AUTOMATION PANEL", 10, UDim2.new(0, 84, 0, 2), UDim2.new(0, 200, 1, 0), MUTED)

    local close = create("TextButton", {
        Text = "×",
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = FG,
        BackgroundColor3 = BG,
        Size = UDim2.new(0, 36, 0, 34),
        Position = UDim2.new(1, -45, 0, 10),
        BorderSizePixel = 0
    }, header)
    corner(close, 9)

    local sidebar = create("ScrollingFrame", {
        Position = UDim2.new(0, 10, 0, 65),
        Size = UDim2.new(0, 166, 1, -76),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, window)
    corner(sidebar, 10)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 8)
    }, sidebar)

    create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, sidebar)

    local content = create("Frame", {
        Position = UDim2.new(0, 188, 0, 65),
        Size = UDim2.new(1, -198, 1, -76),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0
    }, window)
    corner(content, 10)

    local pages = {}
    local navButtons = {}
    local liveLabels = {} -- {label, fn}: обновляются раз в секунду

    local modeText = RUN_MODE and "RUN" or "FLY"

    -- элемент = строка или функция, возвращающая строку (живое обновление)
    local sections = {
        Home = {
            "Dashboard",
            function() return "Hive claim: " .. hiveStatus end,
            function() return "Target hive: " .. hiveTarget end,
            "Movement mode: " .. modeText,
            "Use the floating H button to toggle this menu."
        },
        Farming = {"Farming settings", "Farming controls are not connected yet."},
        Combat = {"Combat settings", "Combat controls are not connected yet."},
        Quests = {"Quest settings", "Quest automation is not connected yet."},
        Planters = {"Planter settings", "Planter controls are not connected yet."},
        Toys = {"Toy settings", "Toy automation is not connected yet."},
        RBC = {"RBC settings", "RBC controls are not connected yet."},
        Webhook = {"Webhook configuration", "Webhook URL: not configured"},
        ["Tg Bot"] = {"Telegram bot configuration", "Bot token and chat ID: not configured"},
        Config = {
            "Configuration",
            "Current movement mode: " .. modeText,
            "Change the mode through the script arguments."
        },
        Debug = {
            "Debug console",
            function() return "HiveFlyRunning: " .. tostring(_G.HiveFlyRunning) end,
            function() return "HiveFlyStop: " .. tostring(_G.HiveFlyStop) end,
            function() return "HiveRun: " .. tostring(RUN_MODE) end
        }
    }

    local function showPage(name)
        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end
        for buttonName, button in pairs(navButtons) do
            button.BackgroundColor3 = buttonName == name and ACCENT or BG
            button.TextColor3 = buttonName == name and Color3.new(1, 1, 1) or MUTED
        end
    end

    for index, name in ipairs({
        "Home", "Farming", "Combat", "Quests", "Planters",
        "Toys", "RBC", "Webhook", "Tg Bot", "Config", "Debug"
    }) do
        local nav = create("TextButton", {
            Name = name .. "Button",
            Text = "   " .. name,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = MUTED,
            BackgroundColor3 = BG,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = index,
            AutoButtonColor = true
        }, sidebar)
        corner(nav, 7)
        navButtons[name] = nav

        local page = create("ScrollingFrame", {
            Name = name .. "Page",
            Visible = false,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = ACCENT,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, content)
        pages[name] = page

        create("UIPadding", {
            PaddingTop = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 12)
        }, page)

        create("UIListLayout", {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, page)

        local title = label(page, name, 20, UDim2.new(), UDim2.new(1, 0, 0, 32), FG)
        title.LayoutOrder = 0

        for itemIndex, item in ipairs(sections[name]) do
            local isFn = type(item) == "function"
            local text = isFn and item() or item

            local card = create("Frame", {
                BackgroundColor3 = BG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 42),
                LayoutOrder = itemIndex
            }, page)
            corner(card, 8)

            local lbl = label(card, text, 11,
                UDim2.new(0, 10, 0, 3),
                UDim2.new(1, -20, 1, -6),
                itemIndex == 1 and ACCENT or MUTED)

            if isFn then
                table.insert(liveLabels, {lbl, item})
            end
        end

        onClick(nav, function()
            showPage(name)
        end)
    end

    showPage("Home")

    local toggle = create("TextButton", {
        Name = "MobileToggle",
        Text = "H",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Size = UDim2.new(0, 52, 0, 52),
        Position = UDim2.new(1, -72, 0.5, -26),
        ZIndex = 10
    }, menuGui)
    corner(toggle, 26)

    local function toggleMenu()
        window.Visible = not window.Visible
    end

    -- кнопка H: клик = открыть/закрыть, перетаскивание = двигать кнопку
    local tDragging, tMoved = false, false
    local tInput, tStart, tStartPos

    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            tDragging = true
            tMoved = false
            tInput = input
            tStart = input.Position
            tStartPos = toggle.Position
        end
    end)

    toggle.InputEnded:Connect(function(input)
        if input == tInput then
            tDragging = false
            tInput = nil
            if not tMoved then
                toggleMenu()
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not tDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - tStart
            if delta.Magnitude > 6 then
                tMoved = true
            end
            if tMoved then
                toggle.Position = UDim2.new(
                    tStartPos.X.Scale, tStartPos.X.Offset + delta.X,
                    tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    onClick(close, function()
        window.Visible = false
    end)

    -- клавиша RightShift на ПК
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightShift then
            toggleMenu()
        end
    end)

    -- перетаскивание окна за шапку (мышь и тач)
    local dragging = false
    local dragInput, dragStart, startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position
            dragInput = input
        end
    end)

    header.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            dragInput = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    -- живое обновление статусных карточек
    task.spawn(function()
        while menuGui.Parent do
            for _, entry in ipairs(liveLabels) do
                pcall(function() entry[1].Text = entry[2]() end)
            end
            task.wait(1)
        end
    end)
end)

if okMenu then
    notify("Успех", "Hive Menu загружено", 3)
else
    warn("[HiveMenu] Не удалось создать меню: " .. tostring(menuErr))
end

------------------------------------------------------------
-- Взятие улья: ровно один раз при запуске
------------------------------------------------------------
task.spawn(function()
    task.wait(2)
    if isStale() then return end

    local function finish(status)
        hiveStatus = status
        if not isStale() then
            _G.HiveFlyRunning = false
        end
    end

    -- улей уже занят нами: ничего не делаем
    local owned = findOwnedHive()
    if owned then
        hiveTarget = owned.Name
        notify("Улей", "У тебя уже есть " .. owned.Name)
        finish("уже занят (" .. owned.Name .. ")")
        return
    end

    local events = ReplicatedStorage:WaitForChild("Events", 10)
    local claim = events and events:FindFirstChild("ClaimHive")
    if not claim then
        notify("Ошибка", "ClaimHive не найден")
        finish("ClaimHive не найден")
        return
    end

    local hive, num = findNearestFreeHive()
    if not hive then
        notify("Ошибка", "Свободных ульев нет")
        finish("нет свободных ульев")
        return
    end

    hiveTarget = hive.Name
    local pos = getHivePosition(hive)

    notify("Режим", RUN_MODE and "БЕГ" or "ПОЛЁТ")

    if RUN_MODE then
        hiveStatus = "бегу к " .. hive.Name
        notify("Улей", "Бегу к " .. hive.Name)
        runTo(pos)
    else
        hiveStatus = "лечу к " .. hive.Name
        notify("Улей", "Лечу к " .. hive.Name)
        flyTo(pos)
    end

    -- запуск был перезапущен или остановлен: улей не берём
    if isStale() or _G.HiveFlyStop then
        return
    end

    -- улей мог занять кто-то другой, пока мы летели
    local ownerNow = hive:FindFirstChild("Owner")
    if ownerNow and ownerNow.Value ~= nil and ownerNow.Value ~= player then
        notify("Упс", hive.Name .. " уже занят другим игроком")
        finish("улей занят другим")
        return
    end

    claim:FireServer(num) -- единственный вызов ClaimHive

    task.wait(1)
    local owner = hive:FindFirstChild("Owner")
    if owner and owner.Value == player then
        notify("Успех", "Улей " .. hive.Name .. " занят")
        finish("занят (" .. hive.Name .. ")")
    else
        notify("Упс", "Не получилось занять " .. hive.Name)
        finish("не удалось занять " .. hive.Name)
    end
end)
