-- Gestion de la localisation
local _, core = ...
local L = core.Locales[GetLocale()] or core.Locales["enUS"]
local version = C_AddOns.GetAddOnMetadata("DMTools", "Version")

local markerSync = false
local colorWhite = "|cFFFFFFFF"
local colorGrey = "|cFF7C7C7C"



--------------------------------------------
-- ATTENTE DU CHARGEMENT DE LA SAUVEGARDE --
--------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", function(self, event)
	if markers == nil then
		markers = {}
		for i = 1, 8 do
			table.insert(markers, {name = "", power = "", health = "", description = "", hidden = true})
		end
	end

    ------------------------
	-- RETROCOMPATIBILITE --
	------------------------
	for i = 1 , 8 do
		-- Si le champ hidden n'existe pas, initialisez-le à false
		if markers[i].hidden == nil then
			markers[i].hidden = true
		end
	end

    --------------------------
    -- INTERFACE PRINCIPALE --
    --------------------------
    -- Création de la page transparente
	local MarkerFramePage = CreateFrame("Frame", "MarkerFramePage", UIParent)
	MarkerFramePage:SetSize(280, 420)
	MarkerFramePage:SetPoint("RIGHT", -300, 60)  -- Positionne la frame au centre de l'écran
    MarkerFramePage:EnableMouse(true)
    MarkerFramePage:SetMovable(true)
    MarkerFramePage:RegisterForDrag("LeftButton")
    MarkerFramePage:SetScript("OnDragStart", MarkerFramePage.StartMoving)
    MarkerFramePage:SetScript("OnDragStop", MarkerFramePage.StopMovingOrSizing)
    MarkerFramePage:SetFrameStrata("MEDIUM")
    MarkerFramePage:Hide()
    MarkerFramePage:SetScript("OnShow", function(self)
        if DMToolsMarkerTransparent == false then
            MarkerFrame:Show()
        end
    end)
    function MarkerFramePage:OnDragStop()
		self:StopMovingOrSizing()
		-- Enregistrer la nouvelle position dans la table
		local point, _, _, x, y = self:GetPoint()
		DMToolsPanelPosition[self:GetName()] = {point = point, x = x, y = y}
	end
	MarkerFramePage:SetScript("OnDragStart", SkillFrame.StartMoving)
	MarkerFramePage:SetScript("OnDragStop", SkillFrame.OnDragStop)
    

    -- Création du cadre
    local MarkerFrame = CreateFrame("Frame", "MarkerFrame", MarkerFramePage, "ButtonFrameTemplate")
    MarkerFrame:SetTitle(L["DMTools NPC"])
    MarkerFrame:SetPortraitToAsset("Interface\\ICONS\\inv_misc_grouplooking")
    MarkerFrame:SetSize(380, 420) -- Largeur, Hauteur
    MarkerFrame:SetPoint("CENTER", 50, 0) -- Position sur l'écran
    MarkerFrame:SetFrameStrata("LOW")
    MarkerFrame.Inset:Hide()
    -- Ajout d'un gestionnaire d'événements OnHide à MarkerFrame
    MarkerFrame:SetScript("OnHide", function(self)
        if DMToolsMarkerTransparent == false then
            MarkerFramePage:Hide()
        end
    end)

    

    -- Création des entête de compétence du volet principal
    local tableHeaders = MarkerFramePage:CreateFontString(nil, "OVERLAY")
    tableHeaders:SetFontObject("GameFontNormal")
    tableHeaders:SetPoint("TOPLEFT", 65, - 35)
    tableHeaders:SetText(L["Marker Table Header"])

    -- Création de la ligne de séparation haute
	local line = MarkerFramePage:CreateTexture(nil, "BACKGROUND")
	line:SetHeight(2)  -- Définit l'épaisseur de la ligne
	line:SetWidth(MarkerFrame:GetWidth())  -- Définit la largeur de la ligne
	line:SetPoint("TOPLEFT", 0, - 50)  -- Positionne la ligne au centre de la frame
	line:SetColorTexture(1, 1, 1, 0.2)  -- Définit la couleur de la ligne (ici, blanc semi-transparent)

    -- Création de la ligne de séparation basse
	local line = MarkerFramePage:CreateTexture(nil, "BACKGROUND")
	line:SetHeight(2)  -- Définit l'épaisseur de la ligne
	line:SetWidth(MarkerFrame:GetWidth())  -- Définit la largeur de la ligne
	line:SetPoint("TOPLEFT", 0, - 380)  -- Positionne la ligne au centre de la frame
	line:SetColorTexture(1, 1, 1, 0.2)  -- Définit la couleur de la ligne (ici, blanc semi-transparent)

    for i = 1, 8 do
        local j = ""
        if i == 1 then
            j = 5
        elseif i == 2 then
            j = 6
        elseif i == 3 then
            j = 3
        elseif i == 4 then
            j = 2
        elseif i == 5 then
            j = 7
        elseif i == 6 then
            j = 1
        elseif i == 7 then
            j = 4
        else 
            j = 8
        end
        --local icon = MarkerFramePage:CreateTexture(nil, "OVERLAY")
        local icon = CreateFrame("Button", "iconButton", MarkerFramePage, "SecureActionButtonTemplate") -- action button
        -- icon:SetAttribute("type1", "macro") -- action button
        -- icon:SetAttribute("macrotext1", "/wm " .. j) -- text for macro on left click
        -- icon:SetAttribute("type2", "macro") -- action button for right click
        -- icon:SetAttribute("macrotext2", "/cwm " .. j) -- text for macro on right click
        icon:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i) -- for action button
        --icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i)
        icon:SetPoint("TOPLEFT", 10, -40 * i -20)
        icon:SetSize(30, 30)
        icon:RegisterForClicks("AnyUp", "AnyDown")
        icon:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                if markerSync == false then
                    ChatFrame1EditBox:Insert("{rt" .. i .. "}")
                    ChatFrame1EditBox:Show()
                    ChatFrame1EditBox:SetFocus()
                end
            end
        end)
        DMToolsMarkerIcon[i] = icon
        
        -- Nom du marqueur
        local MarkerName = MarkerFramePage:CreateFontString(nil, "OVERLAY")
        MarkerName:SetFontObject("GameFontNormal")
        MarkerName:SetPoint("TOPLEFT", 50, -40 * i - 30)
        MarkerName:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].name)
        MarkerName:SetFontObject("GameFontNormal")
        DMToolsMarkerNames[i] = MarkerName

        -- Puissance du marqueur
        local MarkerPower = MarkerFramePage:CreateFontString(nil, "OVERLAY")
        MarkerPower:SetFontObject("GameFontNormal")
        MarkerPower:SetPoint("TOPLEFT", 205, -40 * i - 30)
        MarkerPower:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].power)
        MarkerPower:SetFontObject("GameFontNormal")
        DMToolsMarkerPowers[i] = MarkerPower

        -- Santé du marqueur
        local MarkerHealth = MarkerFramePage:CreateFontString(nil, "OVERLAY")
        MarkerHealth:SetFontObject("GameFontNormal")
        MarkerHealth:SetPoint("TOPLEFT", 280, -40 * i - 30)
        MarkerHealth:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].health)
        MarkerHealth:SetFontObject("GameFontNormal")
        DMToolsMarkerHealth[i] = MarkerHealth

        -- Description du marqueur
        DMToolsMarkerDescription[i] = markers[i].description

        -- Bouton d'édition
		DMToolsEditIsOpened = false
		local editButton = CreateFrame("Button", nil, MarkerFrame, "GameMenuButtonTemplate")
		editButton:SetPoint("TOPLEFT", 350, -40 * i - 25)
		editButton:SetSize(25, 25)
		editButton:SetText("?")
        editButton:SetScript("OnClick", function()
            if DMToolsEditIsOpened == false then
                DMToolsEditIsOpened = true
                -- Création de la fenêtre d'édition de compétence
                local editFrame = CreateFrame("Frame", "editFrame", UIParent, "ButtonFrameTemplate")
                editFrame:SetFrameStrata("HIGH")
                editFrame:SetTitle(L["Marker Details"])
                editFrame:SetSize(400, 230) -- Largeur, Hauteur
                editFrame:SetPoint("CENTER", 0, -0) -- Position sur l'écran
                ButtonFrameTemplate_HidePortrait(editFrame) 
                ButtonFrameTemplate_HideButtonBar(editFrame) 
                editFrame:EnableMouse(true)
                editFrame:SetMovable(true)
                editFrame:RegisterForDrag("LeftButton")
                editFrame:SetScript("OnDragStart", editFrame.StartMoving)
                editFrame:SetScript("OnDragStop", editFrame.StopMovingOrSizing)
                editFrame.Inset:Hide()
                editFrame:SetScript("OnHide", function(self)
                    DMToolsEditIsOpened = false  -- Change la valeur de la variable lorsque la fenêtre est fermée
                end)
                local icon = editFrame:CreateTexture(nil, "OVERLAY")
                icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i)
                icon:SetPoint("TOPLEFT", 13 , -30)
                icon:SetSize(40, 40)
                -- Zone de texte pour le nom du marqueur
				local editMarkerName = editFrame:CreateFontString(nil, "OVERLAY")
				editMarkerName:SetFontObject("GameFontNormal")
				editMarkerName:SetPoint("TOPLEFT", 61, -30)
				editMarkerName:SetText(L["Marker Name"])
				-- Zone de saisie pour le nom du marqueur
				local markerNameBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				markerNameBox:SetSize(130, 20)
				markerNameBox:SetPoint("TOPLEFT", 65, -50)
				markerNameBox:SetAutoFocus(false)
				markerNameBox:SetText(markers[i].name)
				markerNameBox:SetMaxLetters(25)
                -- Zone de texte pour la puissance du marqueur
				local markerPowerText = editFrame:CreateFontString(nil, "OVERLAY")
				markerPowerText:SetFontObject("GameFontNormal")
				markerPowerText:SetPoint("TOPLEFT", 220, -30)
				markerPowerText:SetText(L["Marker Power"])
				-- Zone de saisie pour la puissance
				local markerPowerBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				markerPowerBox:SetSize(70, 20)
				markerPowerBox:SetPoint("TOPLEFT", 222, -50)
				markerPowerBox:SetAutoFocus(false)
				markerPowerBox:SetText(markers[i].power)
				markerPowerBox:SetMaxLetters(12)
                -- Zone de texte pour la santé
				local markerHealthText = editFrame:CreateFontString(nil, "OVERLAY")
				markerHealthText:SetFontObject("GameFontNormal")
				markerHealthText:SetPoint("TOPLEFT", 318, -30)
				markerHealthText:SetText(L["Health"])
				-- Zone de saisie pour la santé
				local markerHealthBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				markerHealthBox:SetSize(70, 20)
				markerHealthBox:SetPoint("TOPLEFT", 320, -50)
				markerHealthBox:SetAutoFocus(false)
				markerHealthBox:SetText(markers[i].health)
				markerHealthBox:SetMaxLetters(10)
                -- Zone de texte pour la description
				local markerDescriptionText = editFrame:CreateFontString(nil, "OVERLAY")
				markerDescriptionText:SetFontObject("GameFontNormal")
				markerDescriptionText:SetPoint("TOPLEFT", 10, -80)
				markerDescriptionText:SetText(L["Marker Description"])
				-- Création de la frame de fond pour la description
				local markerDescriptionBackground = CreateFrame("Frame", nil, editFrame)
				markerDescriptionBackground:SetSize(380, 95)  -- Définit la taille de la frame
				markerDescriptionBackground:SetPoint("TOPLEFT", 13, -100)  -- Positionne la frame au centre de l'écran
				-- Création de la texture de fond
				local bg = markerDescriptionBackground:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
				bg:SetColorTexture(0, 0, 0, 0.5)  -- Définit la texture comme transparente
				-- Zone de saisie pour la description de la compétence
				local markerDescriptionBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				markerDescriptionBox:SetMultiLine(true)
				markerDescriptionBox.Left:Hide()
				markerDescriptionBox.Middle:Hide()
				markerDescriptionBox.Right:Hide()
				markerDescriptionBox:SetWidth(378)
				markerDescriptionBox:SetHeight(200)
				markerDescriptionBox:SetPoint("TOPLEFT", 15, -105)
				markerDescriptionBox:SetAutoFocus(false)
				markerDescriptionBox:SetText(markers[i].description)
                markerDescriptionBox:SetMaxLetters(150)
                -- Coche garder secret
				local secretCheckButton = CreateFrame("CheckButton", "secretCheckButton", editFrame, "ChatConfigCheckButtonTemplate")
				secretCheckButton:SetPoint("TOPLEFT", 369, -75)
				secretCheckButton:SetChecked(markers[i].hidden)
				secretCheckButton.tooltip = L["Keep Secret Tooltip"]
				local secretCheckText = editFrame:CreateFontString(nil, "OVERLAY")
				secretCheckText:SetFontObject("GameFontNormal")
				secretCheckText:SetPoint("TOPLEFT", 285, -80)
				secretCheckText:SetText(L["Keep Secret?"])
				--local isHidden = markers[i].hidden
				--[[ secretCheckButton:SetScript("OnClick", function(self)
					if self:GetChecked() then
						isHidden = true
					else
						isHidden = false
					end ]]
				-- end)
   
                
                -- Bouton "Enregistrer"
				local saveButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
				saveButton:SetPoint("TOPLEFT", 214, -200)
				saveButton:SetSize(180, 25)
				saveButton:SetText(L["Save"])
				saveButton:SetScript("OnClick", function()
					-- Enregistrement de la compétence ici
					local markerNameText = markerNameBox:GetText()
					local markerPowerText = markerPowerBox:GetText()
					local markerHealthText = markerHealthBox:GetText()
					local markerdescriptionText = markerDescriptionBox:GetText()
                    local markerIsHidden = secretCheckButton:GetChecked()
					-- Ajoutez le code pour enregistrer la compétence dans votre base de données locale ici
					markers[i].name = markerNameText
					markers[i].power = markerPowerText
					markers[i].health = markerHealthText
					markers[i].description = markerdescriptionText
                    markers[i].hidden = markerIsHidden
					MarkerName:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].name)
					MarkerPower:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].power)
					MarkerHealth:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].health)
                    editFrame:Hide()
                    DMToolsSendMarkers(i) -- envoi des marqueurs (si synchro true)
                    end)

				-- Bouton "Supprimer"
				local deleteButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
				deleteButton:SetPoint("TOPLEFT", 10, -200)
				deleteButton:SetSize(120, 25)
				deleteButton:SetText(L["Delete"])
				deleteButton:SetScript("OnClick", function()
					markers[i].name = ""
					markers[i].power = ""
					markers[i].health = ""
					markers[i].description = ""
                    markers[i].hidden = true
					MarkerName:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].name)
					MarkerPower:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].power)
					MarkerHealth:SetText((markers[i].hidden and colorGrey or colorWhite) .. markers[i].health)
                    editFrame:Hide()
                    DMToolsSendMarkers(i) -- envoi des marqueurs (si synchro true)
				end)
                 -- Seulement si le joueur est chef de groupe ou raid assist
                 if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
                    saveButton:Enable()
                    deleteButton:Enable()
                    markerSyncButton:Enable()
                 elseif UnitInRaid("player") or UnitInParty("player") then
                    saveButton:Disable()
                    deleteButton:Disable()
                    markerSyncButton:Disable()
                else
                    saveButton:Enable()
                    deleteButton:Enable()
                    markerSyncButton:Disable()
                end               
            end
        end)

    end
    -- Création du tooltip
    local tooltip = CreateFrame("GameTooltip", "MarkerTooltip", MarkerFramePage, "GameTooltipTemplate")

    -- Tableau pour stocker les frames de ligne
    local function DMToolsGenerateMarkerTooltips()
        for i = 1 , 8 do
            local lineFrame = CreateFrame("Frame", nil, MarkerFramePage)
            lineFrame:SetSize(150, 25) -- Ajustez la taille en fonction de votre ligne
            -- Ajustez la position en fonction de votre ligne et de l'index
            lineFrame:SetPoint("TOPLEFT", MarkerFramePage, "TOPLEFT", 45, -i * 40 -23)
            lineFrame:EnableMouse(true)
            --lineFrame:SetFrameStrata("MEDIUM")

            -- Création de la texture
            local texture = lineFrame:CreateTexture(nil, "BACKGROUND")
            texture:SetAllPoints()
            texture:SetColorTexture(1, 1, 1, 0) -- Les quatre paramètres sont Rouge, Vert, Bleu et Alpha (transparence)

            -- Affichage du tooltip lors du survol
            lineFrame:SetScript("OnEnter", function(self)
                tooltip:SetOwner(self, "ANCHOR_TOP")  -- Définir le propriétaire du tooltip ici
                tooltip:ClearLines()
                if markers[i].description ~= nil then
                    --tooltip:SetMinimumWidth(300)
                    --[[ local concatenateDescription = ""
                    for _, detail in ipairs(descriptionDetails) do
                        if detail.name == orderedDescription[i].name and detail.descSkillID == orderedDescription[i].skillID then
                            concatenateDescription = concatenateDescription .. detail.descriptionPart
                        end

                    end ]]
                --tooltip:AddLine(concatenateDescription, 1, 1, 1, true)
                tooltip:AddLine(markers[i].description, 1, 1, 1, true)
                --print(markers[i].description)
                tooltip:Show()
                end
            end)
        
            -- Cacher le tooltip lorsque la souris quitte la frame
            lineFrame:SetScript("OnLeave", function(self)
                tooltip:Hide()
            end)
        
        end
    end
    DMToolsGenerateMarkerTooltips()
    
    -- Boutons de synchronisation des marqueurs
    --local markerSync = false -- gère la synchronisation des marqueurs
    local markerSyncButton = CreateFrame("CheckButton", "markerSyncButton", MarkerFramePage, "ChatConfigCheckButtonTemplate")
    markerSyncButton:SetPoint("TOPLEFT", 10, -389)
    markerSyncButton:SetChecked(markerSync)
    markerSyncButton.tooltip = L["Marker Sync Tooltip"]
    local markerSyncText = MarkerFramePage:CreateFontString(nil, "OVERLAY")
    markerSyncText:SetFontObject("GameFontNormal")
    markerSyncText:SetPoint("TOPLEFT", 38, -395)
    markerSyncText:SetText(L["Marker Sync?"])
    markerSyncButton:SetScript("OnClick", function(self)
        if self:GetChecked() then
            if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
                markerSync = true
                for i = 1, 8 do
                    local j = ""
                    if i == 1 then
                        j = 5
                    elseif i == 2 then
                        j = 6
                    elseif i == 3 then
                        j = 3
                    elseif i == 4 then
                        j = 2
                    elseif i == 5 then
                        j = 7
                    elseif i == 6 then
                        j = 1
                    elseif i == 7 then
                        j = 4
                    else 
                        j = 8
                    end
                    DMToolsMarkerIcon[i]:SetAttribute("type1", "macro") -- action button
                    DMToolsMarkerIcon[i]:SetAttribute("macrotext1", "/wm " .. j) -- text for macro on left click
                    DMToolsMarkerIcon[i]:SetAttribute("type2", "macro") -- action button for right click
                    DMToolsMarkerIcon[i]:SetAttribute("macrotext2", "/cwm " .. j) -- text for macro on right click
                    DMToolsMarkerIcon[i]:SetAttribute("shift-type1", "macro") -- action button for shift + left click
                    DMToolsMarkerIcon[i]:SetAttribute("shift-macrotext1", "/run ChatFrame1EditBox:Insert('{rt" .. i .. "}'); ChatFrame1EditBox:Show(); ChatFrame1EditBox:SetFocus();") -- text for macro on shift + left click

                end
            elseif UnitInRaid("player") or UnitInParty("player") then
                markerSync = false
                for i = 1, 8 do
                    local j = ""
                    if i == 1 then
                        j = 5
                    elseif i == 2 then
                        j = 6
                    elseif i == 3 then
                        j = 3
                    elseif i == 4 then
                        j = 2
                    elseif i == 5 then
                        j = 7
                    elseif i == 6 then
                        j = 1
                    elseif i == 7 then
                        j = 4
                    else 
                        j = 8
                    end
                    DMToolsMarkerIcon[i]:SetAttribute("type1", nil) -- action button
                    DMToolsMarkerIcon[i]:SetAttribute("macrotext1", nil) -- text for macro on left click
                    DMToolsMarkerIcon[i]:SetAttribute("type2", nil) -- action button for right click
                    DMToolsMarkerIcon[i]:SetAttribute("macrotext2", nil) -- text for macro on right click
                    DMToolsMarkerIcon[i]:SetAttribute("shift-type1", nil)
                    DMToolsMarkerIcon[i]:SetAttribute("shift-macrotext1", nil)
                end
                markerSyncButton:SetChecked(markerSync)
                print(L["You need to be leader or assist"])
            else
                for i = 1, 8 do
                    local j = ""
                    if i == 1 then
                        j = 5
                    elseif i == 2 then
                        j = 6
                    elseif i == 3 then
                        j = 3
                    elseif i == 4 then
                        j = 2
                    elseif i == 5 then
                        j = 7
                    elseif i == 6 then
                        j = 1
                    elseif i == 7 then
                        j = 4
                    else 
                        j = 8
                    end
                    DMToolsMarkerIcon[i]:SetAttribute("type1", nil) -- action button
                    DMToolsMarkerIcon[i]:SetAttribute("macrotext1", nil) -- text for macro on left click
                    DMToolsMarkerIcon[i]:SetAttribute("type2", nil) -- action button for right click
                    DMToolsMarkerIcon[i]:SetAttribute("macrotext2", nil) -- text for macro on right click
                    DMToolsMarkerIcon[i]:SetAttribute("shift-type1", nil)
                    DMToolsMarkerIcon[i]:SetAttribute("shift-macrotext1", nil)
                end
                markerSync = false
                markerSyncButton:SetChecked(markerSync)
                print(L["You need to be leader or assist"])
            end
        else
            for i = 1, 8 do
                local j = ""
                if i == 1 then
                    j = 5
                elseif i == 2 then
                    j = 6
                elseif i == 3 then
                    j = 3
                elseif i == 4 then
                    j = 2
                elseif i == 5 then
                    j = 7
                elseif i == 6 then
                    j = 1
                elseif i == 7 then
                    j = 4
                else 
                    j = 8
                end
                DMToolsMarkerIcon[i]:SetAttribute("type1", nil) -- action button
                DMToolsMarkerIcon[i]:SetAttribute("macrotext1", nil) -- text for macro on left click
                DMToolsMarkerIcon[i]:SetAttribute("type2", nil) -- action button for right click
                DMToolsMarkerIcon[i]:SetAttribute("macrotext2", nil) -- text for macro on right click
                DMToolsMarkerIcon[i]:SetAttribute("shift-type1", nil)
                DMToolsMarkerIcon[i]:SetAttribute("shift-macrotext1", nil)
            end
            markerSync = false
            --markerSyncButton:SetChecked(markerSync)   
        end
    end)

    -- Boutons de transparence
    local markerTransparentButton = CreateFrame("CheckButton", "markerSyncButton", MarkerFramePage, "ChatConfigCheckButtonTemplate")
    markerTransparentButton:SetPoint("TOPLEFT", 220, -389)
    markerTransparentButton:SetChecked(DMToolsMarkerTransparent)
    markerTransparentButton.tooltip = L["Marker Transparent Tooltip"]
    local markerTransparentText = MarkerFramePage:CreateFontString(nil, "OVERLAY")
    markerTransparentText:SetFontObject("GameFontNormal")
    markerTransparentText:SetPoint("TOPLEFT", 248, -395)
    markerTransparentText:SetText(L["Marker Trans?"])
    markerTransparentButton:SetScript("OnClick", function(self)
        if self:GetChecked() then
            DMToolsMarkerTransparent = true
            MarkerFrame:Hide()
            for i = 1 , 8 do
                if markers[i].hidden == true  then
                    DMToolsMarkerIcon[i]:Hide()
                end
            end
        else
            DMToolsMarkerTransparent = false
            MarkerFrame:Show()
            for i = 1 , 8 do
                DMToolsMarkerIcon[i]:Show()
            end
         end
    end)

    -- FONCTION D'ENVOI DES MARQUEURS
    if IsInRaid() then
        channel = "RAID"
    end
    function DMToolsSendMarkers(id)
        if markerSync == true and (UnitInRaid("player") or UnitInParty("player")) and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
            C_ChatInfo.SendAddonMessage("DMTools", "MARKERS@" .. UnitName("player") .. "@" .. id .. "@" .. markers[id].name .. "@" .. markers[id].power .. "@" .. markers[id].health .. "@" .. markers[id].description .. "@" .. tostring(markers[id].hidden), channel)
        elseif markerSync == true and markers[id].hidden == false then
            markerSync = false
            markerSyncButton:SetChecked(markerSync)
        end

    end

    -- Création du ticker
    local function cycleSync()
        for i = 1 , 8 do
            C_Timer.After(i*2, function()
            DMToolsSendMarkers(i)
            end)
        end
    end

    local ticker = C_Timer.NewTicker(16, cycleSync)
end)
