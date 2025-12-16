local config = require 'config.client'
local QBCore = exports['qb-core']:GetCoreObject() 
local previewCam = nil


local JailSpawn = vector4(722.7174, 152.5656, 80.7546, 149.8554)
local JailMeta = 'jail_tickets' 

local function stopCamera()
    if previewCam then
        SetCamActive(previewCam, false)
        DestroyCam(previewCam, true)
        RenderScriptCams(false, false, 1, true, true)
        previewCam = nil
    end
end

local function setupCamera()
    if previewCam then return end
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', -45.4222, 158.9362, 149.8228, 0.0, 0.0, 150.0, 60.0, false, 2)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 1, true, true)
end

local function managePlayer()
    local ped = PlayerPedId()
    

    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, 0.0, true, false)
    end
    SetEntityHealth(ped, 200)


    SetEntityCoords(ped, -45.4222, 158.9362, 149.8228, false, false, false, false)
    DisplayRadar(false)
    
    SetTimeout(500, function()
        DoScreenFadeIn(1000)
    end)
end

local function spawnPlayer(spawnData)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end

    stopCamera()


    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    
    local ped = PlayerPedId()


    SetEntityCoords(ped, spawnData.coords.x, spawnData.coords.y, spawnData.coords.z, false, false, false, false)
    

    local heading = spawnData.coords.w or 0.0
    SetEntityHeading(ped, heading)
    

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)

    DisplayRadar(true)
    Wait(500)
    DoScreenFadeIn(1000)


    TriggerEvent('playerSpawned')
end

RegisterNetEvent('qb-spawn:client:setupSpawns', function()

    local PlayerData = QBCore.Functions.GetPlayerData()
    local tickets = PlayerData.metadata[JailMeta] or 0
    local oldTime = PlayerData.metadata['injail'] or 0


    if tickets > 0 or oldTime > 0 then
        print('^1[Spawn] Player is jailed. Forcing prison spawn.^0')
        spawnPlayer({ coords = JailSpawn })
        

        SetTimeout(2000, function()
            TriggerEvent('synapse_jail:client:forceJailPos')
        end)
        return
    end


    local spawns = {}


    local lastCoords = lib.callback.await('qbx_spawn:server:getLastLocation')
    
    if lastCoords then
        spawns[#spawns + 1] = {
            label = locale('last_location'),
            coords = lastCoords,
            isLastLocation = true
        }
    end


    for i = 1, #config.spawns do
        spawns[#spawns + 1] = config.spawns[i]
    end

    managePlayer()
    setupCamera()


    local options = {}
    
    for i = 1, #spawns do
        local spawn = spawns[i]
        local description = 'Spawn at this location'
        local icon = 'map-pin'

        if spawn.isLastLocation then
            description = 'Return to your exact previous position'
            icon = 'clock-rotate-left'
        end

        options[#options+1] = {
            title = spawn.label,
            description = description,
            icon = icon,
            onSelect = function()
                spawnPlayer(spawn)
            end
        }
    end

    lib.registerContext({
        id = 'spawn_selection_menu',
        title = 'Select Spawn Location',
        canClose = false,
        options = options
    })

    lib.showContext('spawn_selection_menu')
end)