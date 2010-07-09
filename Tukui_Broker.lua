local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local TukUI_brokerdatatext = TukuiDB["broker_datatext"]
local TukUI_datatext = TukuiDB["datatext"]

local pluginText = {}
	
local TUKUI_BROKER = CreateFrame("Frame")

TUKUI_BROKER:RegisterEvent("PLAYER_LOGIN")
TUKUI_BROKER:SetScript("OnEvent", function(_, event, ...) TUKUI_BROKER[event](TUKUI_BROKER, ...) end)

-- Helper function from "TukUI (Extra panel stats)" to create a frame to display at
-- a specific TukUI panel position
local function CreatePanelFrame(position, enablemouse)
	-- Create the frame and text objects
	local Frame = CreateFrame("Frame")	
	local Text = TukuiInfoLeft:CreateFontString(nil, "OVERLAY")

	-- Set the font and height
	Text:SetFont(TukUI_datatext.font, TukUI_datatext.fontsize)
	Text:SetHeight(TukuiDB:Scale(27))

	-- Enable the mouse if needed
	Frame:EnableMouse(enablemouse)

	-- Make sure the frame has the same position as the text, so we can add support
	-- for mouse actions
	Frame:SetAllPoints(Text)

	-- Finally, set the text position on the info panel
	TukuiDB.PP(position, Text)

	return Frame, Text
end
	
local function onMouseUp(frame, btn)
	if frame.pluginObject.OnClick then
		frame.pluginObject.OnClick(frame, btn)
	end
end

local function onTooltipEnter(frame)
	if not InCombatLockdown() then
		if frame.pluginObject.OnTooltipShow then
			GameTooltip:SetOwner(frame, "ANCHOR_TOP", 0, TukuiDB:Scale(6));
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("BOTTOM", frame, "TOP", 0, Stats.TTSpacing)
			GameTooltip:ClearLines()	
			frame.pluginObject.OnTooltipShow(GameTooltip, frame)
			GameTooltip:Show()
		elseif frame.pluginObject.OnEnter then
			frame.pluginObject.OnEnter(frame)
		end
	end
end

local function onTooltipLeave(frame)
	GameTooltip:Hide()
		
	if frame.pluginObject.OnLeave then
		frame.pluginObject.OnLeave(frame)
	end
end

function TUKUI_BROKER:New(_, name, obj)
	if TukUI_brokerdatatext[name] ~= nil and TukUI_brokerdatatext[name] > 0 and not pluginText[name] then
		local Frame, Text = CreatePanelFrame(TukUI_brokerdatatext[name], true)

		-- Save info about the plugin into the Frame 
		Frame.pluginName = name
		Frame.pluginObject = obj
			
		-- Text is updated independently of the Frame so store it separately
		pluginText[name] = Text
			
		if obj.suffix then
			self:ValueUpdate(nil, name, nil, obj.value or name, obj)
			ldb.RegisterCallback(self, "LibDataBroker_AttributeChanged_"..name.."_value", "ValueUpdate")
		else
			self:TextUpdate(nil, name, nil, obj.text or obj.label or name)
			ldb.RegisterCallback(self, "LibDataBroker_AttributeChanged_"..name.."_text", "TextUpdate")
		end
			
		Frame:SetScript("OnEnter", onTooltipEnter)
		Frame:SetScript("OnLeave", onTooltipLeave)
		Frame:SetScript("OnMouseUp", onMouseUp)

		if obj.OnCreate then obj.OnCreate(obj, Frame) end
	end
end

function TUKUI_BROKER:TextUpdate(_, name, _, data)
	pluginText[name]:SetText(data)
end

function TUKUI_BROKER:ValueUpdate(_, name, _, data, obj)
	pluginText[name]:SetFormattedText("%s %s", data, obj.suffix)
end

function TUKUI_BROKER:PLAYER_LOGIN()
	self:UnregisterEvent("PLAYER_LOGIN")
	ldb.RegisterCallback(self, "LibDataBroker_DataObjectCreated", "New")
		
	for name, obj in ldb:DataObjectIterator() do
		if not pluginText[name] then
			self:New(nil, name, obj)
		end
	end
	self.PLAYER_LOGIN = nil
end
