lib.versionCheck('Qbox-project/qbx_spawn')


AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if player then
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local citizenid = player.PlayerData.citizenid


        if math.abs(coords.x) < 1.0 and math.abs(coords.y) < 1.0 then return end

        local newPos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            a = heading or 0.0
        }


        MySQL.update.await('UPDATE players SET position = ? WHERE citizenid = ?', {
            json.encode(newPos),
            citizenid
        })

        print('^2[qbx_spawn] Force Saved to DB: ' .. citizenid .. '^0')
    end
end)


lib.callback.register('qbx_spawn:server:getLastLocation', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local citizenid = player.PlayerData.citizenid


    local result = MySQL.single.await('SELECT position FROM players WHERE citizenid = ?', { citizenid })

    if result and result.position then
        local pos = json.decode(result.position)
        return pos
    else
        return nil
    end
end)


RegisterCommand('manualsave', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if player then
        player.Functions.Save()
        TriggerClientEvent('ox_lib:notify', source, {type = 'success', description = 'Player Data Saved to SQL'})
    end
end, false)