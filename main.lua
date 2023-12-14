print("ChatFilterAddon By Tryllemann Loaded")

local addon, ns = ...

local messageList = { "melding -2", "melding -1", "melding 0", "melding 1", "melding 2", "melding 3" }
local messageListSize = #messageList
local lastMessageListUpdateTime = time()
local messageListClearInterval = 60
local hasWarnedAboutFullGroup = false

local function pushToMessageList (message)
    if #messageList >= messageListSize then
        table.remove(messageList, 1)
    end
    table.insert(messageList, message)
end

function try(f, catch_f)
    local status, exception = pcall(f)
    if not status then
        catch_f(exception)
    end
end

local disabledDungeons = {
    "The Scarlet Monastery: Library",
    "The Scarlet Monastery: Cathedral",
    "The Scarlet Monastery: Armory",
    "The Scarlet Monastery: Graveyard"
}
disabledDungeons = {}


local function getQuestsInLog()
    quests = {}
    for i = 1, GetNumQuestLogEntries() do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
        if (not level == 0) then
            quests[i] = GetQuestLogTitle(i);
        end
    end
    return quests
end

local function isQuestFromLogInText(text)
    quests = getQuestsInLog();
    for _, quest in pairs(quests) do
        if (string.find(text:lower(), quest:lower())) then
            return true
        end
    end
    return false
end

print(getQuestsInLog())


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

local hasWarnedAboutChatName = false
local DungeonList = {}
local Dungeons = {}
local Frame = CreateFrame("frame")
Frame:RegisterEvent("CHAT_MSG_CHANNEL")
Frame:SetScript("OnEvent", function(_, event, ...)
    if (event == "CHAT_MSG_CHANNEL") then
        local message, player, _, _, _, _, _, _, channelName = ...
        local lfmSend = ParseMessageCFA(player, message, channelName)
        if (lfmSend == false and ns.Options.DEBUG_MODE) then
            printMessageToNotLfmWindow(message)
        end
    end
end)

function printMessageToLfmWindow(output)
    local lfgOutputFound = false
    for i = 1, NUM_CHAT_WINDOWS do
        if (GetChatWindowInfo(i) == "p" or GetChatWindowInfo(i) == "P") then
            --if (GetChatWindowInfo(i)=="lfm" or GetChatWindowInfo(i)=="LFM") then
            lfgOutputFound = true
            if (i == 1) then
                ChatFrame1:AddMessage(output)
            end
            if (i == 2) then
                ChatFrame2:AddMessage(output)
            end
            if (i == 3) then
                ChatFrame3:AddMessage(output)
            end
            if (i == 4) then
                ChatFrame4:AddMessage(output)
            end
            if (i == 5) then
                ChatFrame5:AddMessage(output)
            end
            if (i == 6) then
                ChatFrame6:AddMessage(output)
            end
            if (i == 7) then
                ChatFrame7:AddMessage(output)
            end
            if (i == 8) then
                ChatFrame8:AddMessage(output)
            end
            if (i == 9) then
                ChatFrame9:AddMessage(output)
            end
        end
    end
    if (not lfgOutputFound and not hasWarnedAboutChatName) then
        print('Did not find any chat windows named "LFM", please create one')
        hasWarnedAboutChatName = true
    end
end

function printMessageToNotLfmWindow(output)
    local lfgOutputFound = false
    for i = 1, NUM_CHAT_WINDOWS do
        if (GetChatWindowInfo(i) == "notlfm" or GetChatWindowInfo(i) == "NOTLFM") then
            lfgOutputFound = true
            -- don't know how to specify correct chat frame without hard coding. please don't judge me
            if (i == 1) then
                ChatFrame1:AddMessage(output)
            end
            if (i == 2) then
                ChatFrame2:AddMessage(output)
            end
            if (i == 3) then
                ChatFrame3:AddMessage(output)
            end
            if (i == 4) then
                ChatFrame4:AddMessage(output)
            end
            if (i == 5) then
                ChatFrame5:AddMessage(output)
            end
            if (i == 6) then
                ChatFrame6:AddMessage(output)
            end
            if (i == 7) then
                ChatFrame7:AddMessage(output)
            end
            if (i == 8) then
                ChatFrame8:AddMessage(output)
            end
            if (i == 9) then
                ChatFrame9:AddMessage(output)
            end
        end
    end
    if (not lfgOutputFound and not hasWarnedAboutChatName) then
        print('Did not find any chat windows named "NOTLFM", please create one')
        hasWarnedAboutChatName = true
    end
end

local function isInDungeon()
    -- loop over dungeons, if current zone is a dungeon, return dungeon. else return false
    return
end

local waitTable = {};
local waitFrame = nil;

function LFMCF__wait(delay, func, ...)
    if (type(delay) ~= "number" or type(func) ~= "function") then
        return false;
    end
    if (waitFrame == nil) then
        waitFrame = CreateFrame("Frame", "WaitFrame", UIParent);
        waitFrame:SetScript("onUpdate", function(self, elapse)
            local count = #waitTable;
            local i = 1;
            while (i <= count) do
                local waitRecord = tremove(waitTable, i);
                local d = tremove(waitRecord, 1);
                local f = tremove(waitRecord, 1);
                local p = tremove(waitRecord, 1);
                if (d > elapse) then
                    tinsert(waitTable, i, { d - elapse, f, p });
                    i = i + 1;
                else
                    count = count - 1;
                    f(unpack(p));
                end
            end
        end);
    end
    tinsert(waitTable, { delay, func, { ... } });
    return true;
end

local function removeBlizzIcons(text)
    local textWithoutIcons = text
    icons = {
        "{Skull}",
        "{Cross}",
        "{Square}",
        "{Moon}",
        "{Triangle}",
        "{Diamond}",
        "{Circle}",
        "{Star}"
    }
    for _, var in pairs(icons) do
        if (ns.Utility.containsText(text, var)) then
            textWithoutIcons = textWithoutIcons:gsub(("%" .. var), " ")
        end
    end
    for _, var in pairs(icons) do
        if (ns.Utility.containsText(text, var:upper())) then
            textWithoutIcons = textWithoutIcons:gsub(("%" .. var:upper()), " ")
        end
    end
    for _, var in pairs(icons) do
        if (ns.Utility.containsText(text, var:lower())) then
            textWithoutIcons = textWithoutIcons:gsub(("%" .. var:lower()), " ")
        end
    end
    if (text ~= textWithoutIcons and ns.Options.DEBUG_MODE) then
        printMessageToLfmWindow("Fjernet blizz ikon! før var det: " .. text)
    end
    return textWithoutIcons
end

local srep = string.rep
local function rpadLFM (s, l, c)
    local res = s .. srep(c or ' ', l - #s)
    return res, res ~= s
end

function ParseMessageCFA(sender, chatMessage, channel)

    if (lastMessageListUpdateTime + messageListClearInterval < time()) then
        for i = 1, messageListSize do
            messageList[i] = i
        end
        lastMessageListUpdateTime = time()
    end

    local messageListActualSize = #messageList
    for i = 0, messageListActualSize do
        if (messageList[i] == chatMessage) then
            return nil
        end
    end

    local lowerMessage = chatMessage:lower()
    if (HasLFMTagCFA(lowerMessage) or (ns.Options.include_LFG_messages_in_addition_to_LFM or (GetNumGroupMembers() > 1 and GetNumGroupMembers() < 5) and HasLFGTagCFA(lowerMessage))) then
        if (ns.Options.hide_XP_runs == true) then
            if (hasXPRunTags(lowerMessage)) then
                if (ns.Options.DEBUG_MODE) then
                    print('DEBUG: not showing message because it has XP run tags ' .. chatMessage)
                end
                return false
            end
        end
        if (ns.Options.hide_cleave_and_AOE_runs == true) then
            if (hasCleaveTags(lowerMessage)) then
                if (ns.Options.DEBUG_MODE) then
                    print('DEBUG: not showing message because it has Cleave run tags ' .. chatMessage)
                end
                return false
            end
        end

        if ((not ns.Options.keep_looking_while_in_full_group) and (GetNumGroupMembers() == 5)) then
            if (not hasWarnedAboutFullGroup) then
                printMessageToLfmWindow("You're inn a full group. LFM will be disabled")
                printMessageToLfmWindow("If you still wish to look for LFM request this can be toggled in the settings")
                printMessageToLfmWindow("Good luck and have fun in the dungeon :)")
            end
            hasWarnedAboutFullGroup = true
            return false
        end

        local dungeonInMessage = HasDungeonAbbreviationCFA(lowerMessage)
        if (dungeonInMessage ~= false or (isQuestFromLogInText(lowerMessage))) then
            hasWarnedAboutFullGroup = false
            pushToMessageList(chatMessage)
            local link = "|cffffc0c0|Hplayer:" .. sender .. "|h[" .. sender .. "]|h|r:";
            local j, k = string.find(lowerMessage, dungeonInMessage:lower())
            local newMessage = string.sub(chatMessage, 0, (j - 1)) .. "|cffffc0FF" .. string.sub(chatMessage, j, k):upper() .. "|r" .. string.sub(chatMessage, k + 1, chatMessage:len())
            --local output = "|cffffc0FF["..dungeonInMessage:upper().."]"
            local output = ""
            if (ns.Options.show_time_stamp_on_messages) then
                local hours, minutes = GetGameTime();
                output = (output .. "[" .. hours .. ":" .. minutes .. "] ")
            end
            output = output .. link .. " " .. newMessage
            if (ns.Options.display_channel_on_all_messages) then
                output = output .. " [" .. channel .. "]";
            end
            printMessageToLfmWindow(removeBlizzIcons(output))
            return true
        end
        return false
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

function ArrayContainsValueCFA(array, val)
    for index, value in ipairs(array) do
        if value == val then
            return true
        end
        if value:gsub('[%p%c%s]', '') == val then
            return true
        end
    end
    return false
end

function HasDungeonAbbreviationCFA(chatMessage)
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
                if (ArrayContainsValueCFA(words, abbreviation:lower())) then
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
                if (ArrayContainsValueCFA(words, abbreviation:lower())) then
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
DefineDungeonCFA("The Deadmines", 5, 17, 24, "Westfall", "vc", { "vc", "deadmines" })
DefineDungeonCFA("Shadowfang Keep", 5, 21, 30, "Silverpine Forest", "sfk", { "sfk", "shadowfang" })
DefineDungeonCFA("Blackfathom Deeps", 5, 22, 32, "Ashenvale", "bfd", { "bfd", "blackfathom" })
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
DefineDungeonCFA("Dire Maul", 5, 56, 60, "Feralas", "Dire", { "dire", "dm", "tribute", "maul", "diremaul", "dme", "dmn", "dmw" })
DefineDungeonCFA("Stratholme", 5, 56, 60, "Eastern Plaguelands", "strat", { "strat", "stratholme", "start", " living", " ud ", "undead", "Startholme" })
DefineDungeonCFA("Scholomance", 5, 56, 60, "Eastern Plaguelands", "scholo", { "scholo", "scholomance" })
DefineDungeonCFA("Molten Core", 40, 60, 60, "Blackrock Depths", "mc", { "mc", "molten" })
DefineDungeonCFA("Onyxia's Lair", 40, 60, 60, "Dustwallow Marsh", "ony", { "ony", "onyxia", "onyxia's" })

print("Possible dungeons for your level: ")
for key, dungeon in pairs(GetDungeonsByLevelCFA(UnitLevel("player"))) do
    print(key)
end



