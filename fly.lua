local player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function notify(t, x)
    pcall(function() StarterGui:SetCore("SendNotification", {Title=t, Text=x, Duration=3}) end)
end

local function getHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function findFreeHive()
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return nil end

    for _, hive in ipairs(honeycombs:GetChildren()) do
        -- Если у улья есть локальная стрелка, значит он свободен
        local arrow = hive:FindFirstChild("localpatharrow")
        if arrow then
            -- Пытаемся достать позицию из стрелки
            local targetPos = nil
            
            if arrow:IsA("Beam") and arrow.Attachment1 then
                targetPos = arrow.Attachment1.WorldPosition
            elseif arrow:IsA("Attachment") then
                targetPos = arrow.WorldPosition
            elseif arrow:IsA("BasePart") then
                targetPos = arrow.Position
            else
                -- Если стрелка это не часть и не Beam, берем позицию самого улья
                -- Ищем внутри улья что-то, что указывает на центр
                local origin = hive:FindFirstChild("OriginPart") or hive.PrimaryPart
                if origin then targetPos = origin.Position end
            end

            -- Если нашли координату, возвращаем её и имя улья
            if targetPos then
                return targetPos, hive.Name
            end
        end
    end
    return nil
end

local function fly(pos)
    local hrp = getHRP()
    if not hrp then return end
    
    -- Ищем пушку
    local b = nil
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("bazooka") or v.Name:lower():find("cannon") or v.Name:lower():find("pult")) then
            b = v break
        end
    end
    
    notify("Flight", "🚀 Летим к улью...")
    if b then
        hrp.CFrame = b.CFrame + Vector3.new(0,5,0)
        task.wait(0.5)
        hrp.Velocity = (pos - hrp.Position).Unit * 180 + Vector3.new(0, 60, 0)
    else
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = (pos - hrp.Position).Unit * 180 + Vector3.new(0, 60, 0)
        bv.Parent = hrp
        local t = tick()
        while tick() - t < 3 do
            task.wait(0.1)
            if (hrp.Position - pos).Magnitude < 10 then break end
            bv.Velocity = (pos - hrp.Position).Unit * 180 + Vector3.new(0, 60, 0)
        end
        bv:Destroy()
    end
end

task.spawn(function()
    task.wait(2)
    
    local pos, hiveName = findFreeHive()
    
    if pos then
        notify("Scan", "✅ Найден свободный: " .. hiveName)
        fly(pos)
        task.wait(1.5)
        
        -- Отправляем клейм. Номер улья берём из имени (Hive1 = 1, Hive2 = 2)
        local hiveIndex = tonumber(hiveName:match("%d+")) or 1
        local ev = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ClaimHive")
        if ev then
            ev:FireServer(hiveIndex)
            notify("Claim", "🔨 Клейм отправлен: " .. hiveIndex)
        end
    else
        notify("Scan", "⚠️ Свободных ульев нет.")
    end
end)
