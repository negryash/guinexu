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
        for _,