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
