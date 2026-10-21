    text(header,"AUTOMATION PANEL",10,MUTED,UDim2.new(0,84,0,0),UDim2.new(0,200,1,0))
    local close = make("TextButton", {Text="×", Font=Enum.Font.GothamBold, TextSize=24, TextColor3=FG,
        BackgroundColor3=BG, Size=UDim2.new(0,36,0,34), Position=UDim2.new(1,-45,0,10), BorderSizePixel=0}, header)
    round(close,9)
    local sidebar = make("ScrollingFrame", {Position=UDim2.new(0,10,0,65), Size=UDim2.new(0,166,1,-76),
        BackgroundColor3=PANEL, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=ACCENT,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y}, window)
    round(sidebar,10)
    make("UIPadding", {PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)}, sidebar)
    make("UIListLayout", {Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder}, sidebar)
    local content = make("Frame", {Position=UDim2.new(0,188,0,65),Size=UDim2.new(1,-198,1,-76),
        BackgroundColor3=PANEL,BorderSizePixel=0},window)
    round(content,10)
    local names = {"Home","Farming","Combat","Quests","Planters","Toys","RBC","Webhook","Tg Bot","Config","Debug"}
    local descriptions = {
        Home={"Dashboard","Status: running","Hive claim: handled by startup routine"},
        Farming={"Farming settings","Not connected to farming logic yet."},
        Combat={"Combat settings","Not connected to combat logic yet."},
        Quests={"Quest settings","Not connected to quest logic yet."},
        Planters={"Planter settings","Not connected to planter logic yet."},
        Toys={"Toy settings","Not connected to toy logic yet."},
        RBC={"RBC settings","Not connected to RBC logic yet."},
        Webhook={"Webhook configuration","Webhook URL is not configured."},
        ["Tg Bot"]={"Telegram bot configuration","Bot token/chat ID are not configured."},
        Config={"Configuration","Mode: "..(RUN_MODE and "RUN" or "FLY"),"Pass \"run\" to enable running mode."},
        Debug={"Debug console","HiveFlyRunning: "..tostring(_G.HiveFlyRunning),"HiveFlyStop: "..tostring(_G.HiveFlyStop),"HiveRun: "..tostring(_G.HiveRun)}
    }
    local pages, navButtons = {}, {}
    local function showPage(name)
        for n,p in pairs(pages) do p.Visible = (n == name) end
        for n,b in pairs(navButtons) do
            b.BackgroundColor3 = n == name and ACCENT or BG
            b.TextColor3 = n == name and Color3.new(1,1,1) or MUTED
        end
    end
    for index,name in ipairs(names) do
        local nav = make("TextButton", {Text="  "..name, Font=Enum.Font.GothamMedium, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, TextColor3=MUTED, BackgroundColor3=BG,
            BorderSizePixel=0, Size=UDim2.new(1,0,0,30), LayoutOrder=index}, sidebar)
        round(nav,7); navButtons[name] = nav
        local page = make("ScrollingFrame", {Name=name.."Page",Visible=false,Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=ACCENT,
            CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},content)
        pages[name] = page
        make("UIPadding", {PaddingTop=UDim.new(0,15),PaddingLeft=UDim.new(0,15),PaddingRight=UDim.new(0,15),PaddingBottom=UDim.new(0,12)},page)
        make("UIListLayout", {Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},page)
        text(page,name,20,FG,UDim2.new(),UDim2.new(1,0,0,32),Enum.Font.GothamBold)
        for i,description in ipairs(descriptions[name]) do
            local card = make("Frame", {BackgroundColor3=BG,BorderSizePixel=0,Size=UDim2.new(1,0,0,42),LayoutOrder=i},page)
            round(card,8)
            text(card,description,11,i==1 and ACCENT or MUTED,UDim2.new(0,10,0,3),UDim2.new(1,-20,1,-6))
        end
        nav.Activated:Connect(function() showPage(name) end)
    end
    showPage("Home")
    local toggle = make("TextButton", {Name="MobileToggle",Text="H",Font=Enum.Font.GothamBold,TextSize=20,
        TextColor3=Color3.new(1,1,1),BackgroundColor3=ACCENT,BorderSizePixel=0,Size=UDim2.new(0,52,0,52),
        Position=UDim2.new(1,-72,0.5,-26),Active=true,Draggable=true},gui)
    round(toggle,26)
    toggle.Activated:Connect(function() window.Visible = not window.Visible end)
    close.Activated:Connect(function() window.Visible = false end)

    -- Touch/mouse drag on header
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragInput, dragStart, startPos = true, input, input.Position, window.Position
        end
    end)
    header.InputEnded:Connect(function(input) if input == dragInput then dragging = false; dragInput = nil end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    task.spawn(function()
        while gui.Parent do
            task.wait(2)
            if pages.Debug and pages.Debug.Visible then
                -- Debug page is a snapshot; refresh its status cards
                for _, child in ipairs(pages.Debug:GetChildren()) do
                    if child:IsA("Frame") then
                        local lbl = child:FindFirstChildOfClass("TextLabel")
                        if lbl and lbl.Text:find("HiveFlyRunning:") then lbl.Text = "HiveFlyRunning: "..tostring(_G.HiveFlyRunning) end
                        if lbl and lbl.Text:find("HiveFlyStop:") then lbl.Text = "HiveFlyStop: "..tostring(_G.HiveFlyStop) end
                    end
                end
            end
        end
    end)
end

createMenu()
notify("Успех", "Hive Menu загружено", 3)

-- Auto claim: preserve existing startup behavior
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
    if RUN_MODE then notify("Улей", "Бегу к "..hive.Name); runTo(pos)
    else notify("Улей", "Лечу к "..hive.Name); flyTo(pos) end
    claim:FireServer(num)
    task.wait(1)
    local owner = hive:FindFirstChild("Owner")
    if owner and owner.Value == player then notify("Успех", "Улей "..hive.Name.." занят")
    else notify("Упс", "Не получилось занять "..hive.Name) end
    _G.HiveFlyRunning = false
end)
