print("ChatFilterAddon By Tryllemann Loaded")

-- TODO: Options for specific dungeons. Options for extra text-matches. Options for duplicate message suppresion timeout. Match seenMessage on player name as well.

local addon, ns = ...

local recentlySeenMessagesQueue = {}

local messageQueueMaxSize = 1000  -- Maximum number of messages in the queue
local messageTimeout = 240      -- Timeout in seconds for each message
local outputWindowName = "General"
local debugWindowName = "debug"

disabledDungeons = {} -- Manual declaration if needed
local DungeonList = {} -- will be filled
local Dungeons = {} -- will be filled
local hasWarnedAboutFullGroup = false

-- Add new constants for dynamic adjustments
local MIN_LEVENSHTEIN_DISTANCE = 0    -- Minimum allowed Levenshtein distance
local MAX_LEVENSHTEIN_DISTANCE = 20   -- Maximum allowed Levenshtein distance
local MIN_MESSAGE_TIMEOUT = 30       -- Minimum message timeout in seconds
local MAX_MESSAGE_TIMEOUT = 240       -- Maximum message timeout in seconds
local LOWER_MESSAGE_RATE = 1    -- Lower limit of messages per minute (e.g., 6 messages/min)
local UPPER_MESSAGE_RATE = 30   -- Upper limit of messages per minute (e.g., 60 messages/min)

local messageTimestamps = {}  -- List to store timestamps of incoming messages

local function cleanupOldTimestamps()
    local currentTime = time()
    while #messageTimestamps > 0 and (currentTime - messageTimestamps[1]) > 240 do
        table.remove(messageTimestamps, 1)
    end
end

-- Function to calculate current message rate per minute
local function getCurrentMessageRate()
    cleanupOldTimestamps()
    local messageCount = #messageTimestamps
    return (messageCount / 2)  -- Convert to messages per minute
end

-- Function to scale a value based on current message rate
local function scaleValue(minValue, maxValue, lowerRate, upperRate, currentRate)
    local rateFraction = (currentRate - lowerRate) / (upperRate - lowerRate)
    rateFraction = math.min(math.max(rateFraction, 0), 1)  -- Clamp between 0 and 1
    return minValue + (maxValue - minValue) * rateFraction
end

-- Adjust the levenshteinDistance requirement dynamically
local function getDynamicLevenshteinDistance()
    local currentRate = getCurrentMessageRate()
    return scaleValue(MIN_LEVENSHTEIN_DISTANCE, MAX_LEVENSHTEIN_DISTANCE, LOWER_MESSAGE_RATE, UPPER_MESSAGE_RATE, currentRate)
end

-- Adjust the message timeout dynamically
local function getDynamicMessageTimeout()
    local currentRate = getCurrentMessageRate()
    return scaleValue(MIN_MESSAGE_TIMEOUT, MAX_MESSAGE_TIMEOUT, LOWER_MESSAGE_RATE, UPPER_MESSAGE_RATE, currentRate)
end

local hasJoinedChannels = false
-- List of channel names to join and hide
local channelsToJoin = {"world", "global", "lfg", "lfm", "lookingforgroup", "lookingformore"}

-- Function to check if the player is already in the channel
local function IsPlayerInChannel(channelName)
    local channels = {GetChannelList()}
    for i = 1, #channels, 3 do
        if channels[i+1]:lower() == channelName:lower() then
            return true
        end
    end
    return false
end

-- Function to hide a channel from all chat windows
local function HideChannelFromAllChatWindows(channelName)
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame"..i]
        ChatFrame_RemoveChannel(chatFrame, channelName)
    end
end

function joinChannels()
    print("Joining LFM channels in the background")
    if hasJoinedChannels then
        return false
    end
    hasJoinedChannels = true
    for _, channelName in ipairs(channelsToJoin) do
        if not IsPlayerInChannel(channelName) then
            JoinChannelByName(channelName)
            hasJoinedChannels = true
            HideChannelFromAllChatWindows(channelName)
        end
    end
end




local function findChatFrameByName(name)
    for i = 1, NUM_CHAT_WINDOWS do
        local windowName = GetChatWindowInfo(i)
        if windowName:lower() == name:lower() then
            return _G["ChatFrame" .. i]
        end
    end
    return nil
end


local function normalizeSenderName(sender)
    local normalizedSender = sender:match("^[^-]+")
    return normalizedSender
end

local function printMessageList()
    print('printing message list: ')
    for i, messageEntry in ipairs(recentlySeenMessagesQueue) do
        print("Message " .. i .. ": " .. messageEntry.text .. ", Timestamp: " .. messageEntry.timestamp)
    end
end

local function pushToMessageList(sender, message)
    -- Remove oldest message if queue is full
    if #recentlySeenMessagesQueue >= messageQueueMaxSize then
        table.remove(recentlySeenMessagesQueue, 1)
    end
    cleanupOldTimestamps()
    -- Add new message with timestamp and sender
    table.insert(recentlySeenMessagesQueue, { sender = normalizeSenderName(sender), text = message, timestamp = time() })
    table.insert(messageTimestamps, time())
end


local function removeExpiredMessages()
    local dynamicMessageTimeout = getDynamicMessageTimeout()
    while #recentlySeenMessagesQueue > 0 and (time() - recentlySeenMessagesQueue[1].timestamp) > dynamicMessageTimeout do
        table.remove(recentlySeenMessagesQueue, 1)
    end
end




local function hasXPRunTags(message)
    xpTags = {
        "xp",
        "exp"
    }
    if (ns.Utility.containsTextFromArray(message, xpTags)) then
        return true
    end
    return false
end

local function hasCleaveTags(message)
    cleaveTags = {
        "cleave",
        "spellcleave",
        "aoe"
    }
    if (ns.Utility.containsTextFromArray(message, cleaveTags)) then
        return true
    end
    return false
end


ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(_, event, ...)
    local message, player, _, _, _, _, _, _, channelName = ...
    local lfmSend, reason = ParseMessageCFA(player, message, channelName, true)
    if (lfmSend == false and ns.Options.DEBUG_MODE) then
        printMessageToDebugChat(reason .. " " .. message)
    end
    if (lfmSend == true) then
        return true
    end
end)


function printMessageToOutputChat(output)
    local chatFrame = findChatFrameByName(outputWindowName)

    -- Create the chat frame if it doesn't exist
    if not chatFrame then
        chatFrame = createChatFrame(outputWindowName)
    end

    -- Add message to the chat frame
    chatFrame:AddMessage(output)
end

function printMessageToDebugChat(output)
    local chatFrame = findChatFrameByName(debugWindowName)

    -- Create the chat frame if it doesn't exist and in debug mode
    if not chatFrame and ns.Options.DEBUG_MODE then
        chatFrame = createChatFrame(debugWindowName)
    end

    -- Add message to the chat frame if it exists
    if chatFrame then
        chatFrame:AddMessage(output)
    end
end

local function formatMessage(sender, chatMessage, lowerMessage, dungeonInMessage, channel)
    sender = normalizeSenderName(sender)
    local playerNameLink = "|cffffc0c0|Hplayer:" .. sender .. "|h[" .. sender .. "]|h|r"
    local j, k = string.find(lowerMessage, dungeonInMessage:lower())
    local formattedMessage = string.sub(chatMessage, 0, j - 1) .. "|cffffc0FF" ..
            string.sub(chatMessage, j, k):upper() .. "|r" ..
            string.sub(chatMessage, k + 1)
    local timestamp = ""
    if ns.Options.show_time_stamp_on_messages then
        local hours, minutes = GetGameTime()
        timestamp = "[" .. hours .. ":" .. minutes .. "] "
    end
    output = timestamp .. playerNameLink
    if (ns.Options.display_channel_on_all_messages) then
        output = output .. " ["..channel.."]";
    end
    output = output .. ": " .. formattedMessage
    return output
end

local function levenshteinDistance(str1, str2)
    local len1 = #str1
    local len2 = #str2
    local matrix = {}
    local cost = 0

    -- initialize matrix
    for i = 0, len1 do
        matrix[i] = {[0] = i}
    end
    for j = 0, len2 do
        matrix[0][j] = j
    end

    -- calculate distances
    for i = 1, len1 do
        for j = 1, len2 do
            if str1:sub(i, i) == str2:sub(j, j) then
                cost = 0
            else
                cost = 1
            end
            matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
        end
    end

    return matrix[len1][len2]
end

function messageHasBeenSeenRecently(sender, message)
    removeExpiredMessages()

    sender = normalizeSenderName(sender)
    local lowerMessage = message:lower()
    local dynamicLevenshteinDistance = getDynamicLevenshteinDistance()

    for _, messageEntry in ipairs(recentlySeenMessagesQueue) do
        if messageEntry.sender == sender then
            local distance = levenshteinDistance(messageEntry.text:lower(), lowerMessage)
            if distance <= dynamicLevenshteinDistance then
                return true
            end
        end
    end
    return false
end

-- todo: Velg chat vindu fra options...

function playerClassFitsRole(playerClass, role)
    local classRoles = {
        Mage = {"DPS", "Caster"},
        Hunter = {"DPS"},
        Warlock = {"DPS", "Caster"},
        Warrior = {"DPS", "Tank", "Melee"},
        Shaman = {"DPS", "Healer", "Caster", "Melee"},
        Paladin = {"DPS", "Tank", "Healer", "Caster", "Melee"},
        Druid = {"DPS", "Tank", "Healer", "Caster", "Melee"},
        Priest = {"DPS", "Healer", "Caster"}
    }

    if classRoles[playerClass] then
        for _, classRole in ipairs(classRoles[playerClass]) do
            if classRole == role then
                return true
            end
        end
    end

    return false
end

function getRolesFromMessage(message)
    local roleKeywords = {
        DPS = {"dps", "dd"},
        Healer = {"heal", "healer", "heals"},
        Tank = {"tank", "mt"},
        Caster = {"caster"},
        Melee = {"melee"}
    }

    local rolesInMessage = {}
    for role, keywords in pairs(roleKeywords) do
        for _, keyword in ipairs(keywords) do
            if message:lower():find(keyword) then
                rolesInMessage[role] = true
            end
        end
    end
    return rolesInMessage
end



-- Parses chat messages and prints it if it meets criteria
function ParseMessageCFA(sender, chatMessage, channel, send_message)
    if not hasJoinedChannels then
        joinChannels()
    end


    local lowerMessage = chatMessage:lower()

    -- Abort if message seen recently
    if messageHasBeenSeenRecently(sender, chatMessage) then
        return false, '| Message seen recently'
    end

    -- Abort if XP run and XP runs are disabled
    if ns.Options.hide_XP_runs and hasXPRunTags(lowerMessage) then
        return false, '| Message contains disabled XP tag'
    end


    -- Abort if Cleave run and Cleave runs are disabled
    if ns.Options.hide_cleave_and_AOE_runs and hasCleaveTags(lowerMessage) then
        return false, '| Message contains disabled Cleave tag'
    end

    -- Abort if in full group
    if not ns.Options.keep_looking_while_in_full_group and GetNumGroupMembers() == 5 then
        if not hasWarnedAboutFullGroup then
            printMessageToOutputChat("You're in a full group. LFM will be disabled")
            printMessageToOutputChat("If you still wish to look for LFM request this can be toggled in the settings")
            hasWarnedAboutFullGroup = true
        end
        return false, '| Disabled while in full group'
    end

    -- Abort if doesn't contain LFM or LFG + option/partial group
    if (not hasLfmOrLfg(lowerMessage)) then
        -- Allow messages without lfg/lfm is there are very few messages
        if not (getCurrentMessageRate() <= LOWER_MESSAGE_RATE) then
            return false, '| Message does not contain LFM or LFG with fitting options'
        end
    end

    -- Abort if message does not contain a relevant dungeon
    local dungeonInMessage = HasLevelAppropriateDungeonAbbreviationCFA(lowerMessage)
    if dungeonInMessage == false then
        return false, '| Message does not contain level-appropriate Dungeons keyword'
    end

    local rolesInMessage = getRolesFromMessage(lowerMessage)
    local playerClass = UnitClass("player")

    local fitsAtLeastOneRole = false
    for role, _ in pairs(rolesInMessage) do
        if playerClassFitsRole(playerClass, role) then
            fitsAtLeastOneRole = true
            break
        end
    end

    if not fitsAtLeastOneRole and next(rolesInMessage) ~= nil then
        -- Allow messages without lfg/lfm is there are very few messages
        if not (getCurrentMessageRate() <= LOWER_MESSAGE_RATE) then
            return false, '| Player class does not fit any of the roles in the message'
        end
    end

    if (send_message) then
        pushToMessageList(sender, chatMessage)
        printMessageToOutputChat(ns.Utility.removeBlizzIcons(formatMessage(sender, chatMessage, lowerMessage, dungeonInMessage, channel)))
    end

    return true
end

function hasLfmOrLfg(message)
    if HasLFMTagCFA(message) and GetNumGroupMembers()<=1 then -- alone, looking to join group
        return true
    end
    if (HasLFGTagCFA(message) and ns.Options.include_LFG_messages_in_addition_to_LFM) then -- alone, but allowing LFG
        return true
    end
    if (HasLFGTagCFA(message) and (GetNumGroupMembers()>1 and GetNumGroupMembers()<5)) then -- In partial party, look for more people
        return true
    end
    return false
end

function HasLFMTagCFA(text)
    local lfmTags = {
        "lfm",
        "lf3m",
        "lf2m",
        "lf1m",
        "lf1",
        "lf2",
        "lf3",
        "lf ",
        "last spot",
        "looking for more"
    }
    for _, tag in pairs(lfmTags) do
        if (string.find(text:lower(), tag)) then
            return true
        end
    end
    return false
end

function HasLFGTagCFA(text)
    if (string.find(text, "lfg")) then
        return true
    end
    return false
end

function HasLevelAppropriateDungeonAbbreviationCFA(chatMessage)
    local lowerChatMessage = chatMessage:lower()
    local level = UnitLevel("player")
    if (not ns.Options.include_dungeons_outside_of_level_range) then
        for key, dungeon in pairs(GetDungeonsByLevelCFA(level)) do
            if (ns.Utility.containsTextFromArray(Dungeons[key].Name, disabledDungeons)) then
                return false
            end
            for _, abbreviation in pairs(dungeon.Abbreviations) do
                words = {}
                for word in lowerChatMessage:gmatch("%w+") do
                    table.insert(words, word)
                end
                if (ns.Utility.ArrayContainsValueCFA(words, abbreviation:lower())) then
                    return abbreviation
                end
            end
        end
    else
        for key, dungeon in pairs(Dungeons) do
            for _, abbreviation in pairs(dungeon.Abbreviations) do
                words = {}
                for word in lowerChatMessage:gmatch("%w+") do
                    table.insert(words, word)
                end
                if (ns.Utility.ArrayContainsValueCFA(words, abbreviation:lower())) then
                    return abbreviation
                end
            end
        end
    end
    return false
end

function DefineDungeonCFA(name, size, minLevel, maxLevel, location, abbreviation, abbreviations)
    Dungeons[name] = {
        Name = name,
        MinLevel = minLevel,
        MaxLevel = maxLevel,
        Location = location,
        Faction = faction,
        Abbreviation = abbreviation,
        Abbreviations = abbreviations,
        Background = background,
        Size = size
    }
    DungeonList[name] = name
end

function GetDungeonsByLevelCFA(level)
    local dungeonsForLevel = {}
    for key in pairs(Dungeons) do
        local dungeon = Dungeons[key]
        if (dungeon.MinLevel <= level and dungeon.MaxLevel >= level) then
            dungeonsForLevel[dungeon.Name] = dungeon
        end
    end
    return dungeonsForLevel
end

DefineDungeonCFA("Ragefire Chasm", 5, 13, 18, "Orgrimmar", "rfc", { "rfc", "ragefire" })
DefineDungeonCFA("Wailing Caverns", 5, 17, 24, "Barrens", "wc", { "wc", "wailing" })
DefineDungeonCFA("The Deadmines", 5, 17, 24, "Westfall", "vc", { "vc", "deadmines", "dm" })
DefineDungeonCFA("Shadowfang Keep", 5, 21, 30, "Silverpine Forest", "sfk", { "sfk", "shadowfang" })
--DefineDungeonCFA("Blackfathom Deeps", 5, 22, 32, "Ashenvale", "bfd", { "bfd", "blackfathom" }) -- ORIGINAL
DefineDungeonCFA("Blackfathom Deeps", 5, 22, 32, "Ashenvale", "bfd", { "bfd", "blackfathom" }) -- Season of Discovery
DefineDungeonCFA("The Stockades", 5, 22, 30, "Stormwind", "stockades", { "stockades", "stocks", "stockade" })
DefineDungeonCFA("Gnomeregan", 5, 28, 38, "Dun Morogh", "gnomergan", { "gnomeregan", "gnomer", "gnome" })
DefineDungeonCFA("Razorfen Kraul", 5, 25, 39, "Barrens", "rfk", { "rfk", "kraul" })
DefineDungeonCFA("The Scarlet Monastery: Graveyard", 5, 28, 44, "Tirisfal Glades", "sm graveyard", { "grave", "graveyard", "sm", "scarlet" })
DefineDungeonCFA("The Scarlet Monastery: Library", 5, 30, 44, "Tirisfal Glades", "sm library", { "lib", "library", "sm", "scarlet" })
DefineDungeonCFA("The Scarlet Monastery: Armory", 5, 32, 44, "Tirisfal Glades", "sm armory", { "arms", "arm", "sm", "scarlet" })
DefineDungeonCFA("The Scarlet Monastery: Cathedral", 5, 34, 44, "Tirisfal Glades", "sm cathedral", { "cath", "cathedral", "scarlet", "sm" })
DefineDungeonCFA("Razorfen Downs", 5, 36, 46, "Barrens", "rfd", { "rfd", "razorfen", "downs" })
DefineDungeonCFA("Uldaman", 5, 41, 52, "Badlands", "ulda", { "ulda", "uldaman" })
DefineDungeonCFA("Zul'Farak", 5, 42, 54, "Tanaris", "zf", { "zf", "zul", "farak", "farrak" })
DefineDungeonCFA("Maraudon", 5, 44, 54, "Desolace", "maraudon", { "maraudon", "mara" })
DefineDungeonCFA("Temple of Atal'Hakkar", 5, 47, 60, "Swamp of Sorrows", "st", { "st", "toa", "atal", "sunken" })
DefineDungeonCFA("Blackrock Depths", 5, 49, 60, "Blackrock Mountain", "brd", { "blackrock", "depths", "brd", "moira", "lava", "arena", "anger", "golem", "jailbreak", "jailbreack", "angerforge" })
DefineDungeonCFA("Lower Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "lbrs", { "lbrs", "lower blackrock spire" })
DefineDungeonCFA("Upper Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "ubrs", { "ubrs", "upper blackrock spire", "rend" })
DefineDungeonCFA("Dire Maul", 5, 56, 60, "Feralas", "Dire", { "dire", "tribute", "maul", "diremaul", "dme", "dmn", "dmw" })
DefineDungeonCFA("Stratholme", 5, 56, 60, "Eastern Plaguelands", "strat", { "strat", "stratholme", "start", " living", " ud ", "undead", "Startholme" })
DefineDungeonCFA("Scholomance", 5, 56, 60, "Eastern Plaguelands", "scholo", { "scholo", "scholomance" })
DefineDungeonCFA("Molten Core", 40, 60, 60, "Blackrock Depths", "mc", { "mc", "molten" })
DefineDungeonCFA("Onyxia's Lair", 40, 60, 60, "Dustwallow Marsh", "ony", { "ony", "onyxia", "onyxia's" })

print("Possible dungeons for your level: ")
for key, dungeon in pairs(GetDungeonsByLevelCFA(UnitLevel("player"))) do
    print(key)
end



