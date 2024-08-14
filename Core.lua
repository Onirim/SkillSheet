-- Gestion de la localisation
local _, core = ...
local L = core.Locales[GetLocale()] or core.Locales["enUS"]
local version = C_AddOns.GetAddOnMetadata("DMTools", "Version")
-- Enregistrement du préfixe de l'addon
C_ChatInfo.RegisterAddonMessagePrefix("DMTools")

---------------
-- FONCTIONS --
---------------
function rollDice(dice)
    local count, sides = dice:match("(%d*)d(%d+)")
    local bonus = dice:match("d%d+%+(%d+)")
    local malus = dice:match("d%d+-(%d+)")
    if count == nil or sides == nil then
        return dice
    else
        count = tonumber(count) or 1
        sides = tonumber(sides)
        bonus = tonumber(bonus) or 0
        malus = tonumber(malus) or 0
        local total = bonus - malus
        for i = 1, count do
            total = total + math.random(sides)
        end
        return total
    end
end



-- Création du bouton de minimap

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
local icon = LibStub("LibDBIcon-1.0")
    if type(miniMapDb) ~= "table" then
        miniMapDb = {}
    end
    if type(miniMapDb.minimapIcon) ~= "table" then
        miniMapDb.minimapIcon = {}
    end
    DMToolsCreateMinimapButton(miniMapDb.minimapIcon)
end)

function DMToolsCreateMinimapButton()
    local ldb = LibStub("LibDataBroker-1.1")
    local minimapButton = ldb:NewDataObject('DMToolsMinimapIcon', { --rename this more unique to your addon
        type = "launcher",
        icon = 633008,
        OnClick = function(_, button)
            if button == "LeftButton" then
                if SkillFrame:IsVisible() then
                	SkillFrame:Hide()
                else
                	SkillFrame:Show()
                end
			elseif button == "RightButton" then
				if MarkerFramePage:IsVisible() then
					MarkerFramePage:Hide()
				else
					MarkerFramePage:Show()
				end
			end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("DMTools                                                   " .. version)
            tooltip:AddLine(" ")
            tooltip:AddLine(L["Open/Close PC panel button"])
			tooltip:AddLine(L["Open/Close NPC panel button"])
			tooltip:AddLine(L["More with /DMTools"])
        end,
    })
    local minimapIcon = LibStub("LibDBIcon-1.0")
    minimapIcon:Register('DMToolsMinimapIcon', minimapButton, miniMapDb) --last arg is usually a table in your saved variables so it remembers the positon
end

-----------------------
-- Variables mémoire --
-----------------------
DMToolsEditIsOpened = false
local lastSkillName = ""
local lastDiceRoll = ""
local lastDiceValue = ""
local lastCostRoll = ""
local lastCostValue = ""
local lastHealthValue = ""
local lastRessourceValue = ""
local nameColors = {}
local outputChannel = "DMTOOLS"
local orderedDescription = {}
local descriptionDetails = {}
DMToolsMarkerNames = {}
DMToolsMarkerPowers = {}
DMToolsMarkerHealth = {}
DMToolsMarkerDescription = {}
DMToolsMarkerIcon = {}
DMToolsSkillName = {}
DMToolsDiceValue = {}
DMToolsCostValue = {}
DMToolsRollButton = {}
DMToolsNewMySkills = {}
DMToolsMarkerTransparent = false
DMToolsPanelPosition = DMToolsPanelPosition or {}

------------------------------
--   CHARGEMENT FENETRES    --
------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	for nom, position in pairs(DMToolsPanelPosition) do
		local fenetre = _G[nom]
		if fenetre then
			fenetre:ClearAllPoints()
			fenetre:SetPoint(position.point, position.x, position.y)
		end
	end
end)



----------------------------
--   MESSAGE D'ACCUEIL    --
----------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    print("|cFFdaa520DMTools " .. version .. L["DMTools is loaded"])
end)

--------------------------------------------
-- ATTENTE DU CHARGEMENT DE LA SAUVEGARDE --
--------------------------------------------
local f = CreateFrame("Frame")
--local icon = LibStub("LibDBIcon-1.0")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", function(self, event)
    -- Vérifiez si MySkills est nil, si c'est le cas, initialisez-le à une table vide
    if MySkills == nil then
        MySkills = {}
		for i = 1, 45 do
		table.insert(MySkills, {id = i, name = "", roll = "", cost = "", description = "", isCategory = false})
		end
		-- Définir les valeurs par défaut pour la première compétence
        MySkills[1].name = L["First Skill"]
        MySkills[1].roll = L["First Roll"]
        MySkills[1].cost = L["First Cost"]
        MySkills[1].description = L["First Description"]
		MySkills[2].name = L["Second Skill"]
        MySkills[2].roll = L["Second Roll"]
        MySkills[2].cost = L["Second Cost"]
        MySkills[2].description = L["Second Description"]
		MySkills[3].name = L["Third Skill"]
        MySkills[3].roll = L["Third Roll"]
        MySkills[3].cost = L["Third Cost"]
        MySkills[3].description = L["Third Description"]
	end
	if healthValue == nil then
		healthValue = "10/10"
	end
	if ressourceValue == nil then
		ressourceValue = "10/10"
	end



	------------------------
	-- RETROCOMPATIBILITE --
	------------------------
	for i = 1 , 45 do
		-- Si le champ isCategory n'existe pas, initialisez-le à false
		if MySkills[i].isCategory == nil then
			MySkills[i].isCategory = false
		end
	end

		


	--------------------------
	-- INTERFACE PRINCIPALE --
	--------------------------

	-- Création du cadre
	local SkillFrame = CreateFrame("Frame", "SkillFrame", UIParent, "ButtonFrameTemplate")
	SkillFrame:SetTitle(L["DMTools Character and GM"])
	SkillFrame:SetPortraitToAsset("Interface\\ICONS\\inv_inscription_runescrolloffortitude_yellow")
	SkillFrame:SetSize(460, 600) -- Largeur, Hauteur
	SkillFrame:SetPoint("LEFT", 100, 60) -- Position sur l'écran
	SkillFrame:EnableMouse(true)
	SkillFrame:SetMovable(true)
	SkillFrame:RegisterForDrag("LeftButton")
	--SkillFrame:SetScript("OnDragStart", SkillFrame.StartMoving)
	--SkillFrame:SetScript("OnDragStop", SkillFrame.StopMovingOrSizing)
	SkillFrame:SetFrameStrata("BACKGROUND")
	SkillFrame.Inset:Hide()
	SkillFrame:Hide() -- A réactiver en PROD
	function SkillFrame:OnDragStop()
		self:StopMovingOrSizing()
		-- Enregistrer la nouvelle position dans la table
		local point, _, _, x, y = self:GetPoint()
		DMToolsPanelPosition[self:GetName()] = {point = point, x = x, y = y}
	end
	SkillFrame:SetScript("OnDragStart", SkillFrame.StartMoving)
	SkillFrame:SetScript("OnDragStop", SkillFrame.OnDragStop)
	

	-- Création du menu déroulant d'output
	local dropDownOutput = CreateFrame("Frame", "MyDropDownMenu", SkillFrame, "UIDropDownMenuTemplate")
	dropDownOutput:SetPoint("TOPLEFT", SkillFrame, "TOPLEFT", 315, -83)
	-- Liste des options du menu déroulant
	local items = {
		"DMTools",
		"Raid",
		"Party",
		"Emote",
		"Self"
	}

	-- Fonction pour gérer le changement de sélection
	local function OnClick(self)
		UIDropDownMenu_SetSelectedID(dropDownOutput, self:GetID())
		outputChannel = string.upper(self:GetText())
	end
	
	-- Fonction pour initialiser le menu déroulant
	local function initialize(self, level)
		local info = UIDropDownMenu_CreateInfo()
		for k,v in pairs(items) do
			info = UIDropDownMenu_CreateInfo()
			info.text = v
			info.value = v
			info.func = OnClick
			UIDropDownMenu_AddButton(info, level)
		end
	end
	-- Configuration du menu déroulant
	UIDropDownMenu_Initialize(dropDownOutput, initialize)
	UIDropDownMenu_SetWidth(dropDownOutput, 100);
	UIDropDownMenu_SetButtonWidth(dropDownOutput, 124)
	UIDropDownMenu_SetSelectedID(dropDownOutput, 1)
	UIDropDownMenu_JustifyText(dropDownOutput, "LEFT")
	-- Création du libellé du menu déroulant de sortie
	local outputLib = SkillFrame:CreateFontString(nil, "OVERLAY")
	outputLib:SetFontObject("GameFontNormal")
	outputLib:SetPoint("TOPLEFT", SkillFrame, "TOPLEFT", 335, -68)
	outputLib:SetText(L["Output Channel"])

	-- Création des entête de compétence du volet principal
	local tableHeaders = SkillFrame:CreateFontString(nil, "OVERLAY")
	tableHeaders:SetFontObject("GameFontNormal")
	tableHeaders:SetPoint("TOPLEFT", 10, - 120)
	tableHeaders:SetText(L["Skill Table Header"])
	-- Création de l'entête du tableau de suivi MJ
	local gmHeaders = SkillFrame:CreateFontString(nil, "OVERLAY")
	gmHeaders:SetFontObject("GameFontNormal")
	gmHeaders:SetPoint("TOPLEFT", 10, - 120)
	gmHeaders:SetText(L["GM Table Header"])
	gmHeaders:Hide()
	-- Création de la ligne de séparation
	local line = SkillFrame:CreateTexture(nil, "BACKGROUND")
	line:SetHeight(2)  -- Définit l'épaisseur de la ligne
	line:SetWidth(SkillFrame:GetWidth())  -- Définit la largeur de la ligne
	line:SetPoint("TOPLEFT", 0, - 135)  -- Positionne la ligne au centre de la frame
	line:SetColorTexture(1, 1, 1, 0.2)  -- Définit la couleur de la ligne (ici, blanc semi-transparent)

	-- Création de la page 1
	local SkillFramePage1 = CreateFrame("Frame", nil, SkillFrame)
	SkillFramePage1:SetSize(460, 600)
	SkillFramePage1:SetPoint("CENTER", 0, 0)  -- Positionne la frame au centre de l'écran
	-- Création de la texture de fond
	local bg = SkillFramePage1:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
	bg:SetColorTexture(0, 0, 0, 0)  -- Définit la texture comme transparente
	-- Création de la page 2
	local SkillFramePage2 = CreateFrame("Frame", nil, SkillFrame)
	SkillFramePage2:SetSize(460, 600)
	SkillFramePage2:SetPoint("CENTER", 0, 0)  -- Positionne la frame au centre de l'écran
	-- Création de la texture de fond
	local bg = SkillFramePage2:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
	bg:SetColorTexture(0, 0, 0, 0)  -- Définit la texture comme transparente
	SkillFramePage2:Hide()
	-- Création de la page 3
	local SkillFramePage3 = CreateFrame("Frame", nil, SkillFrame)
	SkillFramePage3:SetSize(460, 600)
	SkillFramePage3:SetPoint("CENTER", 0, 0)  -- Positionne la frame au centre de l'écran
	-- Création de la texture de fond
	local bg = SkillFramePage3:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
	bg:SetColorTexture(0, 0, 0, 0)  -- Définit la texture comme transparente
	SkillFramePage3:Hide()
	-- Création de la page MJ
	local SkillFrameGM = CreateFrame("Frame", nil, SkillFrame)
	SkillFrameGM:SetSize(460, 600)
	SkillFrameGM:SetPoint("CENTER", 0, 0)  -- Positionne la frame au centre de l'écran
	-- Création de la texture de fond
	local bg = SkillFrameGM:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
	bg:SetColorTexture(0, 0, 0, 0)  -- Définit la texture comme transparente
	SkillFrameGM:Hide()
	
	----------------------
	-- TABLEAU SUIVI GM --
	----------------------
	local players = {}

	-- Création de la table d'affichage des noms
	local displayTableName = SkillFrameGM:CreateFontString(nil, "OVERLAY")
	displayTableName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	displayTableName:SetPoint("TOP", SkillFrameGM, "BOTTOM", -222, 455)
	displayTableName:SetJustifyH("LEFT")
	displayTableName:SetJustifyV("TOP")
	displayTableName:SetText("")
	displayTableName:SetWidth(200)
	-- Création de la table d'affichage des compétences
	local displayTableSkillName = SkillFrameGM:CreateFontString(nil, "OVERLAY")
	displayTableSkillName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	displayTableSkillName:SetPoint("TOP", SkillFrameGM, "BOTTOM", -140, 455)
	displayTableSkillName:SetJustifyH("CENTER")
	displayTableSkillName:SetJustifyV("TOP")
	displayTableSkillName:SetText("")
	displayTableSkillName:SetWidth(300)
	-- Création de la table d'affichage du jet + valeur
	local displayTableRoll = SkillFrameGM:CreateFontString(nil, "OVERLAY")
	displayTableRoll:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	displayTableRoll:SetPoint("TOP", SkillFrameGM, "BOTTOM", 10, 455)
	displayTableRoll:SetJustifyH("CENTER")
	displayTableRoll:SetJustifyV("TOP")
	displayTableRoll:SetText("")
	displayTableRoll:SetWidth(150)
	-- Création de la table d'affichage des jets de ressources
	local displayTableRessource = SkillFrameGM:CreateFontString(nil, "OVERLAY")
	displayTableRessource:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	displayTableRessource:SetPoint("TOP", SkillFrameGM, "BOTTOM", 114, 455)
	displayTableRessource:SetJustifyH("CENTER")
	displayTableRessource:SetJustifyV("TOP")
	displayTableRessource:SetText("")
	displayTableRessource:SetWidth(150)
	-- Création de la table d'affichage de la santé
	local displayTableHealthValue = SkillFrameGM:CreateFontString(nil, "OVERLAY")
	displayTableHealthValue:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	displayTableHealthValue:SetPoint("TOP", SkillFrameGM, "BOTTOM", 209, 455)
	displayTableHealthValue:SetJustifyH("CENTER")
	displayTableHealthValue:SetJustifyV("TOP")
	displayTableHealthValue:SetText("")
	displayTableHealthValue:SetWidth(100)
	-- Création de la table d'affichage de la ressource
	local displayTableRessourceValue = SkillFrameGM:CreateFontString(nil, "OVERLAY")
	displayTableRessourceValue:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	displayTableRessourceValue:SetPoint("TOP", SkillFrameGM, "BOTTOM", 280, 455)
	displayTableRessourceValue:SetJustifyH("CENTER")
	displayTableRessourceValue:SetJustifyV("TOP")
	displayTableRessourceValue:SetText("")
	displayTableRessourceValue:SetWidth(100)

	-- Tableau pour stocker les frames de ligne et leurs tooltips associés
	local lineFrames = {}
	local tooltips = {}

	-- Création des frames de ligne et des tooltips associés
	for i = 1 , 19 do
		local lineFrame = CreateFrame("Frame", nil, SkillFrameGM)
		lineFrame:SetSize(175, 16) -- Ajustez la taille en fonction de votre ligne
		-- Ajustez la position en fonction de votre ligne et de l'index
		lineFrame:SetPoint("TOPLEFT", displayTableName, "TOPLEFT", 100, -i * 24 +25)
		lineFrame:EnableMouse(true)

		-- Création de la texture
		local texture = lineFrame:CreateTexture(nil, "BACKGROUND")
		texture:SetAllPoints()
		texture:SetColorTexture(1, 1, 1, 0) -- Les quatre paramètres sont Rouge, Vert, Bleu et Alpha (transparence)

		
		local tooltip = CreateFrame("GameTooltip", "MyTooltip"..i, SkillFrameGM, "GameTooltipTemplate")
		-- Stocker le tooltip dans la frame pour pouvoir y accéder plus tard
		lineFrame.tooltip = tooltip
		-- Ajouter la frame et le tooltip aux tableaux
		lineFrames[i] = lineFrame
		tooltips[i] = tooltip
	end

	

	-- Tableau pour stocker les frames de ligne
	local function generateTooltips()
		for i = 1 , 19 do
			-- Utiliser la frame et le tooltip existants
			local lineFrame = lineFrames[i]
			local tooltip = tooltips[i]

			-- Affichage du tooltip lors du survol
			lineFrame:SetScript("OnEnter", function(self)
				tooltip:SetOwner(self, "ANCHOR_TOP")  -- Définir le propriétaire du tooltip ici
				tooltip:ClearLines()
				if orderedDescription[i] ~= nil then
				tooltip:SetMinimumWidth(400)
				local concatenateDescription = ""
				for _, detail in ipairs(descriptionDetails) do
					if detail.name == orderedDescription[i].name and detail.descSkillID == orderedDescription[i].skillID then
						concatenateDescription = concatenateDescription .. detail.descriptionPart
					end
				end
				tooltip:AddLine(concatenateDescription, 1, 1, 1, true)
				tooltip:Show()
				end
			end)
			
		
			-- Cacher le tooltip lorsque la souris quitte la frame
			lineFrame:SetScript("OnLeave", function(self)
				tooltip:Hide()
			end)
		
		end
	end



	-- Mise à jour de la table
	
	local function updateDisplayTable()
	orderedDescription = {}
	local displayName = displayName or ""
	local displaySkillName = displaySkillName or ""
	local displayRoll = displayRoll or ""
	local displayRessource = displayRessource or ""
	local displayHealthValue = displayHealthValue or ""
	local displayRessourceValue = displayRessourceValue or ""
		for name, player in pairs(players) do
			local color = nameColors[name] or "|cFF52BE80"
			displayName = displayName .. color .. string.sub(string.format("%-12s",name),1,12) .. "\n\n"
			local skillName = player.skillName or ""
			displaySkillName = displaySkillName .. skillName .. "\n\n"
			local diceRoll = player.diceRoll or ""
			local diceValue = player.diceValue or ""
			if diceRoll == diceValue then
				displayRoll = displayRoll .. diceRoll .. "\n\n"
			else
				diceValue = ("(" .. diceValue .. ")")
				displayRoll = displayRoll .. diceRoll .. " " .. diceValue .. "\n\n"
			end
			local costRoll = player.costRoll or ""
			local costValue = player.costValue or ""
			if costRoll == costValue then
				displayRessource = displayRessource .. costRoll .. "\n\n"
			else
				costValue = ("(" .. costValue .. ")")
				displayRessource = displayRessource .. costRoll .. " " .. costValue .. "\n\n"
			end
			local healthValue = player.healthValue or ""
			displayHealthValue = displayHealthValue .. healthValue .. "\n\n"
			local ressourceValue = player.ressourceValue or ""
			displayRessourceValue = displayRessourceValue .. ressourceValue .. "\n\n"
			if skillName ~= "" then
				table.insert(orderedDescription, {name = name, skillID = player.skillID}) -- insertion de l'ordre des joueurs dans une table
			else
				table.insert(orderedDescription, {name = name, skillID = 0})
			end
		end
		displayTableName:SetText(displayName)
		displayTableSkillName:SetText(displaySkillName)
		displayTableRoll:SetText(displayRoll)
		displayTableRessource:SetText(displayRessource)
		displayTableHealthValue:SetText(displayHealthValue)
		displayTableRessourceValue:SetText(displayRessourceValue)
		generateTooltips()
	end

	

	

	-- Création de la boîte de dialogue de confirmation de nouveau tour joueur
	local confirmNewTurn = CreateFrame("Frame", "confirmNewTurn", SkillFrameGM, "ButtonFrameTemplate")
	ButtonFrameTemplate_HideButtonBar(confirmNewTurn)
	ButtonFrameTemplate_HidePortrait(confirmNewTurn)
	confirmNewTurn.Inset:Hide() 
	confirmNewTurn:SetSize(400, 100)
	confirmNewTurn:SetPoint("CENTER", SkillFrameGM, "CENTER", 300, 55)
	confirmNewTurn:Hide()
	confirmNewTurn:SetFrameStrata("HIGH")

	local confirmNewTurnText = confirmNewTurn:CreateFontString(nil, "OVERLAY")
	confirmNewTurnText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	confirmNewTurnText:SetPoint("CENTER")
	confirmNewTurnText:SetText(L["Confirm new turn"])

	local yesNewTurn = CreateFrame("Button", nil, confirmNewTurn, "GameMenuButtonTemplate")
	yesNewTurn:SetPoint("BOTTOMLEFT", confirmNewTurn, "BOTTOM", 10, 10)
	yesNewTurn:SetSize(80, 25)
	yesNewTurn:SetText(L["Yes"])
	yesNewTurn:SetScript("OnClick", function()
		local playerName = UnitName("player") -- Obtient le nom du joueur
			local status, result = pcall(function() return
				AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
				if status then
					playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
				end
			C_ChatInfo.SendAddonMessage("DMTools", "TURN@" .. playerName .. "@" .. "@" .. "@" .. "@" .. "@" .. "@" .. "@", channel)
			if outputChannel ~= "DMTOOLS" and outputChannel ~= "RAID" and outputChannel ~= "SELF" then
				SendChatMessage(L["has started a new turn"], outputChannel )
			elseif outputChannel == "RAID" then
				SendChatMessage(playerName .. L["has started a new turn"], "RAID_WARNING")
			end
			confirmNewTurn:Hide()
	end)

	local NoNewTurn = CreateFrame("Button", nil, confirmNewTurn, "GameMenuButtonTemplate")
	NoNewTurn:SetPoint("BOTTOMRIGHT", confirmNewTurn, "BOTTOM", -10, 10)
	NoNewTurn:SetSize(80, 25)
	NoNewTurn:SetText(L["No"])
	NoNewTurn:SetScript("OnClick", function()
		confirmNewTurn:Hide()
	end)

	-- Création du bouton de nouveau tour joueur
	local newTurnButton = CreateFrame("Button", nil, SkillFrameGM, "GameMenuButtonTemplate")
	newTurnButton:SetPoint("TOPLEFT", 440, -30)
	newTurnButton:SetSize(110, 25)
	newTurnButton:SetText(L["Player Turn"])
	newTurnButton:SetScript("OnClick", function()
		if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
			confirmNewTurn:Show()
		else
			print(L["You need to be leader or assist"])
		end
	end)

	-- Création de la boîte de dialogue de confirmation de nouveau tour ennemi
	local confirmNewEnemyTurn = CreateFrame("Frame", "confirmNewEnemyTurn", SkillFrameGM, "ButtonFrameTemplate")
	ButtonFrameTemplate_HideButtonBar(confirmNewEnemyTurn)
	ButtonFrameTemplate_HidePortrait(confirmNewEnemyTurn)
	confirmNewEnemyTurn.Inset:Hide() 
	confirmNewEnemyTurn:SetSize(400, 100)
	confirmNewEnemyTurn:SetPoint("CENTER", SkillFrameGM, "CENTER", 300, -55)
	confirmNewEnemyTurn:Hide()
	confirmNewEnemyTurn:SetFrameStrata("HIGH")

	local confirmNewEnemyTurnText = confirmNewEnemyTurn:CreateFontString(nil, "OVERLAY")
	confirmNewEnemyTurnText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	confirmNewEnemyTurnText:SetPoint("CENTER")
	confirmNewEnemyTurnText:SetText(L["Confirm new enemy turn"])

	local yesNewEnemyTurn = CreateFrame("Button", nil, confirmNewEnemyTurn, "GameMenuButtonTemplate")
	yesNewEnemyTurn:SetPoint("BOTTOMLEFT", confirmNewEnemyTurn, "BOTTOM", 10, 10)
	yesNewEnemyTurn:SetSize(80, 25)
	yesNewEnemyTurn:SetText(L["Yes"])
	yesNewEnemyTurn:SetScript("OnClick", function()
		local playerName = UnitName("player") -- Obtient le nom du joueur
			local status, result = pcall(function() return
				AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
				if status then
					playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
				end
			C_ChatInfo.SendAddonMessage("DMTools", "ENEMY@" .. playerName .. "@" .. "@" .. "@" .. "@" .. "@" .. "@" .. "@", channel)
			if outputChannel ~= "DMTOOLS" and outputChannel ~= "RAID" and outputChannel ~= "SELF" then
				SendChatMessage(L["has started a new enemy turn"], outputChannel )
			elseif outputChannel == "RAID" then
				SendChatMessage(playerName .. L["has started a new enemy turn"], "RAID_WARNING")
			end
			confirmNewEnemyTurn:Hide()
	end)

	local NoNewEnemyTurn = CreateFrame("Button", nil, confirmNewEnemyTurn, "GameMenuButtonTemplate")
	NoNewEnemyTurn:SetPoint("BOTTOMRIGHT", confirmNewEnemyTurn, "BOTTOM", -10, 10)
	NoNewEnemyTurn:SetSize(80, 25)
	NoNewEnemyTurn:SetText(L["No"])
	NoNewEnemyTurn:SetScript("OnClick", function()
		confirmNewEnemyTurn:Hide()
	end)

	-- Création du bouton de nouveau tour ennemi
	local newEnemyTurnButton = CreateFrame("Button", nil, SkillFrameGM, "GameMenuButtonTemplate")
	newEnemyTurnButton:SetPoint("TOPLEFT", 440, -55)
	newEnemyTurnButton:SetSize(110, 25)
	newEnemyTurnButton:SetText(L["Enemy Turn"])
	newEnemyTurnButton:SetScript("OnClick", function()
		if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
			confirmNewEnemyTurn:Show()
		else
			print(L["You need to be leader or assist"])
		end
	end)

	-- Création de la boîte de dialogue de confirmation de nouveau tour libre
	local confirmNewFreeTurn = CreateFrame("Frame", "confirmNewFreeTurn", SkillFrameGM, "ButtonFrameTemplate")
	ButtonFrameTemplate_HideButtonBar(confirmNewFreeTurn)
	ButtonFrameTemplate_HidePortrait(confirmNewFreeTurn)
	confirmNewFreeTurn.Inset:Hide() 
	confirmNewFreeTurn:SetSize(400, 100)
	confirmNewFreeTurn:SetPoint("CENTER", SkillFrameGM, "CENTER", 300, -55)
	confirmNewFreeTurn:Hide()
	confirmNewFreeTurn:SetFrameStrata("HIGH")

	local confirmNewFreeTurnText = confirmNewFreeTurn:CreateFontString(nil, "OVERLAY")
	confirmNewFreeTurnText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	confirmNewFreeTurnText:SetPoint("CENTER")
	confirmNewFreeTurnText:SetText(L["Confirm new free turn"])

	local yesNewFreeTurn = CreateFrame("Button", nil, confirmNewFreeTurn, "GameMenuButtonTemplate")
	yesNewFreeTurn:SetPoint("BOTTOMLEFT", confirmNewFreeTurn, "BOTTOM", 10, 10)
	yesNewFreeTurn:SetSize(80, 25)
	yesNewFreeTurn:SetText(L["Yes"])
	yesNewFreeTurn:SetScript("OnClick", function()
		local playerName = UnitName("player") -- Obtient le nom du joueur
			local status, result = pcall(function() return
				AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
				if status then
					playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
				end
			C_ChatInfo.SendAddonMessage("DMTools", "FREE@" .. playerName .. "@" .. "@" .. "@" .. "@" .. "@" .. "@" .. "@", channel)
			if outputChannel ~= "DMTOOLS" and outputChannel ~= "RAID" and outputChannel ~= "SELF" then
				SendChatMessage(L["has started a new free turn"], outputChannel )
			elseif outputChannel == "RAID" then
				SendChatMessage(playerName .. L["has started a new free turn"], "RAID_WARNING")
			end
			confirmNewFreeTurn:Hide()
	end)

	local NoNewFreeTurn = CreateFrame("Button", nil, confirmNewFreeTurn, "GameMenuButtonTemplate")
	NoNewFreeTurn:SetPoint("BOTTOMRIGHT", confirmNewFreeTurn, "BOTTOM", -10, 10)
	NoNewFreeTurn:SetSize(80, 25)
	NoNewFreeTurn:SetText(L["No"])
	NoNewFreeTurn:SetScript("OnClick", function()
		confirmNewFreeTurn:Hide()
	end)

	-- Création du bouton de nouveau tour libre
	local newFreeTurnButton = CreateFrame("Button", nil, SkillFrameGM, "GameMenuButtonTemplate")
	newFreeTurnButton:SetPoint("TOPLEFT", 440, -80)
	newFreeTurnButton:SetSize(110, 25)
	newFreeTurnButton:SetText(L["Free Turn"])
	newFreeTurnButton:Disable()
	newFreeTurnButton:SetScript("OnClick", function()
		if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
			confirmNewFreeTurn:Show()
		else
			print(L["You need to be leader or assist"])
		end
	end)	


----------------------------------
-- Liste des compétences page 1 --
----------------------------------

	for i = 1, 15 do
	
		-- Nom de la compétence
		local skillName = SkillFramePage1:CreateFontString(nil, "OVERLAY")
		skillName:SetFontObject("GameFontNormal")
		skillName:SetPoint("TOPLEFT", 10, -30 * i - 120)
		if MySkills[i].isCategory == true then
			skillName:SetText("|cFFCAA94B" .. string.upper(MySkills[i].name))
			skillName:SetFontObject("GameFontNormalLarge")
		else 
			skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
			skillName:SetFontObject("GameFontNormal")
		end
		DMToolsSkillName[i] = skillName
			
		-- Valeur du dé
		local diceValue = SkillFramePage1:CreateFontString(nil, "OVERLAY")
		diceValue:SetFontObject("GameFontNormal")
		diceValue:SetPoint("TOPLEFT", 210, -30 * i - 120)
		diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
		DMToolsDiceValue[i] = diceValue
		
		-- Valeur du coût
		local costValue = SkillFramePage1:CreateFontString(nil, "OVERLAY")
		costValue:SetFontObject("GameFontNormal")
		costValue:SetPoint("TOPLEFT", 310, -30 * i - 120)
		costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
		DMToolsCostValue[i] = costValue
	
		-- Bouton de roll
		local rollButton = CreateFrame("Button", nil, SkillFramePage1, "GameMenuButtonTemplate")
		local playerName = UnitName("player") -- Obtient le nom du joueur
		DMToolsRollButton[i] = rollButton
		rollButton:SetPoint("TOPLEFT", 380, -30 * i - 115)
		rollButton:SetSize(50, 25)
		rollButton:SetText(L["Roll"])
		rollButton:SetScript("OnClick", function()
			PlaySound(36627)
			local status, result = pcall(function() return
			AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
			if status then
				playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
			end
			lastSkillName = MySkills[i].name
			lastDiceRoll = rollDice(MySkills[i].roll)
			lastDiceValue = MySkills[i].roll
			lastCostRoll = rollDice(MySkills[i].cost)
			lastCostValue = MySkills[i].cost
			if IsInRaid() then
				channel = "RAID"
			end
			C_ChatInfo.SendAddonMessage("DMTools", "ROLL@" .. playerName .. "@" .. MySkills[i].name .. "@" .. lastDiceRoll .. "@" .. MySkills[i].roll .. "@" .. lastCostRoll .. "@" .. MySkills[i].cost .. "@" .. healthValue .. "@" .. ressourceValue .. "@" .. i, channel)
			-- découpage de la description en plusieurs parties
			local length = string.len(MySkills[i].description)
			local start = 1
			local partID = 1
			while start < length do
				local subStr = string.sub(MySkills[i].description, start, start + 150)
				C_ChatInfo.SendAddonMessage("DMTools", "DESC@" .. playerName .. "@" .. i .. "@" .. partID .. "@" ..  subStr, channel)
				start = start +151
				partID = partID +1
			end
			-- partie gérant l'affichage de la notification en emote ou en communication interne
			local displayRoll = "" -- a utiliser pour l'affichage
			local displayRollValue = "" -- temporaire
			local displayCost = "" -- a utiliser pour l'affichage
			local displayCostValue = "" -- temporaire
			if lastDiceRoll == MySkills[i].roll then
				displayRoll = lastDiceRoll
			else
				displayRollValue = ("(" .. MySkills[i].roll .. ")")
				displayRoll = displayRoll .. lastDiceRoll .. " " .. displayRollValue
			end
			if lastCostRoll == MySkills[i].cost then
				displayCost = displayCost .. lastCostRoll
			else
				displayCostValue = ("(" .. MySkills[i].cost .. ")")
				displayCost = displayCost .. lastCostRoll .. " " .. displayCostValue
			end
			local emoteChatMessage = (L["use the skill"] .. MySkills[i].name .. (displayRoll ~= "" and L[", Roll "] or "") .. displayRoll .. (displayCost ~= "" and L[", cost "] or "") .. displayCost)
			if IsInGroup() or IsInRaid() then
				if IsInRaid() then
					channel = "RAID"
				end
				C_ChatInfo.SendAddonMessage("DMTools", "EMOTE@" .. playerName .. " " .. emoteChatMessage .. "@" .. "@" .. "@" .. "@" .. "@", channel)
			end
			if outputChannel ~= "DMTOOLS" and outputChannel ~= "SELF" then
				SendChatMessage(emoteChatMessage, outputChannel )
			elseif outputChannel == "SELF" then
				print(playerName .. " " .. emoteChatMessage)
			end
		end)
		if MySkills[i].name == "" or MySkills[i].isCategory == true then
			rollButton:Hide()
		end
		
		-- Bouton d'édition		
		local editButton = CreateFrame("Button", nil, SkillFramePage1, "GameMenuButtonTemplate")
		editButton:SetPoint("TOPLEFT", 432, -30 * i - 115)
		editButton:SetSize(25, 25)
		editButton:SetText("?")
		editButton:SetScript("OnClick", function()
			if DMToolsEditIsOpened == false then
				DMToolsEditIsOpened = true
				-- Création de la fenêtre d'édition de compétence
				local editFrame = CreateFrame("Frame", "editFrame", UIParent, "ButtonFrameTemplate")
				editFrame:SetFrameStrata("HIGH")
				editFrame:SetTitle(L["Skill Edit"])
				editFrame:SetSize(400, 330) -- Largeur, Hauteur
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
				-- Zone de texte pour le nom de la compétence
				local editSkillName = editFrame:CreateFontString(nil, "OVERLAY")
				editSkillName:SetFontObject("GameFontNormal")
				editSkillName:SetPoint("TOPLEFT", 11, -30)
				editSkillName:SetText(L["Skill Name"])
				-- Zone de saisie pour le nom de la compétence
				local skillNameBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				skillNameBox:SetSize(180, 20)
				skillNameBox:SetPoint("TOPLEFT", 15, -50)
				skillNameBox:SetAutoFocus(false)
				skillNameBox:SetText(MySkills[i].name)
				skillNameBox:SetMaxLetters(30)
				-- Zone de texte pour la valeur du dé
				local editDiceRoll = editFrame:CreateFontString(nil, "OVERLAY")
				editDiceRoll:SetFontObject("GameFontNormal")
				editDiceRoll:SetPoint("TOPLEFT", 210, -30)
				editDiceRoll:SetText(L["Dice"])
				-- Zone de saisie pour la valeur du dé
				local diceValueBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				diceValueBox:SetSize(80, 20)
				diceValueBox:SetPoint("TOPLEFT", 212, -50)
				diceValueBox:SetAutoFocus(false)
				diceValueBox:SetText(MySkills[i].roll)
				diceValueBox:SetMaxLetters(12)
				-- Zone de texte pour le coût
				local editTextCost = editFrame:CreateFontString(nil, "OVERLAY")
				editTextCost:SetFontObject("GameFontNormal")
				editTextCost:SetPoint("TOPLEFT", 308, -30)
				editTextCost:SetText(L["Cost"])
				-- Zone de saisie pour le coût
				local CostValueBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				CostValueBox:SetSize(80, 20)
				CostValueBox:SetPoint("TOPLEFT", 310, -50)
				CostValueBox:SetAutoFocus(false)
				CostValueBox:SetText(MySkills[i].cost)
				CostValueBox:SetMaxLetters(10)
				-- Zone de texte pour la description de la compétence
				local editSkillDescription = editFrame:CreateFontString(nil, "OVERLAY")
				editSkillDescription:SetFontObject("GameFontNormal")
				editSkillDescription:SetPoint("TOPLEFT", 10, -80)
				editSkillDescription:SetText(L["Skill Description"])
				-- Création de la frame de fond pour la description de la compétence
				local skillDescriptionBackground = CreateFrame("Frame", nil, editFrame)
				skillDescriptionBackground:SetSize(380, 195)  -- Définit la taille de la frame
				skillDescriptionBackground:SetPoint("TOPLEFT", 13, -100)  -- Positionne la frame au centre de l'écran
				-- Création de la texture de fond
				local bg = skillDescriptionBackground:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
				bg:SetColorTexture(0, 0, 0, 0.5)  -- Définit la texture comme transparente
				-- Zone de saisie pour la description de la compétence
				local skillDescriptionBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
				skillDescriptionBox:SetMultiLine(true)
				skillDescriptionBox.Left:Hide()
				skillDescriptionBox.Middle:Hide()
				skillDescriptionBox.Right:Hide()
				skillDescriptionBox:SetWidth(378)
				skillDescriptionBox:SetHeight(200)
				skillDescriptionBox:SetPoint("TOPLEFT", 15, -105)
				skillDescriptionBox:SetAutoFocus(false)
				skillDescriptionBox:SetText(MySkills[i].description)
				-- Coche Catégorie
				local categoryCheckButton = CreateFrame("CheckButton", "categoryCheckButton", editFrame, "ChatConfigCheckButtonTemplate")
				categoryCheckButton:SetPoint("TOPLEFT", 369, -75)
				categoryCheckButton:SetChecked(MySkills[i].isCategory)
				categoryCheckButton.tooltip = L["Category? Tooltip"]
				local categoryCheckText = editFrame:CreateFontString(nil, "OVERLAY")
				categoryCheckText:SetFontObject("GameFontNormal")
				categoryCheckText:SetPoint("TOPLEFT", 292, -80)
				categoryCheckText:SetText(L["Category?"])
				local isCategoryCheck = MySkills[i].isCategory
				categoryCheckButton:SetScript("OnClick", function(self)
					if self:GetChecked() then
						isCategoryCheck = true
					else
						isCategoryCheck = false
					end
				end)
				-- Bouton "Enregistrer"
				local saveButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
				saveButton:SetPoint("TOPLEFT", 214, -300)
				saveButton:SetSize(180, 25)
				saveButton:SetText(L["Save"])
				saveButton:SetScript("OnClick", function()
					-- Enregistrement de la compétence ici
					local skillNameText = skillNameBox:GetText()
					local diceValueText = diceValueBox:GetText()
					local costValueText = CostValueBox:GetText()
					local descriptionValueText = skillDescriptionBox:GetText()
					-- Ajoutez le code pour enregistrer la compétence dans votre base de données locale ici
					MySkills[i].name = skillNameText
					MySkills[i].roll = diceValueText
					MySkills[i].cost = costValueText
					MySkills[i].description = descriptionValueText
					MySkills[i].isCategory = isCategoryCheck
					skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
					diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
					costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
					if MySkills[i].name == "" or MySkills[i].isCategory == true then
						rollButton:Hide()
						else 
						rollButton:Show()
					end
					if MySkills[i].isCategory == true then
						skillName:SetText("|cFFCAA94B" .. string.upper(MySkills[i].name))
						skillName:SetFontObject("GameFontNormalLarge")
					else 
						skillName:SetFontObject("GameFontNormal")
					end
				editFrame:Hide()
				end)
				-- Bouton "Supprimer"
				local deleteButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
				deleteButton:SetPoint("TOPLEFT", 10, -300)
				deleteButton:SetSize(120, 25)
				deleteButton:SetText(L["Delete"])
				deleteButton:SetScript("OnClick", function()
					MySkills[i].name = ""
					MySkills[i].roll = ""
					MySkills[i].cost = ""
					MySkills[i].description = ""
					MySkills[i].isCategory = false
					skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
					diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
					costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
					rollButton:Hide()
				editFrame:Hide()
				end)
			end
		end)

	end

----------------------------------
-- Liste des compétences page 2 --
----------------------------------

for i = 16, 30 do
	local j = i - 15
	-- Nom de la compétence
	local skillName = SkillFramePage2:CreateFontString(nil, "OVERLAY")
	skillName:SetFontObject("GameFontNormal")
	skillName:SetPoint("TOPLEFT", 10, -30 * j - 120)
	if MySkills[i].isCategory == true then
		skillName:SetText("|cFFCAA94B" .. string.upper(MySkills[i].name))
		skillName:SetFontObject("GameFontNormalLarge")
	else 
		skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
		skillName:SetFontObject("GameFontNormal")
	end
	DMToolsSkillName[i] = skillName

	-- Valeur du dé
	local diceValue = SkillFramePage2:CreateFontString(nil, "OVERLAY")
	diceValue:SetFontObject("GameFontNormal")
	diceValue:SetPoint("TOPLEFT", 210, -30 * j - 120)
	diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
	DMToolsDiceValue[i] = diceValue
	
	-- Valeur du coût
	local costValue = SkillFramePage2:CreateFontString(nil, "OVERLAY")
	costValue:SetFontObject("GameFontNormal")
	costValue:SetPoint("TOPLEFT", 310, -30 * j - 120)
	costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
	DMToolsCostValue[i] = costValue

	-- Bouton de roll
	local rollButton = CreateFrame("Button", nil, SkillFramePage2, "GameMenuButtonTemplate")
	local playerName = UnitName("player") -- Obtient le nom du joueur
	DMToolsRollButton[i] = rollButton
	rollButton:SetPoint("TOPLEFT", 380, -30 * j - 115)
	rollButton:SetSize(50, 25)
	rollButton:SetText("Roll")
	rollButton:SetScript("OnClick", function()
		PlaySound(36627)
		local status, result = pcall(function() return
		AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
		if status then
			playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
		end
		lastSkillName = MySkills[i].name
		lastDiceRoll = rollDice(MySkills[i].roll)
		lastDiceValue = MySkills[i].roll
		lastCostRoll = rollDice(MySkills[i].cost)
		lastCostValue = MySkills[i].cost
		if IsInRaid() then
			channel = "RAID"
		end
		C_ChatInfo.SendAddonMessage("DMTools", "ROLL@" .. playerName .. "@" .. MySkills[i].name .. "@" .. lastDiceRoll .. "@" .. MySkills[i].roll .. "@" .. lastCostRoll .. "@" .. MySkills[i].cost .. "@" .. healthValue .. "@" .. ressourceValue .. "@" .. i, channel)
			-- découpage de la description en plusieurs parties
			local length = string.len(MySkills[i].description)
			local start = 1
			local partID = 1
			while start < length do
				local subStr = string.sub(MySkills[i].description, start, start + 150)
				C_ChatInfo.SendAddonMessage("DMTools", "DESC@" .. playerName .. "@" .. i .. "@" .. partID .. "@" ..  subStr, channel)
				start = start +151
				partID = partID +1
			end
		-- partie gérant l'affichage de la notification en emote ou en communication interne
		local displayRoll = "" -- a utiliser pour l'affichage
		local displayRollValue = "" -- temporaire
		local displayCost = "" -- a utiliser pour l'affichage
		local displayCostValue = "" -- temporaire
		if lastDiceRoll == MySkills[i].roll then
			displayRoll = lastDiceRoll
		else
			displayRollValue = ("(" .. MySkills[i].roll .. ")")
			displayRoll = displayRoll .. lastDiceRoll .. " " .. displayRollValue
		end
		if lastCostRoll == MySkills[i].cost then
			displayCost = displayCost .. lastCostRoll
		else
			displayCostValue = ("(" .. MySkills[i].cost .. ")")
			displayCost = displayCost .. lastCostRoll .. " " .. displayCostValue
		end
		local emoteChatMessage = (L["use the skill"] .. MySkills[i].name .. (displayRoll ~= "" and L[", Roll "] or "") .. displayRoll .. (displayCost ~= "" and L[", cost "] or "") .. displayCost)
		if IsInGroup() or IsInRaid() then
			if IsInRaid() then
				channel = "RAID"
			end
			C_ChatInfo.SendAddonMessage("DMTools", "EMOTE@" .. playerName .. " " .. emoteChatMessage .. "@" .. "@" .. "@" .. "@" .. "@", channel)
		end
		if outputChannel ~= "DMTOOLS" and outputChannel ~= "SELF" then
			SendChatMessage(emoteChatMessage, outputChannel )
		elseif outputChannel == "SELF" then
			print(playerName .. " " .. emoteChatMessage)
		end
	end)
	if MySkills[i].name == "" or MySkills[i].isCategory == true then
		rollButton:Hide()
	end
	
	-- Bouton d'édition
	DMToolsEditIsOpened = false
	local editButton = CreateFrame("Button", nil, SkillFramePage2, "GameMenuButtonTemplate")
	editButton:SetPoint("TOPLEFT", 432, -30 * j - 115)
	editButton:SetSize(25, 25)
	editButton:SetText("?")
	editButton:SetScript("OnClick", function()
		if DMToolsEditIsOpened == false then
			DMToolsEditIsOpened = true
			-- Création de la fenêtre d'édition de compétence
			local editFrame = CreateFrame("Frame", "editFrame", UIParent, "ButtonFrameTemplate")
			editFrame:SetFrameStrata("HIGH")
			editFrame:SetTitle(L["Skill Edit"])
			editFrame:SetSize(400, 330) -- Largeur, Hauteur
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
			-- Zone de texte pour le nom de la compétence
			local editSkillName = editFrame:CreateFontString(nil, "OVERLAY")
			editSkillName:SetFontObject("GameFontNormal")
			editSkillName:SetPoint("TOPLEFT", 11, -30)
			editSkillName:SetText(L["Skill Name"])
			-- Zone de saisie pour le nom de la compétence
			local skillNameBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			skillNameBox:SetSize(180, 20)
			skillNameBox:SetPoint("TOPLEFT", 15, -50)
			skillNameBox:SetAutoFocus(false)
			skillNameBox:SetText(MySkills[i].name)
			skillNameBox:SetMaxLetters(30)
			-- Zone de texte pour la valeur du dé
			local editDiceRoll = editFrame:CreateFontString(nil, "OVERLAY")
			editDiceRoll:SetFontObject("GameFontNormal")
			editDiceRoll:SetPoint("TOPLEFT", 210, -30)
			editDiceRoll:SetText(L["Dice"])
			-- Zone de saisie pour la valeur du dé
			local diceValueBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			diceValueBox:SetSize(80, 20)
			diceValueBox:SetPoint("TOPLEFT", 212, -50)
			diceValueBox:SetAutoFocus(false)
			diceValueBox:SetText(MySkills[i].roll)
			diceValueBox:SetMaxLetters(12)
			-- Zone de texte pour le coût
			local editTextCost = editFrame:CreateFontString(nil, "OVERLAY")
			editTextCost:SetFontObject("GameFontNormal")
			editTextCost:SetPoint("TOPLEFT", 308, -30)
			editTextCost:SetText(L["Cost"])
			-- Zone de saisie pour le coût
			local CostValueBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			CostValueBox:SetSize(80, 20)
			CostValueBox:SetPoint("TOPLEFT", 310, -50)
			CostValueBox:SetAutoFocus(false)
			CostValueBox:SetText(MySkills[i].cost)
			CostValueBox:SetMaxLetters(10)
			-- Zone de texte pour la description de la compétence
			local editSkillDescription = editFrame:CreateFontString(nil, "OVERLAY")
			editSkillDescription:SetFontObject("GameFontNormal")
			editSkillDescription:SetPoint("TOPLEFT", 10, -80)
			editSkillDescription:SetText(L["Skill Description"])
			-- Création de la frame de fond pour la description de la compétence
			local skillDescriptionBackground = CreateFrame("Frame", nil, editFrame)
			skillDescriptionBackground:SetSize(380, 195)  -- Définit la taille de la frame
			skillDescriptionBackground:SetPoint("TOPLEFT", 13, -100)  -- Positionne la frame au centre de l'écran
			-- Création de la texture de fond
			local bg = skillDescriptionBackground:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
			bg:SetColorTexture(0, 0, 0, 0.5)  -- Définit la texture comme transparente
			-- Zone de saisie pour la description de la compétence
			local skillDescriptionBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			skillDescriptionBox:SetMultiLine(true)
			skillDescriptionBox.Left:Hide()
			skillDescriptionBox.Middle:Hide()
			skillDescriptionBox.Right:Hide()
			skillDescriptionBox:SetWidth(378)
			skillDescriptionBox:SetHeight(200)
			skillDescriptionBox:SetPoint("TOPLEFT", 15, -105)
			skillDescriptionBox:SetAutoFocus(false)
			skillDescriptionBox:SetText(MySkills[i].description)
			-- Coche Catégorie
			local categoryCheckButton = CreateFrame("CheckButton", "categoryCheckButton", editFrame, "ChatConfigCheckButtonTemplate")
			categoryCheckButton:SetPoint("TOPLEFT", 369, -75)
			categoryCheckButton:SetChecked(MySkills[i].isCategory)
			categoryCheckButton.tooltip = L["Category? Tooltip"]
			local categoryCheckText = editFrame:CreateFontString(nil, "OVERLAY")
			categoryCheckText:SetFontObject("GameFontNormal")
			categoryCheckText:SetPoint("TOPLEFT", 292, -80)
			categoryCheckText:SetText(L["Category?"])
			local isCategoryCheck = MySkills[i].isCategory
			categoryCheckButton:SetScript("OnClick", function(self)
				if self:GetChecked() then
					isCategoryCheck = true
				else
					isCategoryCheck = false
				end
			end)
			-- Bouton "Enregistrer"
			local saveButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
			saveButton:SetPoint("TOPLEFT", 214, -300)
			saveButton:SetSize(180, 25)
			saveButton:SetText(L["Save"])
			saveButton:SetScript("OnClick", function()
				-- Enregistrement de la compétence ici
				local skillNameText = skillNameBox:GetText()
				local diceValueText = diceValueBox:GetText()
				local costValueText = CostValueBox:GetText()
				local descriptionValueText = skillDescriptionBox:GetText()
				-- Ajoutez le code pour enregistrer la compétence dans votre base de données locale ici
				MySkills[i].name = skillNameText
				MySkills[i].roll = diceValueText
				MySkills[i].cost = costValueText
				MySkills[i].description = descriptionValueText
				MySkills[i].isCategory = isCategoryCheck
				skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
				diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
				costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
				if MySkills[i].name == "" or MySkills[i].isCategory == true then
					rollButton:Hide()
					else 
					rollButton:Show()
				end
				if MySkills[i].isCategory == true then
					skillName:SetText("|cFFCAA94B" .. string.upper(MySkills[i].name))
					skillName:SetFontObject("GameFontNormalLarge")
				else 
					skillName:SetFontObject("GameFontNormal")
				end
			editFrame:Hide()
			end)
			-- Bouton "Supprimer"
			local deleteButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
			deleteButton:SetPoint("TOPLEFT", 10, -300)
			deleteButton:SetSize(120, 25)
			deleteButton:SetText(L["Delete"])
			deleteButton:SetScript("OnClick", function()
				MySkills[i].name = ""
				MySkills[i].roll = ""
				MySkills[i].cost = ""
				MySkills[i].description = ""
				MySkills[i].isCategory = false
				skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
				diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
				costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
				rollButton:Hide()
			editFrame:Hide()
			end)
		end
	end)

end

----------------------------------
-- Liste des compétences page 3 --
----------------------------------

for i = 31, 45 do
	local j = i - 30
	-- Nom de la compétence
	local skillName = SkillFramePage3:CreateFontString(nil, "OVERLAY")
	skillName:SetFontObject("GameFontNormal")
	skillName:SetPoint("TOPLEFT", 10, -30 * j - 120)
	if MySkills[i].isCategory == true then
		skillName:SetText("|cFFCAA94B" .. string.upper(MySkills[i].name))
		skillName:SetFontObject("GameFontNormalLarge")
	else 
		skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
		skillName:SetFontObject("GameFontNormal")
	end
	DMToolsSkillName[i] = skillName

	-- Valeur du dé
	local diceValue = SkillFramePage3:CreateFontString(nil, "OVERLAY")
	diceValue:SetFontObject("GameFontNormal")
	diceValue:SetPoint("TOPLEFT", 210, -30 * j - 120)
	diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
	DMToolsDiceValue[i] = diceValue
	
	-- Valeur du coût
	local costValue = SkillFramePage3:CreateFontString(nil, "OVERLAY")
	costValue:SetFontObject("GameFontNormal")
	costValue:SetPoint("TOPLEFT", 310, -30 * j - 120)
	costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
	DMToolsCostValue[i] = costValue

	-- Bouton de roll
	local rollButton = CreateFrame("Button", nil, SkillFramePage3, "GameMenuButtonTemplate")
	local playerName = UnitName("player") -- Obtient le nom du joueur
	DMToolsRollButton[i] = rollButton
	rollButton:SetPoint("TOPLEFT", 380, -30 * j - 115)
	rollButton:SetSize(50, 25)
	rollButton:SetText("Roll")
	rollButton:SetScript("OnClick", function()
		PlaySound(36627)
		local status, result = pcall(function() return
		AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
		if status then
			playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
		end
		lastSkillName = MySkills[i].name
		lastDiceRoll = rollDice(MySkills[i].roll)
		lastDiceValue = MySkills[i].roll
		lastCostRoll = rollDice(MySkills[i].cost)
		lastCostValue = MySkills[i].cost
		if IsInRaid() then
			channel = "RAID"
		end
		C_ChatInfo.SendAddonMessage("DMTools", "ROLL@" .. playerName .. "@" .. MySkills[i].name .. "@" .. lastDiceRoll .. "@" .. MySkills[i].roll .. "@" .. lastCostRoll .. "@" .. MySkills[i].cost .. "@" .. healthValue .. "@" .. ressourceValue .. "@" .. i, channel)
			-- découpage de la description en plusieurs parties
			local length = string.len(MySkills[i].description)
			local start = 1
			local partID = 1
			while start < length do
				local subStr = string.sub(MySkills[i].description, start, start + 150)
				C_ChatInfo.SendAddonMessage("DMTools", "DESC@" .. playerName .. "@" .. i .. "@" .. partID .. "@" ..  subStr, channel)
				start = start +151
				partID = partID +1
			end
		-- partie gérant l'affichage de la notification en emote ou en communication interne
		local displayRoll = "" -- a utiliser pour l'affichage
		local displayRollValue = "" -- temporaire
		local displayCost = "" -- a utiliser pour l'affichage
		local displayCostValue = "" -- temporaire
		if lastDiceRoll == MySkills[i].roll then
			displayRoll = lastDiceRoll
		else
			displayRollValue = ("(" .. MySkills[i].roll .. ")")
			displayRoll = displayRoll .. lastDiceRoll .. " " .. displayRollValue
		end
		if lastCostRoll == MySkills[i].cost then
			displayCost = displayCost .. lastCostRoll
		else
			displayCostValue = ("(" .. MySkills[i].cost .. ")")
			displayCost = displayCost .. lastCostRoll .. " " .. displayCostValue
		end
		local emoteChatMessage = (L["use the skill"] .. MySkills[i].name .. (displayRoll ~= "" and L[", Roll "] or "") .. displayRoll .. (displayCost ~= "" and L[", cost "] or "") .. displayCost)
		if IsInGroup() or IsInRaid() then
			if IsInRaid() then
				channel = "RAID"
			end
			C_ChatInfo.SendAddonMessage("DMTools", "EMOTE@" .. playerName .. " " .. emoteChatMessage .. "@" .. "@" .. "@" .. "@" .. "@", channel)
		end
		if outputChannel ~= "DMTOOLS" and outputChannel ~= "SELF" then
			SendChatMessage(emoteChatMessage, outputChannel )
		elseif outputChannel == "SELF" then
			print(playerName .. " " .. emoteChatMessage)
		end
	end)
	if MySkills[i].name == "" or MySkills[i].isCategory == true then
		rollButton:Hide()
	end
	
	-- Bouton d'édition
	DMToolsEditIsOpened = false
	local editButton = CreateFrame("Button", nil, SkillFramePage3, "GameMenuButtonTemplate")
	editButton:SetPoint("TOPLEFT", 432, -30 * j - 115)
	editButton:SetSize(25, 25)
	editButton:SetText("?")
	editButton:SetScript("OnClick", function()
		if DMToolsEditIsOpened == false then
			DMToolsEditIsOpened = true
			-- Création de la fenêtre d'édition de compétence
			local editFrame = CreateFrame("Frame", "editFrame", UIParent, "ButtonFrameTemplate")
			editFrame:SetFrameStrata("HIGH")
			editFrame:SetTitle(L["Skill Edit"])
			editFrame:SetSize(400, 330) -- Largeur, Hauteur
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
			-- Zone de texte pour le nom de la compétence
			local editSkillName = editFrame:CreateFontString(nil, "OVERLAY")
			editSkillName:SetFontObject("GameFontNormal")
			editSkillName:SetPoint("TOPLEFT", 11, -30)
			editSkillName:SetText(L["Skill Name"])
			-- Zone de saisie pour le nom de la compétence
			local skillNameBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			skillNameBox:SetSize(180, 20)
			skillNameBox:SetPoint("TOPLEFT", 15, -50)
			skillNameBox:SetAutoFocus(false)
			skillNameBox:SetText(MySkills[i].name)
			skillNameBox:SetMaxLetters(30)
			-- Zone de texte pour la valeur du dé
			local editDiceRoll = editFrame:CreateFontString(nil, "OVERLAY")
			editDiceRoll:SetFontObject("GameFontNormal")
			editDiceRoll:SetPoint("TOPLEFT", 210, -30)
			editDiceRoll:SetText(L["Dice"])
			-- Zone de saisie pour la valeur du dé
			local diceValueBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			diceValueBox:SetSize(80, 20)
			diceValueBox:SetPoint("TOPLEFT", 212, -50)
			diceValueBox:SetAutoFocus(false)
			diceValueBox:SetText(MySkills[i].roll)
			diceValueBox:SetMaxLetters(12)
			-- Zone de texte pour le coût
			local editTextCost = editFrame:CreateFontString(nil, "OVERLAY")
			editTextCost:SetFontObject("GameFontNormal")
			editTextCost:SetPoint("TOPLEFT", 308, -30)
			editTextCost:SetText(L["Cost"])
			-- Zone de saisie pour le coût
			local CostValueBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			CostValueBox:SetSize(80, 20)
			CostValueBox:SetPoint("TOPLEFT", 310, -50)
			CostValueBox:SetAutoFocus(false)
			CostValueBox:SetText(MySkills[i].cost)
			CostValueBox:SetMaxLetters(10)
			-- Zone de texte pour la description de la compétence
			local editSkillDescription = editFrame:CreateFontString(nil, "OVERLAY")
			editSkillDescription:SetFontObject("GameFontNormal")
			editSkillDescription:SetPoint("TOPLEFT", 10, -80)
			editSkillDescription:SetText(L["Skill Description"])
			-- Création de la frame de fond pour la description de la compétence
			local skillDescriptionBackground = CreateFrame("Frame", nil, editFrame)
			skillDescriptionBackground:SetSize(380, 195)  -- Définit la taille de la frame
			skillDescriptionBackground:SetPoint("TOPLEFT", 13, -100)  -- Positionne la frame au centre de l'écran
			-- Création de la texture de fond
			local bg = skillDescriptionBackground:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
			bg:SetColorTexture(0, 0, 0, 0.5)  -- Définit la texture comme transparente
			-- Zone de saisie pour la description de la compétence
			local skillDescriptionBox = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
			skillDescriptionBox:SetMultiLine(true)
			skillDescriptionBox.Left:Hide()
			skillDescriptionBox.Middle:Hide()
			skillDescriptionBox.Right:Hide()
			skillDescriptionBox:SetWidth(378)
			skillDescriptionBox:SetHeight(200)
			skillDescriptionBox:SetPoint("TOPLEFT", 15, -105)
			skillDescriptionBox:SetAutoFocus(false)
			skillDescriptionBox:SetText(MySkills[i].description)
			-- Coche Catégorie
			local categoryCheckButton = CreateFrame("CheckButton", "categoryCheckButton", editFrame, "ChatConfigCheckButtonTemplate")
			categoryCheckButton:SetPoint("TOPLEFT", 369, -75)
			categoryCheckButton:SetChecked(MySkills[i].isCategory)
			categoryCheckButton.tooltip = L["Category? Tooltip"]
			local categoryCheckText = editFrame:CreateFontString(nil, "OVERLAY")
			categoryCheckText:SetFontObject("GameFontNormal")
			categoryCheckText:SetPoint("TOPLEFT", 292, -80)
			categoryCheckText:SetText(L["Category?"])
			local isCategoryCheck = MySkills[i].isCategory
			categoryCheckButton:SetScript("OnClick", function(self)
				if self:GetChecked() then
					isCategoryCheck = true
				else
					isCategoryCheck = false
				end
			end)
			-- Bouton "Enregistrer"
			local saveButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
			saveButton:SetPoint("TOPLEFT", 214, -300)
			saveButton:SetSize(180, 25)
			saveButton:SetText(L["Save"])
			saveButton:SetScript("OnClick", function()
				-- Enregistrement de la compétence ici
				local skillNameText = skillNameBox:GetText()
				local diceValueText = diceValueBox:GetText()
				local costValueText = CostValueBox:GetText()
				local descriptionValueText = skillDescriptionBox:GetText()
				-- Ajoutez le code pour enregistrer la compétence dans votre base de données locale ici
				MySkills[i].name = skillNameText
				MySkills[i].roll = diceValueText
				MySkills[i].cost = costValueText
				MySkills[i].description = descriptionValueText
				MySkills[i].isCategory = isCategoryCheck
				skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
				diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
				costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
				if MySkills[i].name == "" or MySkills[i].isCategory == true then
					rollButton:Hide()
					else 
					rollButton:Show()
				end
				if MySkills[i].isCategory == true then
					skillName:SetText("|cFFCAA94B" .. string.upper(MySkills[i].name))
					skillName:SetFontObject("GameFontNormalLarge")
				else 
					skillName:SetFontObject("GameFontNormal")
				end
			editFrame:Hide()
			end)
			-- Bouton "Supprimer"
			local deleteButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
			deleteButton:SetPoint("TOPLEFT", 10, -300)
			deleteButton:SetSize(120, 25)
			deleteButton:SetText(L["Delete"])
			deleteButton:SetScript("OnClick", function()
				MySkills[i].name = ""
				MySkills[i].roll = ""
				MySkills[i].cost = ""
				MySkills[i].description = ""
				MySkills[i].isCategory = false
				skillName:SetText("|cFFFFFFFF" .. MySkills[i].name)
				diceValue:SetText("|cFFFFFFFF" .. MySkills[i].roll)
				costValue:SetText("|cFFFFFFFF" .. MySkills[i].cost)
				rollButton:Hide()
			editFrame:Hide()
			end)
		end
	end)

end

	-- Bouton page 1
	local SkillButtonPage1 = CreateFrame("Button", nil, SkillFrame, "GameMenuButtonTemplate")
	SkillButtonPage1:SetPoint("TOPLEFT", 60, -30)
	SkillButtonPage1:SetSize(80, 25)
	SkillButtonPage1:SetText("Page 1")
	SkillButtonPage1:Disable()
	
	-- Bouton page 2
	local SkillButtonPage2 = CreateFrame("Button", nil, SkillFrame, "GameMenuButtonTemplate")
	SkillButtonPage2:SetPoint("TOPLEFT", 145, -30)
	SkillButtonPage2:SetSize(80, 25)
	SkillButtonPage2:SetText("Page 2")
	
	-- Bouton page 3
	local SkillButtonPage3 = CreateFrame("Button", nil, SkillFrame, "GameMenuButtonTemplate")
	SkillButtonPage3:SetPoint("TOPLEFT", 230, -30)
	SkillButtonPage3:SetSize(80, 25)
	SkillButtonPage3:SetText("Page 3")
	
	-- Bouton Interface MJ
	local SkillButtonGM = CreateFrame("Button", nil, SkillFrame, "GameMenuButtonTemplate")
	SkillButtonGM:SetPoint("TOPLEFT", 350, -30)
	SkillButtonGM:SetSize(100, 25)
	SkillButtonGM:SetText(L["GM Screen"])
	
	-- actions des boutons
	SkillButtonPage1:SetScript("OnClick", function()
		SkillFramePage1:Show()
		SkillFramePage2:Hide()
		SkillFramePage3:Hide()
		SkillFrameGM:Hide()
		tableHeaders:Show()
		gmHeaders:Hide()
		SkillFrame:SetSize(460, 600) -- Largeur, Hauteur
		line:SetWidth(SkillFrame:GetWidth())
		SkillButtonPage1:Disable()
		SkillButtonPage2:Enable()
		SkillButtonPage3:Enable()
		SkillButtonGM:Enable()
	end)	
	SkillButtonPage2:SetScript("OnClick", function()
		SkillFramePage1:Hide()
		SkillFramePage2:Show()
		SkillFramePage3:Hide()
		SkillFrameGM:Hide()
		tableHeaders:Show()
		gmHeaders:Hide()
		SkillFrame:SetSize(460, 600) -- Largeur, Hauteur
		line:SetWidth(SkillFrame:GetWidth())
		SkillButtonPage1:Enable()
		SkillButtonPage2:Disable()
		SkillButtonPage3:Enable()
		SkillButtonGM:Enable()
	end)
	SkillButtonPage3:SetScript("OnClick", function()
		SkillFramePage1:Hide()
		SkillFramePage2:Hide()
		SkillFramePage3:Show()
		SkillFrameGM:Hide()
		tableHeaders:Show()
		gmHeaders:Hide()
		SkillFrame:SetSize(460, 600) -- Largeur, Hauteur
		line:SetWidth(SkillFrame:GetWidth())
		SkillButtonPage1:Enable()
		SkillButtonPage2:Enable()
		SkillButtonPage3:Disable()
		SkillButtonGM:Enable()
	end)
	SkillButtonGM:SetScript("OnClick", function()
		SkillFramePage1:Hide()
		SkillFramePage2:Hide()
		SkillFramePage3:Hide()
		SkillFrameGM:Show()
		tableHeaders:Hide()
		gmHeaders:Show()
		SkillFrame:SetSize(660, 600) -- Largeur, Hauteur
		line:SetWidth(SkillFrame:GetWidth())
		SkillButtonPage1:Enable()
		SkillButtonPage2:Enable()
		SkillButtonPage3:Enable()
		SkillButtonGM:Disable()
	end)
	
	-- Cadre des points de vie
	local health = CreateFrame("Frame", nil, SkillFrame)
	health:SetSize(50, 50)
	health:SetPoint("TOPLEFT", SkillFrame, "TOPLEFT", 10, -60)
	-- Ajout de l'icône en fond
	local background = health:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetTexture("Interface\\Icons\\petbattle_health")
	local healthText = health:CreateFontString(nil, "OVERLAY")
	healthText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	healthText:SetPoint("CENTER", health, "CENTER", 0, -19)
	healthText:SetText(L["Health"]) 
	-- Création de la frame de fond la santé
	local healthFrame = CreateFrame("Frame", nil, health)
	healthFrame:SetSize(100, 50)  -- Définit la taille de la frame
	healthFrame:SetPoint("RIGHT", 100, 0)  -- Positionne la frame au centre de l'écran
	-- Création de la texture de fond
	local bg = healthFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
	bg:SetColorTexture(0, 0, 0, 0.5)  -- Définit la texture comme transparente
	local healthValueText = CreateFrame("EditBox", nil, healthFrame, "InputBoxTemplate")
	healthValueText:SetMultiLine(false)
	healthValueText.Left:Hide()
	healthValueText.Middle:Hide()
	healthValueText.Right:Hide()
	healthValueText:SetWidth(100)
	healthValueText:SetHeight(50)
	healthValueText:SetPoint("CENTER", 0, 0)
	healthValueText:SetAutoFocus(false)
	healthValueText:SetText(healthValue)
	healthValueText:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
	healthValueText:SetScript("OnEditFocusLost", function(self)
		healthValue = healthValueText:GetText()
		local status, result = pcall(function() return
			AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
			local playerName = UnitName("player")
			if status then
				playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
			end
		if IsInRaid() then
			channel = "RAID"
		end
		C_ChatInfo.SendAddonMessage("DMTools", "SYNC@" .. playerName .. "@" .. lastSkillName .. "@" .. lastDiceRoll .. "@" .. lastDiceValue .. "@" .. lastCostRoll .. "@" .. lastCostValue .. "@" .. healthValue .. "@" .. ressourceValue, channel)
		end)

	-- Cadre des points de ressource
	local ressource = CreateFrame("Frame", nil, SkillFrame)
	ressource:SetSize(50, 50)
	ressource:SetPoint("TOPLEFT", SkillFrame, "TOPLEFT", 170, -60)
	-- Ajout de l'icône en fond
	local background = ressource:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetTexture("Interface\\Icons\\ability_monk_counteractmagic")
	local ressourceText = health:CreateFontString(nil, "OVERLAY")
	ressourceText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	ressourceText:SetPoint("CENTER", ressource, "CENTER", 0, -19)
	ressourceText:SetText(L["Resource"]) 
	-- Création de la frame de fond des ressources
	local ressourceFrame = CreateFrame("Frame", nil, ressource)
	ressourceFrame:SetSize(100, 50)  -- Définit la taille de la frame
	ressourceFrame:SetPoint("RIGHT", 100, 0)  -- Positionne la frame au centre de l'écran
	-- Création de la texture de fond
	local bg = ressourceFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()  -- Fait en sorte que la texture remplisse toute la frame
	bg:SetColorTexture(0, 0, 0, 0.5)  -- Définit la texture comme transparente
	local ressourceValueText = CreateFrame("EditBox", nil, ressourceFrame, "InputBoxTemplate")
	ressourceValueText:SetMultiLine(false)
	ressourceValueText.Left:Hide()
	ressourceValueText.Middle:Hide()
	ressourceValueText.Right:Hide()
	ressourceValueText:SetWidth(100)
	ressourceValueText:SetHeight(50)
	ressourceValueText:SetPoint("CENTER", 0, 0)
	ressourceValueText:SetAutoFocus(false)
	ressourceValueText:SetText(ressourceValue)
	ressourceValueText:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
	ressourceValueText:SetScript("OnEditFocusLost", function(self)
		ressourceValue = ressourceValueText:GetText()
		local status, result = pcall(function() return
			AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
			local playerName = UnitName("player")
			if status then
				playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
			end
			if IsInRaid() then
				channel = "RAID"
			end
			C_ChatInfo.SendAddonMessage("DMTools", "SYNC@" .. playerName .. "@" .. lastSkillName .. "@" .. lastDiceRoll .. "@" .. lastDiceValue .. "@" .. lastCostRoll .. "@" .. lastCostValue .. "@" .. healthValue .. "@" .. ressourceValue, channel)
	end)


	-- Mise à jour de la table des participants lors de la réception d'un message HELLO
	local function onHelloMessage(name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue, skillID)
		
		if players[name] == nil then
			players[name] = {skillName = skillName, diceRoll = diceRoll, diceValue = diceValue, costRoll = costRoll, costValue = costValue, healthValue = healthValue, ressourceValue = ressourceValue, skillID = skillID}
		elseif skillName ~= nil and skillName ~= "" then
			players[name] = {skillName = skillName, diceRoll = diceRoll, diceValue = diceValue, costRoll = costRoll, costValue = costValue, healthValue = healthValue, ressourceValue = ressourceValue, skillID = skillID}
		end
		updateDisplayTable()
		
	end

	-- Mise à jour de la table des participants lors de la réception d'un message SYNC
	local function onSyncMessage(name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue)
		players[name] = {skillName = skillName, diceRoll = diceRoll, diceValue = diceValue, costRoll = costRoll, costValue = costValue, healthValue = healthValue, ressourceValue = ressourceValue, skillID = skillID}
		updateDisplayTable()
		
	end

	-- Fonction de synchro pour peupler la liste des joueurs
	local playerName = UnitName("player") -- Obtient le nom du joueur
	if IsInRaid() then
		channel = "RAID"
	end

	local function sendInfo()
		local status, result = pcall(function() return
			AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName() end)
			if status then
				playerName =  AddOn_TotalRP3.Player.GetCurrentUser():GetFirstName()
			end
			if not IsInInstance() then
				C_ChatInfo.SendAddonMessage("DMTools", "HELLO@" .. playerName .. "@" .. "@" .. "@" .. "@" .. "@" .. "@" .. healthValue .. "@" .. ressourceValue, channel)
			end
	end

	-- Fonctions de gestion des tours joueur
	local function newTurn(name)
		-- Change la couleur de tous les noms en rouge
		for name, player in pairs(players) do
			nameColors[name] = "|cFFff4500" -- Rouge
			player.skillName = ""
			player.diceRoll = ""
			player.diceValue = ""
			player.costRoll = ""
			player.costValue = ""
		end
		PlaySound(8959)
		if outputChannel == "DMTOOLS" then
			print("|cffffff00" .. name .. L["has started a new turn"])
		end
		newTurnButton:Disable()
		newEnemyTurnButton:Enable()
		newFreeTurnButton:Enable()
		updateDisplayTable() -- Met à jour la table
	end

	-- Fonctions de gestion des tours ennemis
	local function newEnemyTurn(name)
		-- Change la couleur de tous les noms en rouge
		for name, player in pairs(players) do
			nameColors[name] = "|cffffff00" -- Jaune
		end
		PlaySound(8959)
		if outputChannel == "DMTOOLS" then
			print("|cffffff00" .. name .. L["has started a new enemy turn"])
		end
		newTurnButton:Enable()
		newFreeTurnButton:Enable()
		newEnemyTurnButton:Disable()
		updateDisplayTable() -- Met à jour la table
	end

	-- Fonctions de gestion des tours libres
	local function newFreeTurn(name)
		-- Change la couleur de tous les noms en vert
		for name, player in pairs(players) do
			nameColors[name] = "|cFF52BE80" -- Vert
		end
		PlaySound(8959)
		if outputChannel == "DMTOOLS" then
			print("|cffffff00" .. name .. L["has started a new free turn"])
		end
		newTurnButton:Enable()
		newFreeTurnButton:Disable()
		newEnemyTurnButton:Enable()
		updateDisplayTable() -- Met à jour la table
	end

	-- Création du ticker
	local ticker = C_Timer.NewTicker(7, sendInfo)

	-- Fonction d'enregistrement des marqueurs
	local function storeMarkers(player, id, markerName, markerPower, markerHealth, markerDescription, markerHidden)
		id = tonumber(id)
		if player ~= UnitName("player") and markerHidden == "false" then
			DMToolsMarkerNames[id]:SetText("|cFFFFFFFF" .. markerName)
			markers[id].name = markerName
			DMToolsMarkerPowers[id]:SetText("|cFFFFFFFF" .. markerPower)
			markers[id].power = markerPower
			DMToolsMarkerHealth[id]:SetText("|cFFFFFFFF" .. markerHealth)
			markers[id].health = markerHealth
			markers[id].description = markerDescription
			markers[id].hidden = false
			DMToolsMarkerIcon[id]:Show()
			--print(markers[id].description)
		elseif player ~= UnitName("player") and markerHidden == "true" then
			DMToolsMarkerNames[id]:SetText("")
			markers[id].name = ""
			DMToolsMarkerPowers[id]:SetText("")
			markers[id].power = ""
			DMToolsMarkerHealth[id]:SetText("")
			markers[id].health = ""
			markers[id].description = ""
			markers[id].hidden = true
				if DMToolsMarkerTransparent == true then
					DMToolsMarkerIcon[id]:Hide()
				end
		end
    end

	-- Fonction d'enregistrement des données de description des compétences
	local function storeSkillDescription(name, descSkillID, partID, descriptionPart)
		-- Parcourir la table pour trouver et supprimer les données existantes
		for i = #descriptionDetails, 1, -1 do
			if descriptionDetails[i].name == name and descriptionDetails[i].descSkillID == descSkillID and descriptionDetails[i].partID ==  partID then
				table.remove(descriptionDetails, i)
			end
		end
		table.insert(descriptionDetails, {name = name, descSkillID = descSkillID, partID = partID, descriptionPart = descriptionPart})
	end
	------------------------
	--  COMMANDE SYSTEME  --
	------------------------

	-- Commande pour afficher la fenêtre
	SLASH_DMTools1 = "/DMTools"
	SlashCmdList["DMTools"] = function(msg)
		if msg == "" then
			-- Aucun argument fourni, afficher le texte d'aide
			print(L["Command Usage"])
			--print("/DMTools character - Explication de la commande character")
			--print("/DMTools markers - Explication de la commande markers")
			print(L["DMTools Export"])
			print(L["DMTools Import"])
			print(L["DMTools Reset"])
		elseif string.lower(msg) == "character" then
			-- Gérer la commande character
		elseif string.lower(msg) == "markers" then
			-- Gérer la commande markers
		elseif string.lower(msg) == "export" then
			DMToolsExportData(MySkills)
		elseif string.lower(msg) == "import" then
			DMToolsImportData(MySkills)
		elseif string.lower(msg) == "reset" then
			DMToolsReset(MySkills)
		else
			print("Commande inconnue. Tapez /DMTools pour l'aide.")
		end
	end

	------------------------------
	-- GESTIONNAIRE D'EVENEMENT --
	------------------------------

	-- Création d'un cadre pour gérer les événements
	local eventFrame = CreateFrame("Frame")

	-- Enregistrement de l'événement "CHAT_MSG_ADDON"
	eventFrame:RegisterEvent("CHAT_MSG_ADDON")

	eventFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
		if event == "CHAT_MSG_ADDON" and prefix == "DMTools" then
			local action, name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue, skillID = strsplit("@", message)
			local action, player, id, markerName, markerPower, markerHealth, markerDescription, markerHidden, markerDump = strsplit("@", message)
			local action, name, descSkillID, partID, descriptionPart, descDump = strsplit("@", message)
			if action == "HELLO" then
				onHelloMessage(name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue, skillID)
			elseif action == "ROLL" then
				nameColors[name] = "|cFF52BE80"
				onHelloMessage(name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue, skillID)
				--print(name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue, skillID)
			elseif action == "SYNC" then
				onSyncMessage(name, skillName, diceRoll, diceValue, costRoll, costValue, healthValue, ressourceValue)
			elseif action == "EMOTE" and outputChannel == "DMTOOLS" then
				print("|cffffff00" .. name) -- affiche la notification du jet
			elseif action == "TURN" then
				newTurn(name)
			elseif action == "ENEMY" then
				newEnemyTurn(name)
			elseif action == "FREE" then
				newFreeTurn(name)
			elseif action == "MARKERS" then
				storeMarkers(player, id, markerName, markerPower, markerHealth, markerDescription, markerHidden)
				--print(player, id, markerName, markerPower, markerHealth, markerDescription, markerHidden)
			elseif action == "DESC" then
				--print(action, name, descSkillID, partID, description)
				storeSkillDescription(name, descSkillID, partID, descriptionPart)
			end
		end
	end)
	
end)
