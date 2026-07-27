-- Функция для корректного перевода кириллицы (UTF-8) в нижний регистр
local function Utf8Lower(str)
    if not str then return "" end
    local isAscii = true
    for i = 1, #str do
        if string.byte(str, i) > 127 then
            isAscii = false
            break
        end
    end
    if isAscii then return string.lower(str) end

    local u = {
        ["А"]="а", ["Б"]="б", ["В"]="в", ["Г"]="г", ["Д"]="д", ["Е"]="е", ["Ё"]="ё",
        ["Ж"]="ж", ["З"]="з", ["И"]="и", ["Й"]="й", ["К"]="к", ["Л"]="л", ["М"]="м",
        ["Н"]="н", ["О"]="о", ["П"]="п", ["Р"]="р", ["С"]="с", ["Т"]="т", ["У"]="у",
        ["Ф"]="ф", ["Х"]="х", ["Ц"]="ц", ["Ч"]="ч", ["Ш"]="ш", ["Щ"]="щ", ["Ъ"]="ъ",
        ["Ы"]="ы", ["Ь"]="ь", ["Э"]="э", ["Ю"]="ю", ["Я"]="я"
    }
    return (str:gsub("[%z\1-\127\194-\244][\128-\191]*", u):lower())
end

-- ГЛАВНАЯ ФУНКЦИЯ: Ищет игрока с учетом текущего игрового сервера
local function GetNotesForPlayer(playerName)
    if not playerName or playerName == "" then return nil end
    if not ScamRegistryDB then return nil end

    local currentRealm = Utf8Lower(GetRealmName() or "")
    local cleanName = Utf8Lower(playerName)

    if ScamRegistryDB[currentRealm] and ScamRegistryDB[currentRealm][cleanName] then
        return ScamRegistryDB[currentRealm][cleanName]
    end

    return nil
end

-- Форматирование заметок в текст
local function FormatNotes(notes)
    if not notes then return nil end
    if type(notes) == "string" then notes = { notes } end

    if type(notes) == "table" and #notes > 0 then
        local result = ""
        for i, note in ipairs(notes) do
            if #notes > 1 then
                result = result .. i .. ". " .. note .. "\n\n"
            else
                result = result .. note
            end
        end
        return result
    end
    return nil
end

-- Окончания для слова "жалоба"
local function GetPluralComplaint(count)
    local c100 = count % 100
    local c10 = count % 10
    if c100 >= 11 and c100 <= 19 then
        return count .. " жалоб"
    elseif c10 == 1 then
        return count .. " жалоба"
    elseif c10 >= 2 and c10 <= 4 then
        return count .. " жалобы"
    else
        return count .. " жалоб"
    end
end

----------------------------------------------------
-- 1. ОКНО ДЕТАЛЬНОЙ ИНФОРМАЦИИ ПО ЦЕЛИ
----------------------------------------------------
local infoFrame = CreateFrame("Frame", "ScamRegistryInfoFrame", UIParent)
infoFrame:SetSize(380, 240)
infoFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
infoFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
infoFrame:EnableMouse(true); infoFrame:SetMovable(true); infoFrame:RegisterForDrag("LeftButton")
infoFrame:SetScript("OnDragStart", infoFrame.StartMoving); infoFrame:SetScript("OnDragStop", infoFrame.StopMovingOrSizing); infoFrame:Hide()

local infoTitle = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
infoTitle:SetPoint("TOP", infoFrame, "TOP", 0, -12)
infoTitle:SetText("|cffFF0000ИНФОРМАЦИЯ О ЦЕЛИ|r")

local infoScroll = CreateFrame("ScrollFrame", "ScamRegistryInfoScroll", infoFrame, "UIPanelScrollFrameTemplate")
infoScroll:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 15, -40)
infoScroll:SetPoint("BOTTOMRIGHT", infoFrame, "BOTTOMRIGHT", -35, 40)

local infoContent = CreateFrame("Frame", nil, infoScroll)
infoContent:SetSize(310, 100); infoScroll:SetScrollChild(infoContent)

local infoText = infoContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
infoText:SetPoint("TOPLEFT", infoContent, "TOPLEFT", 0, 0)
infoText:SetWidth(300); infoText:SetJustifyH("LEFT"); infoText:SetJustifyV("TOP")

local closeInfoBtn = CreateFrame("Button", nil, infoFrame, "UIPanelButtonTemplate")
closeInfoBtn:SetSize(90, 22)
closeInfoBtn:SetPoint("BOTTOM", infoFrame, "BOTTOM", 0, 10)
closeInfoBtn:SetText("Закрыть")
closeInfoBtn:SetScript("OnClick", function() infoFrame:Hide() end)

----------------------------------------------------
-- 2. ОКНО ПРЕДВАРИТЕЛЬНОГО ПРОСМОТРА СКАНА
----------------------------------------------------
local scanFrame = CreateFrame("Frame", "ScamRegistryScanFrame", UIParent)
scanFrame:SetSize(380, 250)
scanFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
scanFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
scanFrame:EnableMouse(true); scanFrame:SetMovable(true); scanFrame:RegisterForDrag("LeftButton")
scanFrame:SetScript("OnDragStart", scanFrame.StartMoving); scanFrame:SetScript("OnDragStop", scanFrame.StopMovingOrSizing); scanFrame:Hide()

local scanTitle = scanFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
scanTitle:SetPoint("TOP", scanFrame, "TOP", 0, -12)
scanTitle:SetText("|cffFF0000РЕЗУЛЬТАТЫ СКАНА|r")

local scanScroll = CreateFrame("ScrollFrame", "ScamRegistryScanScroll", scanFrame, "UIPanelScrollFrameTemplate")
scanScroll:SetPoint("TOPLEFT", scanFrame, "TOPLEFT", 15, -40)
scanScroll:SetPoint("BOTTOMRIGHT", scanFrame, "BOTTOMRIGHT", -35, 45)

local scanContent = CreateFrame("Frame", nil, scanScroll)
scanContent:SetSize(310, 100); scanScroll:SetScrollChild(scanContent)

local scanText = scanContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scanText:SetPoint("TOPLEFT", scanContent, "TOPLEFT", 0, 0)
scanText:SetWidth(300); scanText:SetJustifyH("LEFT"); scanText:SetJustifyV("TOP")

local lastFoundScammers = {}
local lastTotalScanned = 0

local sendPartyBtn = CreateFrame("Button", nil, scanFrame, "UIPanelButtonTemplate")
sendPartyBtn:SetSize(95, 22)
sendPartyBtn:SetPoint("BOTTOMLEFT", scanFrame, "BOTTOMLEFT", 15, 10)
sendPartyBtn:SetText("В группу")

local sendRaidBtn = CreateFrame("Button", nil, scanFrame, "UIPanelButtonTemplate")
sendRaidBtn:SetSize(95, 22)
sendRaidBtn:SetPoint("LEFT", sendPartyBtn, "RIGHT", 5, 0)
sendRaidBtn:SetText("В рейд")

local closeScanBtn = CreateFrame("Button", nil, scanFrame, "UIPanelButtonTemplate")
closeScanBtn:SetSize(80, 22)
closeScanBtn:SetPoint("BOTTOMRIGHT", scanFrame, "BOTTOMRIGHT", -15, 10)
closeScanBtn:SetText("Закрыть")
closeScanBtn:SetScript("OnClick", function() scanFrame:Hide() end)

-- Функция отправки сообщений в чат
local function SendScanResultsToChat(chatType)
    if #lastFoundScammers > 0 then
        SendChatMessage("[ScamRegistry] Внимание! В базе найдено " .. #lastFoundScammers .. " игроков:", chatType)
        for _, scammer in ipairs(lastFoundScammers) do
            SendChatMessage(" - " .. scammer.name .. " — " .. GetPluralComplaint(scammer.count), chatType)
        end
    else
        local groupTypeStr = (chatType == "RAID") and "рейда" or "группы"
        SendChatMessage("[ScamRegistry] Сканирование " .. groupTypeStr, chatType)
        SendChatMessage("Просканировано: " .. lastTotalScanned .. ". Игроков с жалобами не найдено", chatType)
    end
end

sendPartyBtn:SetScript("OnClick", function() SendScanResultsToChat("PARTY") end)
sendRaidBtn:SetScript("OnClick", function() SendScanResultsToChat("RAID") end)

----------------------------------------------------
-- 3. ОКНО С ССЫЛКОЙ НА DISCORD (Жалоба)
----------------------------------------------------
local discordLink = "https://discord.gg/ZeRn5tuKTc"

local reportFrame = CreateFrame("Frame", "ScamRegistryReportFrame", UIParent)
reportFrame:SetSize(320, 110)
reportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
reportFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
reportFrame:EnableMouse(true); reportFrame:SetMovable(true); reportFrame:RegisterForDrag("LeftButton")
reportFrame:SetScript("OnDragStart", reportFrame.StartMoving); reportFrame:SetScript("OnDragStop", reportFrame.StopMovingOrSizing); reportFrame:Hide()

local reportTitle = reportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
reportTitle:SetPoint("TOP", reportFrame, "TOP", 0, -12)
reportTitle:SetText("|cffffcc00ПОДАТЬ ЖАЛОБУ|r")

local reportText = reportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
reportText:SetPoint("TOP", reportTitle, "BOTTOM", 0, -5)
reportText:SetText("Скопируйте ссылку (Ctrl+C) для перехода в Discord:")

local reportEditBox = CreateFrame("EditBox", nil, reportFrame, "InputBoxTemplate")
reportEditBox:SetSize(260, 20)
reportEditBox:SetPoint("TOP", reportText, "BOTTOM", 0, -8)
reportEditBox:SetAutoFocus(false)
reportEditBox:SetText(discordLink)
reportEditBox:SetScript("OnTextChanged", function(self)
    self:SetText(discordLink)
    self:HighlightText()
end)
reportEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    reportFrame:Hide()
end)

local closeReportBtn = CreateFrame("Button", nil, reportFrame, "UIPanelButtonTemplate")
closeReportBtn:SetSize(70, 20)
closeReportBtn:SetPoint("BOTTOM", reportFrame, "BOTTOM", 0, 8)
closeReportBtn:SetText("Закрыть")
closeReportBtn:SetScript("OnClick", function() reportFrame:Hide() end)

local function ShowReportWindow()
    reportFrame:Show()
    reportEditBox:SetFocus()
    reportEditBox:HighlightText()
    print("|cff00ff00[ScamRegistry]|r Ссылка на Discord для подачи жалоб: |cffffcc00" .. discordLink .. "|r")
end

----------------------------------------------------
-- 4. ЛОГИКА ПРОВЕРКИ И СКАНА
----------------------------------------------------
local function ShowTargetInfo()
    if UnitExists("target") and UnitIsPlayer("target") then
        local name = UnitName("target")
        if name then
            local rawNotes = GetNotesForPlayer(name)
            local formattedText = FormatNotes(rawNotes)

            if formattedText then
                infoText:SetText("|cffffcc00Игрок:|r " .. name .. " (" .. GetRealmName() .. ")\n\n|cffffffffЗаметки:|r\n" .. formattedText)
            else
                infoText:SetText("|cffffcc00Игрок:|r " .. name .. "\n\n|cff00ff00В базе вашего сервера информации о нарушениях нет.|r")
            end

            infoContent:SetHeight(math.max(infoText:GetStringHeight() + 20, 120))
            infoScroll:SetVerticalScroll(0)
            infoFrame:Show()
            return
        end
    end
    print("|cff00ff00[ScamRegistry]|r Выберите игрока в цель.")
end

local function ScanRoster()
    local numRaid, numParty = GetNumRaidMembers(), GetNumPartyMembers()
    if numRaid == 0 and numParty == 0 then
        print("|cff00ff00[ScamRegistry]|r Вы не находитесь в группе или рейде.")
        return
    end

    lastFoundScammers = {}
    local totalPlayers = 0

    if numRaid > 0 then
        for i = 1, numRaid do
            local name = UnitName("raid" .. i)
            if name and name ~= "" then
                totalPlayers = totalPlayers + 1
                local rawNotes = GetNotesForPlayer(name)
                if rawNotes then
                    local count = (type(rawNotes) == "table") and #rawNotes or 1
                    if count > 0 then table.insert(lastFoundScammers, { name = name, count = count }) end
                end
            end
        end
    else
        local playerName = UnitName("player")
        if playerName and playerName ~= "" then
            totalPlayers = totalPlayers + 1
            local rawNotes = GetNotesForPlayer(playerName)
            if rawNotes then
                local count = (type(rawNotes) == "table") and #rawNotes or 1
                if count > 0 then table.insert(lastFoundScammers, { name = playerName, count = count }) end
            end
        end

        for i = 1, numParty do
            local name = UnitName("party" .. i)
            if name and name ~= "" then
                totalPlayers = totalPlayers + 1
                local rawNotes = GetNotesForPlayer(name)
                if rawNotes then
                    local count = (type(rawNotes) == "table") and #rawNotes or 1
                    if count > 0 then table.insert(lastFoundScammers, { name = name, count = count }) end
                end
            end
        end
    end

    lastTotalScanned = totalPlayers

    if #lastFoundScammers > 0 then
        local displayText = "|cffffffffСервер:|r " .. GetRealmName() .. "\n|cffffffffПросканировано:|r " .. totalPlayers .. "\n|cffFF0000Найдено нарушителей:|r " .. #lastFoundScammers .. "\n\n"
        for _, scammer in ipairs(lastFoundScammers) do
            displayText = displayText .. "• |cffffcc00" .. scammer.name .. "|r — " .. GetPluralComplaint(scammer.count) .. "\n"
        end
        scanText:SetText(displayText)
    else
        scanText:SetText("|cffffffffСервер:|r " .. GetRealmName() .. "\n|cffffffffПросканировано участников:|r " .. totalPlayers .. "\n\n|cff00ff00Нарушителей не найдено.|r")
    end

    -- Кнопки активны всегда в зависимости от присутствия в группе/рейде
    if numRaid > 0 then
        sendRaidBtn:Enable()
        sendPartyBtn:Disable()
    else
        sendRaidBtn:Disable()
        sendPartyBtn:Enable()
    end

    scanContent:SetHeight(math.max(scanText:GetStringHeight() + 20, 120))
    scanScroll:SetVerticalScroll(0)
    scanFrame:Show()
end

----------------------------------------------------
-- 5. МИНИ-ПАНЕЛЬ С ЗАГОЛОВКОМ И 3 КНОПКАМИ
----------------------------------------------------
local controlBar = CreateFrame("Frame", "ScamRegistryControlBar", UIParent)
controlBar:SetSize(220, 52)
controlBar:SetPoint("TOP", UIParent, "TOP", 0, -30)
controlBar:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
controlBar:EnableMouse(true); controlBar:SetMovable(true); controlBar:RegisterForDrag("LeftButton")
controlBar:SetScript("OnDragStart", controlBar.StartMoving); controlBar:SetScript("OnDragStop", controlBar.StopMovingOrSizing)

local barTitle = controlBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
barTitle:SetPoint("TOP", controlBar, "TOP", 0, -6)
barTitle:SetText("|cffFF0000ScamRegistry|r")

local scanBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
scanBtn:SetSize(60, 20)
scanBtn:SetPoint("BOTTOMLEFT", controlBar, "BOTTOMLEFT", 8, 8)
scanBtn:SetText("Скан")
scanBtn:SetScript("OnClick", function() ScanRoster() end)

local checkBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
checkBtn:SetSize(60, 20)
checkBtn:SetPoint("LEFT", scanBtn, "RIGHT", 4, 0)
checkBtn:SetText("Цель")
checkBtn:SetScript("OnClick", function() ShowTargetInfo() end)

local reportBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
reportBtn:SetSize(72, 20)
reportBtn:SetPoint("LEFT", checkBtn, "RIGHT", 4, 0)
reportBtn:SetText("Жалоба")
reportBtn:SetScript("OnClick", function() ShowReportWindow() end)

local hideBarBtn = CreateFrame("Button", nil, controlBar, "UIPanelCloseButton")
hideBarBtn:SetSize(20, 20)
hideBarBtn:SetPoint("TOPRIGHT", controlBar, "TOPRIGHT", -2, -2)
hideBarBtn:SetScript("OnClick", function() controlBar:Hide() end)

----------------------------------------------------
-- 6. СЛЭШ-КОМАНДЫ
----------------------------------------------------
SLASH_SCAMREGISTRY1 = "/sr"
SLASH_SCAMREGISTRY2 = "/scam"
SlashCmdList["SCAMREGISTRY"] = function(msg)
    local param = msg:match("^%s*(.-)%s*$")
    local lowerParam = Utf8Lower(param)

    if lowerParam == "ui" or lowerParam == "panel" then controlBar:Show(); return
    elseif lowerParam == "scan" or lowerParam == "скан" then ScanRoster(); return
    elseif lowerParam == "target" or lowerParam == "цель" then ShowTargetInfo(); return
    elseif lowerParam == "report" or lowerParam == "жалоба" then ShowReportWindow(); return end

    if not param or param == "" then
        print("|cff00ff00[ScamRegistry]|r Команды: /sr ui, /sr scan, /sr target, /sr report, /sr Ник")
        return
    end
    
    local rawNotes = GetNotesForPlayer(param)
    if type(rawNotes) == "string" then rawNotes = { rawNotes } end

    if rawNotes and #rawNotes > 0 then
        print("|cffFF0000[ScamRegistry]|r " .. param .. " (" .. GetRealmName() .. "):")
        for i, note in ipairs(rawNotes) do
            print("  |cffffcc00" .. i .. ".|r " .. note)
        end
    else
        print("|cff00ff00[ScamRegistry]|r Игрок " .. param .. " не найден в базе " .. GetRealmName() .. ".")
    end
end