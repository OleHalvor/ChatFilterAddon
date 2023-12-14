print("ChatFilterAddon By Tryllemann Loaded")

local addon, ns = ...

local messageList = {}
local hasWarnedAboutFullGroup = false

local messageQueueMaxSize = 100  -- Maximum number of messages in the queue
local messageTimeout = 60       -- Timeout in seconds for each message

local function printMessageList()
    print('printing message list: ')
    for i, messageEntry in ipairs(messageList) do
        print("Message " .. i .. ": " .. messageEntry.text .. ", Timestamp: " .. messageEntry.timestamp)
    end
end

local function pushToMessageList(message)
    local currentTime = time()

    -- Remove expired messages
    while #messageList > 0 and (currentTime - messageList[1].timestamp) > messageTimeout do
        table.remove(messageList, 1)
    end

    -- Remove oldest message if queue is full
    if #messageList >= messageQueueMaxSize then
        table.remove(messageList, 1)
    end

    -- Add new message with timestamp
    table.insert(messageList, { text = message, timestamp = currentTime })
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


local function CreateCustomChatWindow()
    -- Create the main frame
    local frame = CreateFrame("Frame", "CustomChatFrame", UIParent)
    local isLocked = true  -- Initial state
    frame:SetMovable(not isLocked)
    frame:EnableMouse(not isLocked)
    frame:SetSize(300, 100) -- Width, Height
    frame:SetPoint("BOTTOMRIGHT",0,100) -- Position on the screen
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Create ScrollFrame as a child of the main frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -10, 10)

    -- Create the ScrollingMessageFrame
    local messageFrame = CreateFrame("ScrollingMessageFrame", nil, scrollFrame)
    messageFrame:SetSize(280, 180) -- Width, Height
    messageFrame:SetFontObject("ChatFontNormal")
    messageFrame:SetJustifyH("LEFT")
    messageFrame:SetFading(false)
    -- Event handler for hyperlinks
    messageFrame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
    messageFrame:SetHyperlinksEnabled(true)

    scrollFrame:SetScrollChild(messageFrame)

    frame:SetScript("OnSizeChanged", function(self)
        messageFrame:SetWidth(scrollFrame:GetWidth())
        messageFrame:SetHeight(scrollFrame:GetHeight())
    end)

    -- Lock Button
    local lockButton = CreateFrame("Button", nil, frame)
    lockButton:SetPoint("TOPRIGHT", -10, 10)
    lockButton:SetSize(32, 32)
    lockButton:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
    lockButton:SetHighlightTexture("Interface\\Buttons\\LockButton-Unlocked-Highlight")
    lockButton:SetPushedTexture("Interface\\Buttons\\LockButton-Unlocked-Down")



    lockButton:SetScript("OnClick", function()
        isLocked = not isLocked
        frame:SetMovable(not isLocked)
        frame:EnableMouse(not isLocked)
        -- Change the texture based on the lock state
        lockButton:SetNormalTexture(isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up")
        lockButton:SetHighlightTexture(isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Locked-Highlight")
        lockButton:SetPushedTexture(isLocked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Locked-Down")
    end)

    -- Gear Button for Options
    local gearButton = CreateFrame("Button", nil, frame)
    gearButton:SetPoint("TOPRIGHT", lockButton, "TOPLEFT", -4, 0)
    gearButton:SetSize(24, 24)
    gearButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    gearButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    gearButton:SetScript("OnClick", function()
        -- Open the Interface Options to your addon's panel
        InterfaceOptionsFrame_OpenToCategory("ChatFilterAddon")
        InterfaceOptionsFrame_OpenToCategory("ChatFilterAddon")  -- Call twice to ensure it navigates correctly
    end)



    -- Function to add messages to the ScrollingMessageFrame
    function frame:AddMessage(message)
        messageFrame:AddMessage(message)
    end

    -- Resizing functionality
    frame:SetResizable(true)

    -- Resize Button
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetPoint("BOTTOMRIGHT", -6, 6)
    resizeButton:SetSize(16, 16)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
            self:GetHighlightTexture():Hide()
        end
    end)
    resizeButton:SetScript("OnMouseUp", function(self)
        frame:StopMovingOrSizing()
        self:GetHighlightTexture():Show()
        messageFrame:SetWidth(scrollFrame:GetWidth())
        messageFrame:SetHeight(scrollFrame:GetHeight())
    end)

    return frame
end

-- Usage example







function printMessageToLfmWindow(output)
    local lfgOutputFound = false
    local windowNameToFind = "p"

    -- Loop through chat windows to find the one named "LFM" or "P"
    for i = 1, NUM_CHAT_WINDOWS do
        local windowName = GetChatWindowInfo(i)
        if windowName:lower() == windowNameToFind:lower() then
            lfgOutputFound = true
            local chatFrame = _G["ChatFrame" .. i]
            chatFrame:AddMessage(output)
            break -- Stop the loop as we found the window
        end
    end

    if not lfgOutputFound and not hasWarnedAboutChatName then
        print('Did not find any chat windows named "' .. windowNameToFind .. '", please create one')
        hasWarnedAboutChatName = true
    end
end


function printMessageToNotLfmWindow(output)
    local lfgOutputFound = false
    local windowNameToFind = "notlfm"

    -- Loop through chat windows to find the one named "LFM" or "P"
    for i = 1, NUM_CHAT_WINDOWS do
        local windowName = GetChatWindowInfo(i)
        if windowName:lower() == windowNameToFind:lower() then
            lfgOutputFound = true
            local chatFrame = _G["ChatFrame" .. i]
            chatFrame:AddMessage(output)
            break -- Stop the loop as we found the window
        end
    end

    if not lfgOutputFound and not hasWarnedAboutChatName then
        print('Did not find any chat windows named "' .. windowNameToFind .. '", please create one')
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
        AddMessageToCustomChatWindow("Fjernet blizz ikon! før var det: " .. text)
    end
    return textWithoutIcons
end

local srep = string.rep
local function rpadLFM (s, l, c)
    local res = s .. srep(c or ' ', l - #s)
    return res, res ~= s
end

local function shouldShowMessageBasedOnTags(lowerMessage)
    if ns.Options.hide_XP_runs and hasXPRunTags(lowerMessage) then
        return false, 'XP run tags'
    end
    if ns.Options.hide_cleave_and_AOE_runs and hasCleaveTags(lowerMessage) then
        return false, 'Cleave run tags'
    end
    return true
end

local function formatMessage(sender, chatMessage, lowerMessage, dungeonInMessage, channel)
    local link = "|cffffc0c0|Hplayer:" .. sender .. "|h[" .. sender .. "]|h|r:"
    local j, k = string.find(lowerMessage, dungeonInMessage:lower())
    local newMessage = string.sub(chatMessage, 0, j - 1) .. "|cffffc0FF" ..
            string.sub(chatMessage, j, k):upper() .. "|r" ..
            string.sub(chatMessage, k + 1)
    local output = ""
    if ns.Options.show_time_stamp_on_messages then
        local hours, minutes = GetGameTime()
        output = "[" .. hours .. ":" .. minutes .. "] "
    end
    output = output .. link .. " " .. newMessage
    if ns.Options.display_channel_on_all_messages then
        output = output .. " [" .. channel .. "]"
    end
    return output
end


function ParseMessageCFA(sender, chatMessage, channel)
    local lowerMessage = chatMessage:lower()

    local messageExists = false
    for i, messageEntry in ipairs(messageList) do
        if messageEntry.text == chatMessage then
            messageExists = true
            break
        end
    end

    if messageExists then
        return false
    end

    -- Check if message should be shown based on tags
    local shouldShow, reason = shouldShowMessageBasedOnTags(lowerMessage)
    if not shouldShow then
        if ns.Options.DEBUG_MODE then
            print('DEBUG: not showing message because it has ' .. reason)
        end
        return false
    end

    -- Check if in a full group
    if not ns.Options.keep_looking_while_in_full_group and GetNumGroupMembers() == 5 then
        if not hasWarnedAboutFullGroup then
            AddMessageToCustomChatWindow("You're in a full group. LFM will be disabled")
            AddMessageToCustomChatWindow("If you still wish to look for LFM request this can be toggled in the settings")
            hasWarnedAboutFullGroup = true
        end
        return false
    end

    -- Check for dungeon abbreviations or quests in message
    local dungeonInMessage = HasDungeonAbbreviationCFA(lowerMessage)
    if dungeonInMessage ~= false or isQuestFromLogInText(lowerMessage) then
        hasWarnedAboutFullGroup = false

        pushToMessageList(chatMessage)

        -- Format and print message
        local formattedMessage = formatMessage(sender, chatMessage, lowerMessage, dungeonInMessage, channel)
        AddMessageToCustomChatWindow(removeBlizzIcons(formattedMessage))
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

local myCustomChatWindow = CreateCustomChatWindow()
myCustomChatWindow:AddMessage("Welcome to the custom chat window!")
-- Example: Use this function to add messages to the custom chat window
function AddMessageToCustomChatWindow(message)
    myCustomChatWindow:AddMessage(message)
end
