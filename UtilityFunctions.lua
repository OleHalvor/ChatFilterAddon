-- UtilityFunctions.lua
local addon, ns = ...
ns.Utility = {}

function ns.Utility.mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function ns.Utility.containsText(message, text)
    return string.find(message:lower(), text:lower()) ~= nil
end

function ns.Utility.tablelength(T)
    return #T
end

function ns.Utility.containsTextFromArray(message, array)
    for _, var in pairs(array) do
        if Utility.containsText(message, var) then
            return true
        end
    end
    return false
end

function ns.Utility.removeBlizzIcons(text)
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
        if (containsText(text,var)) then
            textWithoutIcons = textWithoutIcons:gsub(("%"..var)," ")
        end
    end
    for _, var in pairs(icons) do
        if (containsText(text,var:upper())) then
            textWithoutIcons = textWithoutIcons:gsub(("%"..var:upper())," ")
        end
    end
    for _, var in pairs(icons) do
        if (containsText(text,var:lower())) then
            textWithoutIcons = textWithoutIcons:gsub(("%"..var:lower())," ")
        end
    end
    if (text ~= textWithoutIcons and Options.DEBUG_MODE) then
        printMessageToLfmWindow("Fjernet blizz ikon! før var det: "..text)
    end
    return textWithoutIcons
end

print("UtilityFunctions.lua loaded")
return Utility
