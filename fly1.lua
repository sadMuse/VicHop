-- Hive automation + menu (reconstructed combined build)
-- Use only in environments where client-side Lua execution is permitted.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local args = {...}

local function detectRunMode()
    if args[1] == "run" or args[1] == true then return true end
    local okEnv, env = pcall(function() return getgenv and getgenv() end)
    if okEnv and env and (env.HiveRun == true or env.HiveRun == "run") then return true end
    if _G.HiveRun == true then return true end
    local okShared, sharedRun = pcall(function() return shared and shared.HiveRun == true end)
    if okShared and sharedRun then return true end
    return false
end

local RUN_MODE = detectRunMode()
local RUN_SPEED = 50
local FLY_SPEED = 150

if _G.HiveFlyRunning then
    _G.HiveFlyStop = true
    task.wait(0.3)
end
_G.HiveFlyRunning = true
_G.HiveFlyStop = false

local BG = Color3.fromRGB(16, 18, 27)
local PANEL = Color3.fromRGB(25, 29, 42)
local FG = Color3.fromRGB(235, 239, 249)
local MUTED = Color3.fromRGB(151, 161, 184)
local ACCENT = Color3.fromRGB(93, 113, 255)

local function make(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    if parent then object.Parent = parent end
    return object
end

local function round(object, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, object)
end

local function text(parent, value, size, color, position, dimensions, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value),
        Font = font or Enum.Font.Gotham,
        TextSize = size or 12,
        TextColor3 = color or FG,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        Position = position or UDim2.new(),
        Size = dimensions or UDim2.new(1, 0, 0, 24),
    }, parent)
end

local notifGui
local function notify(title, message, duration)
    duration = duration or 3
    pcall(function()
        if not notifGui or not notifGui.Parent then
            notifGui = make("ScreenGui", {
                Name = "HiveNotifications", ResetOnSpawn = false,
                IgnoreGuiInset = true, DisplayOrder = 999,
            })
            local ok, hui = pcall(function() return gethui and gethui() end)
            if ok and hui then
                notifGui.Parent = hui
            else
                notifGui.Parent = player:WaitForChild("PlayerGui")
            end
        end
        local card = make("Frame", {
            BackgroundColor3 = PANEL, BackgroundTransparency = 0.08,
            BorderSizePixel = 0, Size = UDim2.new(0, 290, 0, 62),
            Position = UDim2.new(1, 310, 0, 14),
        }, notifGui)
        round(card, 12)
        make("UIStroke", {Color = ACCENT, Transparency = 0.25, Thickness = 1}, card)
        text(card, title, 14, ACCENT, UDim2.new(0, 12, 0, 5), UDim2.new(1, -24, 0, 22), Enum.Font.GothamBold)
        text(card, message, 12, FG, UDim2.new(0, 12, 0, 28), UDim2.new(1, -24, 0, 27))
        TweenService:Create(card, TweenInfo.new(0.25), {Position = UDim2.new(1, -306, 0, 14)}):Play()
        task.delay(duration, function()
            if card and card.Parent then
                local t = TweenService:Create(card, TweenInfo.new(0.25), {Position = UDim2.new(1, 310, 0, 14), BackgroundTransparency = 1})
                t:Play(); t.Completed:Wait()
                if card then card:Destroy() end
            end
        end)
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = tostring(title), Text = tostring(message), Duration = duration})
    end)
end

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
    if num and HIVE_POSITIONS[num] then return HIVE_POSITIONS[num] end
    local arrow = hive:FindFirstChild("localpatharrow")
    if arrow then
        if arrow:IsA("Model") then local cf = arrow:GetBoundingBox(); return cf.Position end
