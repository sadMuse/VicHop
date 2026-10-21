-- ============================================================
-- Secret X💢 — Vicious Bee Killer (Cannon Flight Edition)
-- Made by restless (patched by VANTA)
-- ============================================================
print("🐝 Vicious Bee Killer - Starting...")

local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local StarterGui      = game:GetService("StarterGui")

local player = Players.LocalPlayer

pcall(function()
    for _, v in pairs(getconnections(player.Idled)) do v:Disable() end
end)

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
    end)
end

local function getHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function waitForCharacter()
    if not player.Character then player.CharacterAdded:Wait() end
    local char = player.Character
    char:WaitForChild("HumanoidRootPart", 15)
    char:WaitForChild("Humanoid", 15)
    task.wait(1)
end

-- === 1. Поиск свободного улья ===
local function findFreeHive()
    local hives = workspace:FindFirstChild("HiveDeco") and workspace.HiveDeco:FindFirstChild("Hives")
    if not hives then return nil end
    
    for _, hive in ipairs(hives:GetChildren()) do
        -- Проверка: улей свободен, если на нём нет таблички "Claimed" или цвет не красный
        local isClaimed = false
        for _, child in ipairs(hive:GetDescendants()) do
            if child:IsA("TextLabel") and (child.Text:find("Claimed") or child.Text:find("Owned")) then
                isClaimed = true
                break
            end
            if child:IsA("BasePart") and child.Color == Color3.fromRGB(255, 0, 0) then -- пример цвета занятого
                isClaimed = true
                break
            end
        end
        
        if not isClaimed then
            local origin = hive:FindFirstChild("OriginPart") or hive.PrimaryPart
            if origin then return origin end
        end
    end
    return nil
end

-- === 2. Поиск пушки ===
local function findCannon()
    -- Ищем пушки в Workspace (Cannon, Launcher, Pult)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:find("Cannon") or v.Name:find("Launcher") or v.Name:find("Pult")) then
            return v
        end
    end
    return nil
end

-- === 3. Полёт к улью ===
local function flyToHive(targetPos)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    local cannon = findCannon()
    if cannon then
        notify("Secret X💢", "💥 Пушка найдена! Летим...")
        -- Телепорт к пушке
        hrp.CFrame = cannon.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.5)
        
        -- Выстрел: наводим камеру/персонажа на улей и даем импульс
        local dir = (targetPos - hrp.Position).Unit
        hrp.Velocity = dir * 150 + Vector3.new(0, 50, 0) -- Импульс вверх и в сторону
    else
        notify("Secret X💢", "⚠️ Пушка не найдена. Прыгаем вручную...")
        -- Если пушки нет, используем Velocity (BodyVelocity)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = (targetPos - hrp.Position).Unit * 150 + Vector3.new(0, 50, 0)
        bv.Parent = hrp
        task.wait(1)
        bv:Destroy()
    end
end

-- === 4. Основная логика (из прошлого кода) ===
local function findThorn()
    local wts = workspace:FindFirstChild("Particles") and workspace.Particles:FindFirstChild("WTs")
    if not wts then return nil end
    for _, v in ipairs(wts:GetChildren()) do
        if v.Name == "WaitingThorn" then return v end
    end
    return nil
end

local function findVicious()
    local monsters = workspace:FindFirstChild("Monsters")
    if not monsters then return nil end
    for _, v in ipairs(monsters:GetChildren()) do
        if v.Name:find("Vicious Bee") then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return v end
        end
    end
    return nil
end

local function followAndKillVicious()
    print("⚔️ Following Vicious Bee...")
    notify("Secret X💢", "⚔️ Vicious Bee found! Following...")

    local vic = findVicious()
    if not vic then return end
    task.wait(2)
    vic = findVicious()
    if not vic then return end

    local vicRoot = vic:FindFirstChild("HumanoidRootPart") or vic.PrimaryPart
    if not vicRoot then return end

    local platform = Instance.new("Part")
    platform.Size = Vector3.new(100, 1, 100)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Parent = workspace
    platform.CFrame = vicRoot.CFrame + Vector3.new(0, 8, 0)

    task.wait(0.1)
    local hrp = getHRP()
    if hrp then hrp.CFrame = platform.CFrame + Vector3.new(0, 3, 0) end

    local moveConn = RunService.Heartbeat:Connect(function()
        if not vicRoot or not vicRoot.Parent then return end
        platform.CFrame = CFrame.new(vicRoot.Position + Vector3.new(0, 8, 0))
        local h = getHumanoid()
        if h then
            local targetOnPlat = Vector3.new(vicRoot.Position.X, platform.Position.Y + 2, vicRoot.Position.Z)
            h:MoveTo(targetOnPlat)
        end
    end)

    while true do
        task.wait(0.5)
        local hum = getHumanoid()
        if not hum or hum.Health <= 0 then
            moveConn:Disconnect()
            platform:Destroy()
            notify("Secret X💢", "💀 Died — respawning...")
            waitForCharacter()
            task.wait(1)
            followAndKillVicious()
            return
        end
        if not findVicious() then
            moveConn:Disconnect()
            platform:Destroy()
            notify("Secret X💢", "✅ Vicious Bee killed! Waiting for respawn...")
            task.wait(5)
            main()
            return
        end
    end
end

function main()
    waitForCharacter()
    for i = 5, 1, -1 do
        notify("Secret X💢", "⏳ Scanning in " .. i .. " seconds...")
        task.wait(1)
    end
    notify("Secret X💢", "🔍 Scanning now!")

    while true do
        task.wait(1)
        local vic = findVicious()
        if vic then
            -- Если видим моба, просто убиваем его (улей можно потом)
            followAndKillVicious()
            return
        end
        
        local thorn = findThorn()
        if thorn then
            notify("Secret X💢", "🌵 Thorn found! Claiming free hive...")
            
            local freeHive = findFreeHive()
            if freeHive then
                notify("Secret X💢", "🏠 Свободный улей найден! Летим...")
                flyToHive(freeHive.Position)
                task.wait(2)
                
                -- Если долетели, клеймим (на всякий случай)
                local ClaimHive = game:GetService("ReplicatedStorage"):FindFirstChild("Events") and game:GetService("ReplicatedStorage").Events:FindFirstChild("ClaimHive")
                if ClaimHive then
                    ClaimHive:FireServer(1) -- допустим, 1
                end
            else
                notify("Secret X💢", "⚠️ Свободных ульев нет. Ждем...")
            end
            
            -- Телепорт к кусту и ожидание моба
            local hrp = getHRP()
            if hrp then hrp.CFrame = CFrame.new(thorn.Position + Vector3.new(0, 5, 0)) end
            task.wait(1)
            
            local spawnTimeout = tick()
            local spawned = false
            while tick() - spawnTimeout < 15 do
                task.wait(0.3)
                local v = findVicious()
                if v then spawned = true break end
            end
            if spawned then
                followAndKillVicious()
            else
                notify("Secret X💢", "⚠️ Vicious didn't spawn, re-scanning...")
                task.wait(5)
            end
        else
            notify("Secret X💢", "❌ Nothing found, re-scanning...")
            task.wait(5)
        end
    end
end

task.spawn(main)
print("🐝 Loaded!")
