-- Whitelist for admins
local adminWhitelist = {
    "steam:110000112345678", -- Replace with actual Steam IDs
    "steam:110000112345679"
}

-- Check if a player is an admin
local function isAdmin(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, id in ipairs(identifiers) do
        if adminWhitelist[id] then
            return true
        end
    end
    return false
end

-- Helper function to check if a player is an admin
function IsAdmin(steamID)
    for _, adminID in ipairs(config.adminSteamIDs) do
        if steamID == adminID then
            return true
        end
    end
    return false
end

-- Logging system
local function logToDiscord(reason, playerId, extraData)
    local webhookUrl = "https://your-discord-webhook-url" -- Replace with your Discord webhook URL
    local playerName = GetPlayerName(playerId)
    local message = {
        {
            ["color"] = 16711680,
            ["title"] = "Anti-Cheat Alert",
            ["description"] = "Player: " .. playerName .. "\nReason: " .. reason .. (extraData and ("\nDetails: " .. extraData) or ""),
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, "POST", json.encode({embeds = message}), { ["Content-Type"] = "application/json" })
end

-- Ban System
local playerWarnings = {}

local function applySanction(playerId, reason)
    playerWarnings[playerId] = (playerWarnings[playerId] or 0) + 1

    if playerWarnings[playerId] == 1 then
        DropPlayer(playerId, "You have been warned: " .. reason)
    elseif playerWarnings[playerId] == 2 then
        DropPlayer(playerId, "You have been kicked for: " .. reason)
    elseif playerWarnings[playerId] >= 3 then
        BanPlayer(playerId, reason)
    end
end

-- Function to ban a player
function BanPlayer(playerID, reason)
    local steamID = GetPlayerIdentifiers(playerID)[1] -- Assuming SteamID is the first identifier
    if not steamID then return end

    -- Load existing bans
    local banFile = LoadResourceFile(GetCurrentResourceName(), config.banFile)
    local bans = json.decode(banFile) or {}

    -- Add the new ban
    table.insert(bans, {steamID = steamID, reason = reason, timestamp = os.time()})

    -- Save the updated ban list
    SaveResourceFile(GetCurrentResourceName(), config.banFile, json.encode(bans), -1)

    -- Kick the player
    DropPlayer(playerID, "You have been banned: " .. reason)
end

-- Command to unban a player
RegisterCommand("unban", function(source, args, rawCommand)
    local steamID = args[1]
    if not steamID then
        TriggerClientEvent("chat:addMessage", source, {args = {"^1Error", "Please provide a SteamID."}})
        return
    end

    -- Load existing bans
    local banFile = LoadResourceFile(GetCurrentResourceName(), config.banFile)
    local bans = json.decode(banFile) or {}

    -- Remove the ban
    for i, ban in ipairs(bans) do
        if ban.steamID == steamID then
            table.remove(bans, i)
            break
        end
    end

    -- Save the updated ban list
    SaveResourceFile(GetCurrentResourceName(), config.banFile, json.encode(bans), -1)

    TriggerClientEvent("chat:addMessage", source, {args = {"^2Success", "Player unbanned."}})
end, true)

-- Enhanced flag handling with sanctions
RegisterNetEvent("anticheat:flag")
AddEventHandler("anticheat:flag", function(reason, extraData)
    local playerId = source
    if isAdmin(playerId) then
        print("Admin " .. playerId .. " triggered a flag: " .. reason .. " (Logged only)")
        logToDiscord(reason, playerId, extraData)
        return
    end

    print("Player " .. playerId .. " flagged: " .. reason .. (extraData and (" (" .. extraData .. ")") or ""))
    logToDiscord(reason, playerId, extraData)
    applySanction(playerId, reason)
end)

-- Handle unauthorized vehicle and object spawns
RegisterNetEvent("anticheat:flag")
AddEventHandler("anticheat:flag", function(reason, extraData)
    local playerId = source
    if reason == "Unauthorized vehicle spawn detected!" or reason == "Unauthorized object spawn detected!" then
        logToDiscord(reason .. " Model: " .. extraData, playerId)
        applySanction(playerId, reason)
    end
end)

-- Detect hidden resources
RegisterNetEvent("anticheat:checkHiddenResources")
AddEventHandler("anticheat:checkHiddenResources", function(activeResources)
    for _, resource in ipairs(activeResources) do
        if not IsResourceAllowed(resource) then
            local playerId = source
            logToDiscord("Hidden resource detected: " .. resource, playerId)
        end
    end
end)

-- Helper function to check if a table contains a value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Load configuration from JSON file
local config = LoadResourceFile(GetCurrentResourceName(), "config.json")
config = json.decode(config)

-- Update allowed resources logic
function IsResourceAllowed(resourceName)
    for _, allowed in ipairs(config.allowedResources) do
        if resourceName == allowed then
            return true
        end
    end
    return false
end

-- Command to trigger snapshot
RegisterCommand("takeSnapshot", function(source, args, rawCommand)
    local playerId = source
    if isAdmin(playerId) then
        TriggerClientEvent("anticheat:takeSnapshot", -1)
    end
end, true)

-- Hash check for important files
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every 60 seconds
        local filesToCheck = {
            "client.lua",
            "server.lua"
        }

        for _, file in ipairs(filesToCheck) do
            local fileHash = GetResourceKvpString(file)
            if not fileHash or fileHash ~= "expected_hash_value" then
                logToDiscord("File hash mismatch detected: " .. file, -1)
            end
        end
    end
end)

-- Check inventory and weapons
RegisterNetEvent("anticheat:checkInventory")
AddEventHandler("anticheat:checkInventory", function(currentWeapons)
    local playerId = source
    for _, weapon in ipairs(currentWeapons) do
        if not table.contains(restrictedWeapons, weapon) then
            logToDiscord("Unauthorized weapon detected: " .. weapon, playerId)
        end
    end
end)

-- Log player commands
AddEventHandler("chatMessage", function(source, name, message)
    logToDiscord("Command executed: " .. message, source)
end)

-- Protect against spam
local eventCounts = {}

RegisterServerEvent("anticheat:trackEvent")
AddEventHandler("anticheat:trackEvent", function(eventName)
    local playerId = source
    eventCounts[playerId] = eventCounts[playerId] or {}
    eventCounts[playerId][eventName] = (eventCounts[playerId][eventName] or 0) + 1

    if eventCounts[playerId][eventName] > 10 then -- Threshold for spam
        logToDiscord("Event spam detected: " .. eventName, playerId)
        applySanction(playerId, "Event spam")
    end
end)

-- Save flags to database (example implementation)
function saveFlagToDatabase(playerId, reason)
    -- Replace with actual database logic
    print("Saving flag to database: Player " .. playerId .. ", Reason: " .. reason)
end

RegisterNetEvent("anticheat:flag")
AddEventHandler("anticheat:flag", function(reason, extraData)
    local playerId = source
    saveFlagToDatabase(playerId, reason)
end)

-- Anti-Backdoor: Detect and neutralize server-side script injections
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- Check every 30 seconds
        local resources = GetNumResources()
        for i = 0, resources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            local resourceState = GetResourceState(resourceName)
            if resourceState ~= "started" and not IsResourceAllowed(resourceName) then
                logToDiscord("Potential backdoor detected in resource: " .. resourceName, -1)
                StopResource(resourceName)
            end
        end
    end
end)

-- Anti-Cipher Panel: Identify and block common cipher panels
local knownCipherPanels = {
    "adminpanel",
    "hackerpanel",
    "cheatmenu"
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- Check every 30 seconds
        for _, panel in ipairs(knownCipherPanels) do
            if GetResourceState(panel) == "started" then
                logToDiscord("Unauthorized cipher panel detected: " .. panel, -1)
                StopResource(panel)
            end
        end
    end
end)

-- Continuous Monitoring: Real-time defense against malicious activities
RegisterNetEvent("anticheat:monitorEvent")
AddEventHandler("anticheat:monitorEvent", function(eventName, details)
    local playerId = source
    logToDiscord("Suspicious event detected: " .. eventName .. " Details: " .. (details or "N/A"), playerId)
    applySanction(playerId, "Suspicious activity")
end)

-- Detect resource exploitation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(15000) -- Check every 15 seconds
        local resources = GetNumResources()
        for i = 0, resources - 1 do
            local resourceName = GetResourceByFindIndex(i)
            if not IsResourceAllowed(resourceName) then
                logToDiscord("Unauthorized resource detected: " .. resourceName, -1)
                StopResource(resourceName)
            end
        end
    end
end)

-- Detect macro usage
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every 60 seconds
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local activity = GetPlayerActivity(playerId) -- Replace with actual activity tracking logic
            if activity == "macro" then
                logToDiscord("Macro usage detected!", playerId)
                applySanction(playerId, "Macro usage")
            end
        end
    end
end)