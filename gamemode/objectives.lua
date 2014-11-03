AS = AS or {}

AS._Objectives = AS._Objectives or {}
function AS.AddObjective(obj)
	AS._Objectives[obj:GetPriority()] = AS._Objectives[obj:GetPriority()] or {}
	if table.HasValue( AS._Objectives[obj:GetPriority()], obj ) then return end	-- just in case the same entity gets added more then once
	table.insert( AS._Objectives[obj:GetPriority()], obj )
	--print("Objectives")
//	print(obj:GetEnabled())
	--PrintTable( AS._Objectives )
end
hook.Add( "UT2K4AddObjective", "UT2K4_AS_AddObjective", AS.AddObjective )

if SERVER then 
	util.AddNetworkString( "SyncObjectives" )
	function AS.SyncObjectivesToClient( ply ) 
		MsgN("Sending objectives to client")

		net.Start( "SyncObjectives" )
		net.WriteTable(AS._Objectives)
		--PrintTable( AS._Objectives )
		if ply then
			net.Send( ply )
		else
			net.Broadcast() 
		end
	end
//	hook.Add( "PreCleanupMap", "UT2K4_AS_PreCleanupMap", AS.PreCleanupMap )
else
	net.Receive( "SyncObjectives", function( len )
		MsgN("Receiving objectives on client")
		table.Empty(AS._Objectives)
		PrintTable( AS._Objectives )
		AS._Objectives = net.ReadTable()
		--PrintTable( AS._Objectives )
	end ) 
end

hook.Add( "PlayerAuthed", "SyncObjectivesToNewPlayer", function( ply )
	if SERVER then AS.SyncObjectivesToClient( ply ) end
end)

function AS.InitObjectives() 
	MsgN("Initializing objectives")
	SetGlobalFloat("as_cur_objecive", 0)
//	if SERVER then AS.SyncObjectivesToClient() end
	-- enable the first objectives
	for _,ent in pairs( AS._Objectives[0] ) do
		if IsValid(ent) then
			ent:Enable()
		end
	end
end

function AS.ResetObjectives() 
	MsgN("Resetting objectives")
	SetGlobalFloat("as_cur_objecive", 0)
	if SERVER then AS.SyncObjectivesToClient() end
	local numObjs = table.Count(AS._Objectives)
	for p = 0, numObjs-1 do
		for _,ent in pairs( AS._Objectives[p] ) do
			if IsValid(ent) then
				ent:Reset()
			end
		end
	end
end

//AS.CurPriority = AS.CurPriority or 0
//SetGlobalFloat("as_cur_objecive", 0)
function AS.GetCurObjectives(no_optional) 
	//MsgN("Getting current objectives")
	local objs = {}
	if !AS._Objectives[GetGlobalFloat("as_cur_objecive", 0)] then 
		MsgN("There are no objectives for "..GetGlobalFloat("as_cur_objecive", 0))
		return nil 
	end
	for _,ent in pairs( AS._Objectives[GetGlobalFloat("as_cur_objecive", 0)] ) do
		if ent:GetOptional() and no_optional then
			-- If the ent is optional and we don't want optional ents the do nothing
			//MsgN(tostring(ent).. " is a optional entity")
		else
			table.insert( objs, ent )
		end
	end
	return objs
end

function AS.PrintObjectiveEntities() 
	MsgN("-- AS.PrintObjectiveEntities")
	local numObjs = table.Count(AS._Objectives)
	MsgN(numObjs)
	PrintTable(AS._Objectives)
	for p = 0, numObjs-1 do
		MsgN(p)
		for _,ent in pairs( AS._Objectives[p] ) do
			if IsValid(ent) then
				local col = Color( 0, 0, 255 )
				if ent:GetCompleted() then
					col = Color( 0, 255, 0 )
				elseif !ent:GetEnabled() then
					col = Color( 255, 0, 0 )
				end
				MsgC(col,"\t",ent:GetInfoAttack(),"\n")
			else
				table.remove( AS._Objectives[p], _ )
			end
		end
	end 

end
//hook.Add( "InitPostEntity", "UT2K4_AS_GetObjectiveEntities", AS.PrintObjectiveEntities )
//hook.Add( "PostCleanupMap", "UT2K4_AS_PreCleanupMap", AS.PrintObjectiveEntities )

-- Make this a little nicer
function AS.CompleteObjective(obj,plys)
	local numCurObjs = table.Count(AS._Objectives[obj:GetPriority()])
	local CompletedSet = false
	if numCurObjs == 1 then
		if AS._Objectives[obj:GetPriority() + 1] then
			-- Teleport defending team to new spawnpoints. Make this a option for objectives
			timer.Simple( 0.1, function() SendDefendersToNewSpawn() end )
			CompletedSet = true
			for _,nextobj in pairs( AS._Objectives[obj:GetPriority() + 1] ) do
				nextobj:Enable()
			end
			SetGlobalFloat("as_cur_objecive", obj:GetPriority() + 1 )
			net.Start( "ShowObjectivesForPlayer" )
			net.Broadcast()
		else
			hook.Call("CompleteRound", GAMEMODE, COMPLETE_OBJECTIVE)
		end
	else
		local numComplete = 0
		local numRequired = 0
		for _,otherObj in pairs( AS._Objectives[obj:GetPriority()] ) do
			if (!otherObj:GetEnabled() or otherObj:GetCompleted()) and !otherObj:GetOptional() then
				numComplete = numComplete + 1
			end
			if !otherObj:GetOptional() then
				numRequired = numRequired + 1
			end
		end
--		MsgN("numRequired",numRequired)
--		MsgN("numComplete",numComplete)
		if numComplete == numRequired then
			-- done all required 
			CompletedSet = true
			-- disable all optional objectives
			--MsgN("-- complete all required objectives, disable them all and enable the next set")
			for _,otherObj in pairs( AS._Objectives[obj:GetPriority()] ) do
				if IsValid(otherObj) then
					--MsgN("-- Disabled "..tostring(otherObj).." ("..otherObj:GetInfoName()..")")
					--otherObj:Disable()	-- just disable all of them cause it wont matter
					otherObj:SetCompleted(true)	-- Fuck that, mark it complete because it kinda was
				end
			end
			-- enable the next objectives
			if AS._Objectives[obj:GetPriority() + 1] then
				for _,nextobj in pairs( AS._Objectives[obj:GetPriority() + 1] ) do
					--MsgN("-- Enabled "..tostring(nextobj).." ("..nextobj:GetInfoName()..")")
					if IsValid(nextobj) then
						nextobj:Enable()
					end
				end
				SetGlobalFloat("as_cur_objecive", obj:GetPriority() + 1 )
				net.Start( "ShowObjectivesForPlayer" )
				net.Broadcast()
				
				-- Teleport defending team to new spawnpoints. Make this a option for objectives
				timer.Simple( 0.1, function() SendDefendersToNewSpawn() end )
			else
				--MsgN("----- All objectives complete")
				hook.Call("CompleteRound", GAMEMODE, COMPLETE_OBJECTIVE)
			end
		end
	end
	
//	AS.PrintObjectiveEntities()
	return CompletedSet
	--[[
	local numObjs = table.Count(AS._Objectives)
	MsgN(numObjs)
	PrintTable(AS._Objectives)
	for p = 0, numObjs-1 do
		MsgN(p.."------------------------------------------------------------------------")
		for _,ent in pairs( AS._Objectives[p] ) do
			if IsValid(ent) then
				--AS._Objectives[ent.priority] = AS._Objectives[ent.priority] or {}
				--local info = {}
				local class = ent:GetClass()
				local col = Color( 0, 0, 255 )
				if ent:GetCompleted() then
					col = Color( 0, 255, 0 )
				elseif !ent:GetEnabled() then
					col = Color( 255, 0, 0 )
				end
				MsgC(col,"\t",ent:GetInfoAttack(),"\n")
			else
				table.remove( AS._Objectives[p], _ )
			end
		end
	end --]]
end
hook.Add( "UT2K4CompleteObjective", "UT2K4_AS_CompleteObjective", AS.CompleteObjective )


if SERVER then 
	util.AddNetworkString( "ClearObjectives" )
	util.AddNetworkString( "ShowObjectivesForPlayer" )
	function AS.PreCleanupMap(obj)
		table.Empty(AS._Objectives)	-- This should help keep stuff from breaking
		net.Start( "ClearObjectives" )
		net.Broadcast() 
	end
	hook.Add( "PreCleanupMap", "UT2K4_AS_PreCleanupMap", AS.PreCleanupMap )
else
	net.Receive( "ClearObjectives", function( len )
		table.Empty(AS._Objectives)	-- This should also help keep stuff from breaking
	end ) 
end

function Pulse(high,low,speed)
	local height = high-low
	local sinheight = height/2
	local t = low+sinheight
	local pulse = (math.sin(CurTime()*speed)*sinheight)+t
	return pulse
end

hook.Add("ShowSpare1", "ShowObjectivesForPlayer", function(ply)
	net.Start( "ShowObjectivesForPlayer" )
	net.Send( ply )
end)

if SERVER then return end
net.Receive( "ShowObjectivesForPlayer", function()
	--AS.HUDShowObjectives = CurTime()
	if AS.HUDShowObjectives then
		AS.HUDShowObjectives = CurTime() - AS.HUDShowObjectivesSpeed
	else
		AS.HUDShowObjectives = CurTime()
	end
end ) 


local HoldArrow = surface.GetTextureID( "vgui/assault/HoldArrow" )
local HoldCircle = surface.GetTextureID( "vgui/assault/HoldCircle" )
local HoldObjective = surface.GetTextureID( "vgui/assault/HoldObjective" )
local OptionalObjective = surface.GetTextureID( "vgui/assault/OptionalObjective" )
local PrimaryObjective = surface.GetTextureID( "vgui/assault/PrimaryObjective" )
local TargetObjective = surface.GetTextureID( "vgui/assault/TargetObjective" )
local TouchObjective = surface.GetTextureID( "vgui/assault/TouchObjective" )
local VehicleObjective = surface.GetTextureID( "vgui/assault/VehicleObjective" )
local ObjectiveIcon = { [OBJECTIVE_HOLD] = HoldObjective, [OBJECTIVE_TOUCH] = TouchObjective, [OBJECTIVE_DESTROY] = TargetObjective, [OBJECTIVE_VEHICLE] = VehicleObjective }
local width = 300
local height = 400
local Fade_Bar 		= surface.GetTextureID( "vgui/assault/Fade_bar" );
local Ring 		= surface.GetTextureID( "particle/particle_ring_wave_additive" );
local Ring_Outline 		= surface.GetTextureID( "particle/particle_ring_sharp" );
local Clock 		= surface.GetTextureID( "vgui/assault/clock" )

local function LerpColor( delta, CF, CT )
	return Color( Lerp( delta, CF.r, CT.r ), Lerp( delta, CF.g, CT.g ), Lerp( delta, CF.b, CT.b ), Lerp( delta, CF.a, CT.a ))
end

local function Alpha(c,a)
	return Color(c.r,c.g,c.b,a)
end

 
local function DrawObjectiveIcon(obj,x,y,inView)
	if obj:GetAlert() then
		//surface.SetDrawColor( 200, 200, 0, (math.sin(CurTime()*24)*75)+75 )
		surface.SetDrawColor( 200, 200, 0, Pulse(150,0,24) )
	else
		//surface.SetDrawColor( 42, 62, 200, math.abs(math.sin(CurTime()*3))*150 )
		local col = team.GetColor(GetDefendingTeam())
		surface.SetDrawColor( col.r, col.g, col.b, Pulse(150,0,6) )
		//surface.SetDrawColor( 42, 62, 200, Pulse(150,0,6) )
	end

	if inView then
		surface.SetTexture( ObjectiveIcon[obj:GetIcon()] )
	else
		if obj:GetOptional() then
			surface.SetTexture( OptionalObjective )
		else
			surface.SetTexture( PrimaryObjective )
		end
	end
	surface.DrawTexturedRect( x-75, y-75, 150, 150 )	
end

local barwidth = 200
local barhight = 16
local function DrawCompletionBar(obj,x,y,inView)
	if obj:HasSpawnFlags(16) then return end
	draw.RoundedBox( barhight/2, x-barwidth/2, y-80, barwidth, barhight, team.GetColor(LocalPlayer():Team()) )
	draw.RoundedBox( barhight/4, x+barhight/4-barwidth/2, y+barhight/4-80, (barwidth-barhight/2)*((100-obj:GetPercentComplete())/100), barhight/2, Color(0,255,0) )

//	draw.RoundedBox( 8, x-104, y-80, 208, 16, team.GetColor(LocalPlayer():Team()) )
//	draw.RoundedBox( 4, x+4-104, y+4-80, 200-obj:GetPercentComplete()*2, 8, Color(0,255,0) )
end

local space = ScreenScale(2)
local padding = ScreenScale(6)
local text = {}
local function DrawObjectivesInfoBox(p)
	surface.SetFont("Small_Text")
	--
	--- This puts all the objective info in a table and gives us the overal text size
	--
	local allTextH = 0
	local maxW	= 0
//	local text = {}
	local numObjs = table.Count(AS._Objectives)
	for p = 0, numObjs-1 do
		text[p] = {}
		for _,ent in pairs( AS._Objectives[p] ) do
			if IsValid(ent) then
				local obj = {}
				obj.Com = ent:GetCompleted()
				obj.Ena = ent:GetEnabled()
				obj.Opt = ent:GetOptional()
				obj.Ale = ent:GetAlert()
				local col = Color( 255, 208, 64 ,255 )	-- Current objective
				if ent:GetCompleted() then
					col = Color( 150, 150, 150, 255 )	-- Finished objective
				elseif !ent:GetEnabled() then
					col = Color( 235, 235, 235, 255 )	-- Future objectives
				end 
				obj.Col = col
				obj.Ypos = allTextH
				local info = "No Information?"
				if LocalPlayer():IsAttacking(true) then
					info = ent:GetInfoAttack()
				else
					info = ent:GetInfoDefend()
				end
				obj.Tex = (table.Count(text[p]) == 0 and p or "  ").."  -\t"..(ent:GetOptional() and "¤ " or "")..info
				obj.TexW, obj.TexH = surface.GetTextSize(obj.Tex)
				allTextH = allTextH + obj.TexH + space
				maxW = math.max(maxW,obj.TexW)
				
				
				table.insert( text[p], obj )
				//MsgC(col,"\t",(ent:GetOptional() and "* " or "")..ent:GetInfoAttack(),"\n")
//				MsgC(col,p.."  -\t",(ent:GetOptional() and "* " or "")..ent:GetInfoAttack(),"\n")
			end 
		end
	end 
	allTextH = allTextH - space	-- Removes the extra spacing at the end
	
	local w, h = surface.GetTextSize("Objectives")
	
	local topBoxH = h + padding*2
	
	
	local totalH = topBoxH + padding*2 + allTextH
	--
	--- Now we draw all of it
	--
	local y = Lerp( p, -totalH, 0 )	-- This is the ypos for the top of the list
	local MyTeamCol = team.GetColor(LocalPlayer():Team())
	local lowPow = math.pow(2, math.floor(math.log(ScreenScale(6))/math.log(2)))
	
	draw.RoundedBox( lowPow, ScrW()-maxW - padding*2, y, maxW + padding*2, topBoxH, Alpha(MyTeamCol,80)  )	
	draw.SimpleTextOutlined("Objectives", "Small_Text",  ScrW()-(maxW + padding*2)/2-w/2, y + padding, Color(235,235,235,255), 0, 0, 1, Color(25,25,25,255))
	
	draw.RoundedBox( lowPow, ScrW()-maxW - padding*2, y+ topBoxH, maxW + padding*2, allTextH + padding*2, Alpha(MyTeamCol,80)  )	
	for p = 0, numObjs-1 do
		for _,obj in pairs( text[p] ) do
			draw.SimpleTextOutlined(obj.Tex, "Small_Text",  ScrW()-maxW - padding, y + topBoxH + padding + obj.Ypos, obj.Col, 0, 0, 1, Color(25,25,25,255))
			
			
		end
	end
	
//	local MyTeamCol = team.GetColor(LocalPlayer():Team())
							
//	draw.RoundedBox( 20, ScrW()-maxW, y, maxW, allTextH, Alpha(MyTeamCol,80)  )
//	draw.RoundedBox( 20, ScrW()-width, y, width, height, Alpha(MyTeamCol,80)  )
//	surface.SetDrawColor( Alpha(MyTeamCol,138) );
//	surface.SetTexture( Fade_Bar );
//	surface.DrawTexturedRect( ScrW()-width, y , width, height );
end

local function DrawWaitingHUD()
	local MyTeamCol = team.GetColor(LocalPlayer():Team())
	local text = "Round starting in "..string.FormattedTime( math.max(0, GetGlobalFloat("as_round_end", 600) - CurTime()), "%02i:%02i")
	surface.SetFont("Large_Text")
	local Width, Height = surface.GetTextSize(text)
	
	surface.SetDrawColor( Alpha(MyTeamCol,138) );
	surface.SetTexture( Fade_Bar );
	surface.DrawTexturedRect( ScrW()/2-(Width+ScreenScale(4))/2, ScreenScale(4) , Width+ScreenScale(4), ScreenScale(20) );
	 
	draw.SimpleTextOutlined(text, "Large_Text", ScrW()/2-Width/2, ScreenScale(1), Color(235, 235, 235, 255), 0, 0, 1, Color(25,25,25,255))
	
	surface.SetTexture( Ring )
	surface.SetDrawColor( Color(235, 235, 235, 255) );
	surface.DrawTexturedRect( ScrW()/2-Width/2-ScreenScale(30), 0 , ScreenScale(28), ScreenScale(28) );	
	surface.SetTexture( Ring_Outline )
	surface.SetDrawColor( Color(25, 25, 25, 255) );
	surface.DrawTexturedRect( ScrW()/2-Width/2-ScreenScale(30), 0 , ScreenScale(28), ScreenScale(28) );	
	
	surface.SetTexture( Clock )
	local col = Color(235, 235, 235, 255)
	surface.SetDrawColor( col.r, col.g, col.b, Pulse(250,50,7) )
	surface.DrawTexturedRect( ScrW()/2-Width/2-ScreenScale(28), ScreenScale(2) , ScreenScale(24), ScreenScale(24) );	
end

AS.HUDShowObjectives = CurTime()
AS.HUDShowObjectivesTime = 5		-- How long to show the objective window for
AS.HUDShowObjectivesSpeed = 0.5
hook.Add("HUDPaint", "UT2K4ASHUD", function()
//	if GetRoundState() == ROUND_STARTING then DrawWaitingHUD() return end
	local MyTeamCol = team.GetColor(LocalPlayer():Team())
	--[[
	if AS.HUDShowObjectives then
		local time = CurTime() - AS.HUDShowObjectives
		local showtime = AS.HUDShowObjectivesTime
		local p = 0		
		if time < 1 then
			p = Lerp( time, 0, 1 )
		elseif time < showtime + 1 then
			p = 1
		elseif time < showtime + 2 then
			p = Lerp( time - (showtime + 1), 1, 0 )
		else
			AS.HUDShowObjectives = nil
			return
		end
		DebugInfo(1,CurTime())
		DebugInfo(2,AS.HUDShowObjectives)
		DebugInfo(3,time)
		DebugInfo(4,showtime)
		DebugInfo(5,p)
		
		DrawObjectivesInfoBox(p)
	end	
	--]]
	if AS.HUDShowObjectives then
		local time = CurTime() - AS.HUDShowObjectives
		local showtime = AS.HUDShowObjectivesTime
		local animtime = AS.HUDShowObjectivesSpeed
		local p = 0
		if time < animtime then
			p = 1 + -(animtime - time)/animtime
		elseif time < showtime + animtime then
			p = 1
		elseif time < showtime + (animtime*2) then
			p =(animtime - (time - (showtime + animtime)))/animtime
		
		
		
			--p = ((showtime + animtime*2)-time)
		else
			AS.HUDShowObjectives = nil
			return
		end
	
		DrawObjectivesInfoBox(p)	-- p = percent 0-1
	end
	
	--
	--- Objective waypoints
	--
	local objs = AS.GetCurObjectives() 
	if !objs then return end
	for _,obj in pairs( objs ) do
		if IsValid(obj) and !obj:GetCompleted() then
			local pos = obj:GetPos()
			local scrPosData = pos:ToScreen()
			local x = scrPosData.x
			local y = scrPosData.y
			local visible = true--scrPosData.visible
			if visible then //and obj:GetEnabled() then 
				//draw.DrawText( obj:GetPercentComplete().."%", "TargetID", x, y, Color( 255,255,255,255 ), TEXT_ALIGN_CENTER )
				local tr = util.TraceLine( { start = EyePos(), endpos = obj:GetPos(), mask = MASK_VISIBLE } )
				local inView = tr.Fraction == 1	--The entity is a point entity so the trace should make it right to its pos
				DrawObjectiveIcon(obj,x,y,inView)

				DrawCompletionBar(obj,x,y,inView)
			end
		end
	end
	
	--
	--- Current objective info
	--

	local obj = AS.GetCurObjectives(true)[1] 
	local text = "Something went wrong"
	if LocalPlayer():IsAttacking(true) then
		text = obj:GetInfoAttack()
	else
		text = obj:GetInfoDefend()
	end
	surface.SetFont("Large_Text")
	local Width, Height = surface.GetTextSize(text)
	
	surface.SetDrawColor( Alpha(MyTeamCol,138) );
	surface.SetTexture( Fade_Bar );
	surface.DrawTexturedRect( ScrW()/2-(Width+ScreenScale(4))/2, ScreenScale(4) , Width+ScreenScale(4), ScreenScale(20) );
	 
	draw.SimpleTextOutlined(text, "Large_Text", ScrW()/2-Width/2, ScreenScale(1), Color(235, 235, 235, 255), 0, 0, 1, Color(25,25,25,255))
	
	surface.SetTexture( Ring )
	surface.SetDrawColor( Color(235, 235, 235, 255) );
	surface.DrawTexturedRect( ScrW()/2-Width/2-ScreenScale(30), 0 , ScreenScale(28), ScreenScale(28) );	
	surface.SetTexture( Ring_Outline )
	surface.SetDrawColor( Color(25, 25, 25, 255) );
	surface.DrawTexturedRect( ScrW()/2-Width/2-ScreenScale(30), 0 , ScreenScale(28), ScreenScale(28) );	
	
	surface.SetTexture( ObjectiveIcon[obj:GetIcon()] )
	surface.SetDrawColor( team.GetColor(GetDefendingTeam()) );
	if obj:GetAlert() then
		//surface.SetDrawColor( 200, 200, 0, (math.sin(CurTime()*24)*75)+75 )
		surface.SetDrawColor( 200, 200, 0, Pulse(150,0,24) )
	else
		//surface.SetDrawColor( 42, 62, 200, math.abs(math.sin(CurTime()*3))*150 )
		local col = team.GetColor(GetDefendingTeam())
		surface.SetDrawColor( col.r, col.g, col.b, Pulse(150,0,6) )
		//surface.SetDrawColor( 42, 62, 200, Pulse(150,0,6) )
	end
	surface.DrawTexturedRect( ScrW()/2-Width/2-ScreenScale(28), ScreenScale(2) , ScreenScale(24), ScreenScale(24) );	
	
end)
concommand.Add( "showobjectives",function( ply )
	if AS.HUDShowObjectives then
		AS.HUDShowObjectives = CurTime() - 1
	else
		AS.HUDShowObjectives = CurTime()-- ( AS.HUDShowObjectives and AS.HUDShowObjectives > 1 ) and CurTime() - 1 or CurTime()
	end
end )