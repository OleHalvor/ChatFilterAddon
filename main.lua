print('ChatFilterAddon Loaded!')

-- most of this is copied from classicLFG addon

DungeonList = {}
Dungeons = {}

local Frame = CreateFrame("frame")
Frame:RegisterEvent("CHAT_MSG_CHANNEL")
Frame:SetScript("OnEvent", function(_, event, ...)
        if (event == "CHAT_MSG_CHANNEL") then
            local message, player, _, _, _, _, _, _, channelName = ...
            ParseMessageCFA(player, message, channelName)
        end
end)


    function ParseMessageCFA(sender, chatMessage, channel)
	local lowerMessage = chatMessage:lower()
	if (HasLFMTagCFA(lowerMessage)) then
		if (HasDungeonAbbreviationCFA(lowerMessage)) then
           		 print(sender," : ",lowerMessage," : ",channel)
		end
	end
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
        "looking for more"
    }
    local found = false
    for _, tag in pairs(lfmTags) do
        if (string.find(text, tag)) then
            found = true
            break
        end
    end
    return found
end

function ArrayContainsValueCFA(array, val)
    for index, value in ipairs(array) do
        if value == val then
            return true
        end
    end
    return false
end

function HasDungeonAbbreviationCFA(chatMessage)
    local level = UnitLevel("player")
    for key, dungeon in pairs(GetDungeonsByLevelCFA(level)) do
        print("After get by level ",dungeon, "abbr: ",dungeon.Abbreviations)
        for _, abbreviation in pairs(dungeon.Abbreviations) do
            words = {}
            for word in chatMessage:gmatch("%w+") do table.insert(words, word) end
            if (ArrayContainsValueCFA(words, abbreviation)) then
                return true
            end
        end
    end
    return nil
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
    print("checking dungeons for level ",level)
    local dungeonsForLevel = {}
    for key in pairs(Dungeons) do
        local dungeon = Dungeons[key]
        if (dungeon.MinLevel <= level and dungeon.MaxLevel >= level) then
            dungeonsForLevel[dungeon.Name] = dungeon.Name
        end
    end
    return dungeonsForLevel
end



DefineDungeonCFA("Ragefire Chasm", 5, 12, 21, "Orgrimmar", "rfc", {"rfc", "ragefire"})
DefineDungeonCFA("Wailing Caverns", 5, 15, 25, "Barrens", "wc", {"wc"})
DefineDungeonCFA("The Deadmines", 5, 14, 24, "Westfall", "vc", {"dm", "vc", "deadmines"})
DefineDungeonCFA("Shadowfang Keep", 5, 16, 27, "Silverpine Forest", "sfk", {"sfk", "shadowfang"})
DefineDungeonCFA("Blackfathom Deeps", 5, 20, 30, "Ashenvale", "bfd", {"bfd"})
DefineDungeonCFA("The Stockades", 5, 21, 30, "Stormwind", "stockades", {"stockades", "stocks"})
DefineDungeonCFA("Gnomeregan", 5, 25, 35, "Dun Morogh", "gnomergan", {"gnomeregan", "gnomer"})
DefineDungeonCFA("Razorfen Kraul", 5, 22, 32, "Barrens", "rfk", {"rfk", "kraul"})
DefineDungeonCFA("The Scarlet Monastery: Graveyard", 5, 25, 35, "Tirisfal Glades", "sm graveyard", {"sm", "SM GY"})
DefineDungeonCFA("The Scarlet Monastery: Library", 5, 29, 39, "Tirisfal Glades", "sm library", {"sm"})
DefineDungeonCFA("The Scarlet Monastery: Armory", 5, 32, 42, "Tirisfal Glades", "sm armory", {"sm"})
DefineDungeonCFA("The Scarlet Monastery: Cathedral", 5, 34, 44, "Tirisfal Glades", "sm cathedral", {"sm"})
DefineDungeonCFA("Razorfen Downs", 5, 33, 43, "Barrens", "rfd", {"rfd"})
DefineDungeonCFA("Uldaman", 5, 35, 45, "Badlands", "ulda", {"ulda"})
DefineDungeonCFA("Zul'Farak", 5, 40, 50, "Tanaris", "zf", {"zf"})
DefineDungeonCFA("Maraudon", 5, 44, 54, "Desolace", "maraudon", {"maraudon", "mara"})
DefineDungeonCFA("Temple of Atal'Hakkar", 5, 47, 60, "Swamp of Sorrows", "st", {"st", "toa", "atal", "sunken temple"})
DefineDungeonCFA("Blackrock Depths", 5, 49, 60, "Blackrock Mountain", "brd", {"brd"})
DefineDungeonCFA("Lower Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "lbrs", {"lbrs"})
DefineDungeonCFA("Upper Blackrock Spire", 10, 55, 60, "Blackrock Mountain", "ubrs", {"ubrs"})
-- ToDo: Need to add all the Dungeon parts once they are released on Classic Realms
--ClassicLFG:DefineDungeon("Dire Maul", 55, 60, "Feralas", {"dm:"}, ClassicLFG.Faction.BOTH)
--
DefineDungeonCFA("Stratholme", 5, 56, 60, "Eastern Plaguelands", "strat", {"strat"})
DefineDungeonCFA("Scholomance", 5, 56, 60, "Eastern Plaguelands", "scholo", {"scholo"})
DefineDungeonCFA("Molten Core", 40, 60, 60, "Blackrock Depths", "mc", {"mc"})
DefineDungeonCFA("Onyxia's Lair", 40, 60, 60, "Dustwallow Marsh", "ony", {"ony", "onyxia"})



















