-- ============================================================
-- Bee Swarm — Hive Visualizer (Beam Markers)
-- ============================================================
print("🐝 Hive Visualizer - Starting...")

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

-- Папка для маркеров, чтобы их можно было легко удалить
local markerFolder = Instance.new("Folder")
markerFolder.Name = "HiveMarkers"
markerFolder.Parent = workspace

-- Очистка старых маркеров, если скрипт запускали ранее
local oldFolder = workspace:FindFirstChild("HiveMarkers")
if oldFolder then oldFolder:Destroy() end

-- Цвета для лучей
local COLORS = {
    Color3.fromRGB(255, 0, 0),    -- Красный
    Color3.fromRGB(0, 255, 0),    -- Зеленый
    Color3.fromRGB(0, 150, 255),  -- Синий
    Color3.fromRGB(255, 255, 0),  -- Желтый
    Color3.fromRGB(255, 0, 255),  -- Фиолетовый
    Color3.fromRGB(0, 255, 255)   -- Голубой
}

local function createBeamMarker(position, index, name)
    -- 1. Создаем нижнюю точку (на самом улье)
    local bottomPart = Instance.new("Part")
    bottomPart.Name = "Bottom_" .. name
    bottomPart.Size = Vector3.new(2, 2, 2)
    bottomPart.Position = position
    bottomPart.Anchored = true
    bottomPart.CanCollide = false
    bottomPart.Transparency = 0.5
    bottomPart.Color = COLORS[(index % #COLORS) + 1]
    bottomPart.Material = Enum.Material.Neon
    bottomPart.Parent = markerFolder

    -- 2. Создаем верхнюю точку (высоко в небе)
    local topPart = Instance.new("Part")
    topPart.Name = "Top_" .. name
    topPart.Size = Vector3.new(0.5, 0.5, 0.5)
    topPart.Position = position + Vector3.new(0, 150, 0)
    topPart.Anchored = true
    topPart.CanCollide = false
    topPart.Transparency = 1
    topPart.Parent = markerFolder

    -- 3. Создаем точки крепления (Attachments) для луча
    local attBottom = Instance.new("Attachment")
    attBottom.Parent = bottomPart
    
    local attTop = Instance.new("Attachment")
    attTop.Parent = topPart

    -- 4. Создаем сам луч (Beam)
    local beam = Instance.new("Beam")
    beam.Attachment0 = attBottom
    beam.Attachment1 = attTop
    beam.Width0 = 1
    beam.Width1 = 3
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(COLORS[(index % #COLORS) + 1])
    beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(0.2, 0.8) -- Прозрачность от низа к верху
    beam.Parent = bottomPart

    -- 5. Вешаем текст с номером улья
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = bottomPart

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.TextColor3 = COLORS[(index % #COLORS) + 1]
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = billboard
end

-- === Поиск ульев ===
task.wait(2)
print("🔍 Поиск ульев...")

local hiveDeco = workspace:FindFirstChild("HiveDeco")
local canvases = hiveDeco and hiveDeco:FindFirstChild("StickerCanvases")

if canvases then
    local count = 0
    for _, canvas in ipairs(canvases:GetChildren()) do
        local origin = canvas:FindFirstChild("OriginPart")
        if origin then
            count = count + 1
            print("✅ Найден улей:", canvas.Name, "| Позиция:", origin.Position)
            createBeamMarker(origin.Position, count, canvas.Name)
        end
    end
    print("📊 Всего ульев найдено:", count)
else
    warn("❌ Папка StickerCanvases не найдена!")
end

print("🐝 Маркеры установлены. Посмотри в небо!")
