----// eChat //----
-- Author: Exho (obviously)
-- Version: 4/9/14

if SERVER then
	AddCSLuaFile()
	return
end

eChat = {}

eChat.config = {
	timeStamps = true,	
	fadeTime = 12,
}

surface.CreateFont( "eChat_18", {
	font = "Roboto Lt",
	size = 18,
	weight = 500,
	antialias = true,
} )

surface.CreateFont( "eChat_16", {
	font = "Roboto Lt",
	size = 16,
	weight = 500,
	antialias = true,
} )

--// Prevents errors if the script runs too early, which it will
if not GAMEMODE then
	hook.Add("Initialize", "echat_init", function()
		include("autorun/cl_chat.lua")
		eChat.buildBox()
	end)
	return
end

--// Builds the chatbox but doesn't display it
function eChat.buildBox()
	eChat.frame = vgui.Create("DFrame")
	eChat.frame:SetSize( 625, 300 )
	eChat.frame:SetTitle("")
	eChat.frame:ShowCloseButton( false )
	eChat.frame:SetDraggable( false )
	eChat.frame:SetPos( 30, ScrH() - eChat.frame:GetTall() * 1.7)
	eChat.frame.Paint = function( self, w, h )
		eChat.blur( self, 10, 20, 255 )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
		
		draw.RoundedBox( 0, 0, 0, w, 25, Color( 80, 80, 80, 100 ) )
	end
	eChat.oldPaint = eChat.frame.Paint
	
	local serverName = vgui.Create("DLabel", eChat.frame)
	serverName:SetText( GetConVarString( "hostname" ) )
	serverName:SetFont( "eChat_18")
	serverName:SizeToContents()
	serverName:SetPos( 5, 4 )
	
	local settings = vgui.Create("DButton", eChat.frame)
	settings:SetText("Settings")
	settings:SetFont( "eChat_18")
	settings:SetTextColor( Color( 230, 230, 230, 150 ) )
	settings:SetSize( 70, 25 )
	settings:SetPos( eChat.frame:GetWide() - settings:GetWide(), 0 )
	settings.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 200 ) )
	end
	settings.DoClick = function( self )
		eChat.openSettings()
	end
	
	eChat.entry = vgui.Create("DTextEntry", eChat.frame) 
	eChat.entry:SetSize( eChat.frame:GetWide() - 50, 20 )
	eChat.entry:SetTextColor( color_white )
	eChat.entry:SetFont("eChat_18")
	eChat.entry:SetDrawBorder( false )
	eChat.entry:SetDrawBackground( false )
	eChat.entry:SetCursorColor( color_white )
	eChat.entry:SetHighlightColor( Color(52, 152, 219) )
	eChat.entry:SetPos( 45, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	eChat.entry.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		derma.SkinHook( "Paint", "TextEntry", self, w, h )
	end
	eChat.entry.OnKeyCodeTyped = function( self, code )
		if code == KEY_ESCAPE then
			-- Work around to hide the chatbox when the client press escape
			eChat.hideBox()
			gui.HideGameUI()
		elseif code == KEY_ENTER then
			-- Replicate the client pressing enter
			
			if string.Trim( self:GetText() ) != "" then
				gamemode.Call("OnPlayerChat", LocalPlayer(), self:GetText(), eChat.teamChat, !LocalPlayer():Alive())
				--LocalPlayer():ConCommand("say "..self:GetText())
			end
			
			eChat.hideBox()
		end
	end
	
	eChat.chatLog = vgui.Create("RichText", eChat.frame) 
	eChat.chatLog:SetSize( eChat.frame:GetWide() - 10, eChat.frame:GetTall() - 60 )
	eChat.chatLog:SetPos( 5, 30 )
	eChat.chatLog.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
	end
	eChat.chatLog.Think = function( self )
		if eChat.lastMessage then
			if CurTime() - eChat.lastMessage > eChat.config.fadeTime then
				self:SetVisible( false )
			else
				self:SetVisible( true )
			end
		end
	end
	eChat.chatLog.PerformLayout = function( self )
		self:SetFontInternal("eChat_18")
		self:SetFGColor( color_white )
	end
	eChat.oldPaint2 = eChat.chatLog.Paint
	
	local text = "Say :"

	local say = vgui.Create("DLabel", eChat.frame)
	say:SetText("")
	surface.SetFont( "eChat_18")
	local w, h = surface.GetTextSize( text )
	say:SetSize( w + 5, 20 )
	say:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	say.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		draw.DrawText( text, "eChat_18", 2, 1, color_white )
	end
	say.Think = function( self )
		if eChat.teamChat then 
			text = "Say (TEAM) :"
			local w, h = surface.GetTextSize( text )
			self:SetSize( w + 5, 20 )
			self:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
			
			eChat.entry:SetSize( eChat.frame:GetWide() - self:GetWide() - 15, 20 )
			eChat.entry:SetPos( self:GetWide() + 10, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
		else
			text = "Say :"
			local w, h = surface.GetTextSize( text )
			self:SetSize( w + 5, 20 )
			self:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
			
			eChat.entry:SetSize( eChat.frame:GetWide() - 50, 20 )
			eChat.entry:SetPos( 45, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
		end
	end	
	
	eChat.hideBox()
end

--// Hides the chat box but not the messages
function eChat.hideBox()
	eChat.frame.Paint = function() end
	eChat.chatLog.Paint = function() end
	
	eChat.chatLog:SetVerticalScrollbarEnabled( false )
	eChat.chatLog:GotoTextEnd()
	
	eChat.lastMessage = eChat.lastMessage or CurTime() - eChat.config.fadeTime
	
	-- Hide the chatbox except the log
	local children = eChat.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end
		
		if pnl != eChat.chatLog then
			pnl:SetVisible( false )
		end
	end
	
	-- Give the player control again
	eChat.frame:SetMouseInputEnabled( false )
	eChat.frame:SetKeyboardInputEnabled( false )
	gui.EnableScreenClicker( false )
	
	-- We are done chatting
	gamemode.Call("FinishChat")
	
	-- Clear the text entry
	eChat.entry:SetText( "" )
	gamemode.Call( "ChatTextChanged", "" )
end

--// Shows the chat box
function eChat.showBox()
	-- Draw the chat box again
	eChat.frame.Paint = eChat.oldPaint
	eChat.chatLog.Paint = eChat.oldPaint2
	
	eChat.chatLog:SetVerticalScrollbarEnabled( true )
	eChat.lastMessage = nil
	
	-- Show any hidden children
	local children = eChat.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end
		
		pnl:SetVisible( true )
	end
	
	-- MakePopup calls the input functions so we don't need to call those
	eChat.frame:MakePopup()
	eChat.entry:RequestFocus()
	
	-- Make sure other addons know we are chatting
	gamemode.Call("StartChat")
end

--// Opens the settings panel
function eChat.openSettings()
	eChat.hideBox()
	
	eChat.frameS = vgui.Create("DFrame")
	eChat.frameS:SetSize( 400, 300 )
	eChat.frameS:SetTitle("")
	eChat.frameS:MakePopup()
	eChat.frameS:SetPos( ScrW()/2 - eChat.frameS:GetWide()/2, ScrH()/2 - eChat.frameS:GetTall()/2 )
	eChat.frameS:ShowCloseButton( true )
	eChat.frameS.Paint = function( self, w, h )
		eChat.blur( self, 10, 20, 255 )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
		
		draw.RoundedBox( 0, 0, 0, w, 25, Color( 80, 80, 80, 100 ) )
		
		draw.RoundedBox( 0, 0, 25, w, 25, Color( 50, 50, 50, 50 ) )
	end
	
	local serverName = vgui.Create("DLabel", eChat.frameS)
	serverName:SetText( "eChat - Settings" )
	serverName:SetFont( "eChat_18")
	serverName:SizeToContents()
	serverName:SetPos( 5, 4 )
	
	local label1 = vgui.Create("DLabel", eChat.frameS)
	label1:SetText( "Time stamps: " )
	label1:SetFont( "eChat_18")
	label1:SizeToContents()
	label1:SetPos( 10, 40 )
	
	local checkbox1 = vgui.Create("DCheckBox", eChat.frameS ) 
	checkbox1:SetPos(label1:GetWide() + 15, 42)
	checkbox1:SetValue( eChat.config.timeStamps )
	
	local label2 = vgui.Create("DLabel", eChat.frameS)
	label2:SetText( "Fade time: " )
	label2:SetFont( "eChat_18")
	label2:SizeToContents()
	label2:SetPos( 10, 70 )
	
	local textEntry = vgui.Create("DTextEntry", eChat.frameS) 
	textEntry:SetSize( 50, 20 )
	textEntry:SetPos( label2:GetWide() + 15, 70 )
	textEntry:SetText( eChat.config.fadeTime ) 
	textEntry:SetTextColor( color_white )
	textEntry:SetFont("eChat_18")
	textEntry:SetDrawBorder( false )
	textEntry:SetDrawBackground( false )
	textEntry:SetCursorColor( color_white )
	textEntry:SetHighlightColor( Color(52, 152, 219) )
	textEntry.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		derma.SkinHook( "Paint", "TextEntry", self, w, h )
	end
	
	--[[local checkbox2 = vgui.Create("DCheckBox", eChat.frameS ) 
	checkbox2:SetPos(label2:GetWide() + 15, 72)
	checkbox2:SetValue( eChat.config.seeChatTags )
	
	local label3 = vgui.Create("DLabel", eChat.frameS)
	label3:SetText( "Use chat tags: " )
	label3:SetFont( "eChat_18")
	label3:SizeToContents()
	label3:SetPos( 10, 100 )
	
	local checkbox3 = vgui.Create("DCheckBox", eChat.frameS ) 
	checkbox3:SetPos(label3:GetWide() + 15, 102)
	checkbox3:SetValue( eChat.config.useChatTag )]]
	
	local save = vgui.Create("DButton", eChat.frameS)
	save:SetText("Save")
	save:SetFont( "eChat_18")
	save:SetTextColor( Color( 230, 230, 230, 150 ) )
	save:SetSize( 70, 25 )
	save:SetPos( eChat.frameS:GetWide()/2 - save:GetWide()/2, eChat.frameS:GetTall() - save:GetTall() - 10)
	save.Paint = function( self, w, h )
		if self:IsDown() then
			draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 80, 80, 200 ) )
		else
			draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 200 ) )
		end
	end
	save.DoClick = function( self )
		eChat.frameS:Close()
		
		eChat.config.timeStamps = checkbox1:GetChecked() 
		eChat.config.fadeTime = tonumber(textEntry:GetText()) or eChat.config.fadeTime
	end
end

--// Panel based blur function by Chessnut from NutScript
local blur = Material( "pp/blurscreen" )
function eChat.blur( panel, layers, density, alpha )
	-- Its a scientifically proven fact that blur improves a script
	local x, y = panel:LocalToScreen(0, 0)

	surface.SetDrawColor( 255, 255, 255, alpha )
	surface.SetMaterial( blur )

	for i = 1, 3 do
		blur:SetFloat( "$blur", ( i / layers ) * density )
		blur:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
	end
end

local oldAddText = chat.AddText

--// Overwrite chat.AddText to detour it into my chatbox
function chat.AddText(...)
	if not eChat.chatLog then
		eChat.buildBox()
	end
	
	local msg = {}
	
	-- Iterate through the strings and colors
	for _, obj in pairs( {...} ) do
		if type(obj) == "table" then
			eChat.chatLog:InsertColorChange( obj.r, obj.g, obj.b, obj.a )
			table.insert( msg, Color(obj.r, obj.g, obj.b, obj.a) )
		elseif type(obj) == "string"  then
			eChat.chatLog:AppendText( obj )
			table.insert( msg, obj )
		elseif obj:IsPlayer() then
			local ply = obj
			
			if eChat.config.timeStamps then
				eChat.chatLog:InsertColorChange( 130, 130, 130, 255 )
				eChat.chatLog:AppendText( "["..os.date("%X").."] ")
			end
			
			if eChat.config.seeChatTags and ply:GetNWBool("eChat_tagEnabled", false) then
				local col = ply:GetNWString("eChat_tagCol", "255 255 255")
				local tbl = string.Explode(" ", col )
				eChat.chatLog:InsertColorChange( tbl[1], tbl[2], tbl[3], 255 )
				eChat.chatLog:AppendText( "["..ply:GetNWString("eChat_tag", "N/A").."] ")
			end
			
			local col = GAMEMODE:GetTeamColor( obj )
			eChat.chatLog:InsertColorChange( col.r, col.g, col.b, 255 )
			eChat.chatLog:AppendText( obj:Nick() )
			table.insert( msg, obj:Nick() )
		end
	end
	eChat.chatLog:AppendText("\n")
	
	eChat.chatLog:SetVisible( true )
	eChat.lastMessage = CurTime()
	oldAddText(unpack(msg))
end


--// Write any server notifications
hook.Add( "ChatText", "echat_joinleave", function( index, name, text, type )
	if not eChat.chatLog then
		eChat.buildBox()
	end
	
	if type == "joinleave" or type == "none" then
		eChat.chatLog:InsertColorChange( 0, 128, 255, 255 )
		eChat.chatLog:AppendText( text.."\n" )
		eChat.lastMessage = CurTime()
	end
end)

--// Stops the default chat box from being opened
hook.Add("PlayerBindPress", "echat_hijackbind", function(ply, bind, pressed)
	local codeword = "messagemode"
	
	-- If the bind is "messagemode" or "messagemode2" then the client hit their chat key
	if string.sub( bind, 1, string.len(codeword) ) == codeword then
		if bind == "messagemode2" then 
			eChat.teamChat = true
		else
			eChat.teamChat = false
		end
		
		if IsValid( eChat.frame ) then
			eChat.showBox()
		else
			eChat.buildBox()
			eChat.showBox()
		end
		return true
	end
end)

--// Hide the default chat too in case that pops up
hook.Add("HUDShouldDraw", "echat_hidedefault", function( name )
	if name == "CHudChat" then
		return false
	end
end)

--// Modify the Chatbox for align.
local oldGetChatBoxPos = chat.GetChatBoxPos
function chat.GetChatBoxPos()
	return eChat.frame:GetPos()
end

--// Overriding FPRP Stupid Chat System. The Glorious DarkRP Masterrace got it also working, to shine over the fprp peasants.
local function override_darkrp()
	--// Detouring the DarkRP Chat to use the old system
	local function AddToChat(bits)
		local col1 = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))

		local prefixText = net.ReadString()
		local ply = net.ReadEntity()
		ply = IsValid(ply) and ply or LocalPlayer()

		if prefixText == "" or not prefixText then
			prefixText = ply:Nick()
			prefixText = prefixText ~= "" and prefixText or ply:SteamName()
		end

		local col2 = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))

		local text = net.ReadString()
		local shouldShow
		if text and text ~= "" then
			if IsValid(ply) then
				shouldShow = hook.Call("OnPlayerChat", GAMEMODE, ply, text, false, not ply:Alive(), prefixText, col1, col2)
			end

			if shouldShow ~= true then
				chat.AddText(col1, prefixText, col2, ": "..text)
			end
		else
			--shouldShow = hook.Call("ChatText", GAMEMODE, "0", prefixText, prefixText, "none")
			--if shouldShow ~= true then
				chat.AddText(col1, prefixText)
			--end
		end
		chat.PlaySound()
	end
net.Receive("DarkRP_Chat", AddToChat)
	--// Reverting the OnPlayerChat changes. Praise FPtje!
	function GAMEMODE:OnPlayerChat(ply, strText, bTeamOnly, bPlayerIsDead )
		local tab = {}
		if ( bPlayerIsDead ) then
			table.insert( tab, Color( 255, 30, 40 ) )
			table.insert( tab, "*DEAD* " )
		end
		if ( bTeamOnly ) then
			table.insert( tab, Color( 30, 160, 40 ) )
			table.insert( tab, "(TEAM) " )
		end
		if ( IsValid( ply ) ) then
			table.insert( tab, ply )
		else
			table.insert( tab, "Console" )
		end
		table.insert( tab, Color( 255, 255, 255 ) )
		table.insert( tab, ": " .. strText )
		chat.AddText( unpack(tab) )
		return true
		end
	end
hook.Add("Initialize", "eChats_DerpRP_comp", override_darkrp)