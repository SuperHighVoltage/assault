include( "shared.lua" )
include( "player_ext.lua" )
include( "objectives.lua" )
include( "vehicles.lua" )

DEFINE_BASECLASS( "gamemode_base" )

function GM:Initialize()
	
end 

function GM:PostDrawViewModel( vm, ply, weapon )

	if ( weapon.UseHands || !weapon:IsScripted() ) then

		local hands = LocalPlayer():GetHands()
		if ( IsValid( hands ) ) then hands:DrawModel() end

	end

end

local Fade_Bar 		= surface.GetTextureID( "vgui/assault/Fade_bar" );			//Faded bar
local Clock 		= surface.GetTextureID( "vgui/assault/clock" );				//Clock icon
local Cross 		= surface.GetTextureID( "vgui/assault/Health3" );			//Health icon
local Sheild 		= surface.GetTextureID( "vgui/assault/Sheild" );			//Sheild icon
local Ammo 			= surface.GetTextureID( "vgui/assault/Ammo" );				//Ammo icon

local fontdata = {}
	fontdata.font = "Eurostile-Extended"	
	fontdata.size = ScreenScale(24)	
	fontdata.weight = 600	//boldness
	fontdata.blursize = 0
	fontdata.scanlines = 0	//needs to be bigger then one to have an effect
	fontdata.antialias = true
	fontdata.underline = false
	fontdata.italic = false
	fontdata.strikeout = false
	fontdata.rotary = false		//"Seems to add a line in the middle of each letter"
	fontdata.shadow = false
	fontdata.additive = false
	fontdata.outline = false
surface.CreateFont("Large_Text",fontdata)

local fontdata = {}
	fontdata.font = "Eurostile-Extended"	
	fontdata.size = ScreenScale(7)	
	fontdata.weight = 600	//boldness
	fontdata.blursize = 0
	fontdata.scanlines = 0	//needs to be bigger then one to have an effect
	fontdata.antialias = true
	fontdata.underline = false
	fontdata.italic = false
	fontdata.strikeout = false
	fontdata.rotary = false		//"Seems to add a line in the middle of each letter"
	fontdata.shadow = false
	fontdata.additive = false
	fontdata.outline = false
surface.CreateFont("Small_Text",fontdata)

local function LerpColor( delta, CF, CT )
	return Color( Lerp( delta, CF.r, CT.r ), Lerp( delta, CF.g, CT.g ), Lerp( delta, CF.b, CT.b ), Lerp( delta, CF.a, CT.a ))
end

local function Alpha(c,a)
	return Color(c.r,c.g,c.b,a)
end

local white = Color(235, 235, 235, 255)
local yellow = Color( 255, 208, 64 ,255 )
local red = Color( 255, 48, 0, 255 )
local ammoBarW = 0
hook.Add("HUDPaint", "AS_Clock", function()
if GetRoundState() == ROUND_STARTING then return end
---[[
	surface.SetDrawColor( Alpha(team.GetColor(LocalPlayer():Team()),138) );
	surface.SetTexture( Fade_Bar );
	surface.DrawTexturedRect( ScreenScale(10), ScreenScale(4) , ScreenScale(74), ScreenScale(20) );
	local timeLeft = math.max(0, GetGlobalFloat("as_round_end", 600) - CurTime())
	local TColor = white
	if timeLeft < 10 then
		TColor = red
	elseif timeLeft < 20 then
		TColor = LerpColor( (timeLeft-10)/10, red, yellow )
	elseif timeLeft < 50 then
		TColor = yellow
	elseif timeLeft < 60 then
		TColor = LerpColor( (timeLeft-50)/10, yellow, white )
	end
	local text = string.FormattedTime( timeLeft, "%02i:%02i")
	draw.SimpleTextOutlined(text, "Large_Text", ScreenScale(27), ScreenScale(1), TColor, 0, 0, 1, Color(25,25,25,255))
	surface.SetDrawColor( TColor );
	surface.SetTexture( Clock );
	surface.DrawTexturedRect( ScreenScale(1), ScreenScale(1) , ScreenScale(26), ScreenScale(26) );	
//	surface.DrawTexturedRect( 0, 0 , ScreenScale(28), ScreenScale(28) );	
--]]
	if !LocalPlayer():Alive() then return end
--
--- Health
--
	surface.SetDrawColor( Alpha(team.GetColor(LocalPlayer():Team()),138) );
	surface.SetTexture( Fade_Bar );
	surface.DrawTexturedRect( ScreenScale(10), ScrH()-ScreenScale(4)-ScreenScale(20) , ScreenScale(56), ScreenScale(20) );
	local health = LocalPlayer():Health()
	local HColor = white
	if health < 10 then
		HColor = red
	elseif health < 20 then
		HColor = LerpColor( (health-10)/10, red, yellow )
	elseif health < 30 then
		HColor = yellow
	elseif health < 40 then
		HColor = LerpColor( (health-30)/10, yellow, white )
	end
	draw.SimpleTextOutlined(health, "Large_Text", ScreenScale(27), ScrH()-ScreenScale(27), HColor, 0, 0, 1, Color(25,25,25,255))
	surface.SetDrawColor( HColor );								
	surface.SetTexture( Cross );
	surface.DrawTexturedRect( ScreenScale(1), ScrH()-ScreenScale(27) , ScreenScale(26), ScreenScale(26) );	
	
	if LocalPlayer():InVehicle() and LocalPlayer():GetVehicle():GetNWInt("Health",-1) != -1 then
		local Vhealth = LocalPlayer():GetVehicle():GetNWInt("Health",-1)
		local HColor = white
		if Vhealth < 40 then
			HColor = red
		elseif Vhealth < 60 then
			HColor = LerpColor( (Vhealth-40)/20, red, yellow )
		elseif Vhealth < 80 then
			HColor = yellow
		elseif Vhealth < 100 then
			HColor = LerpColor( (Vhealth-80)/20, yellow, white )
		end
		surface.SetDrawColor( Alpha(team.GetColor(LocalPlayer():Team()),138) );
		surface.SetTexture( Fade_Bar );
		surface.DrawTexturedRect( ScreenScale(10)+ScreenScale(70), ScrH()-ScreenScale(4)-ScreenScale(20) , ScreenScale(56), ScreenScale(20) );
		draw.SimpleTextOutlined(Vhealth, "Large_Text", ScreenScale(27)+ScreenScale(70), ScrH()-ScreenScale(27), HColor, 0, 0, 1, Color(25,25,25,255))
		surface.SetDrawColor( HColor );								
		surface.SetTexture( Cross );
		surface.DrawTexturedRect( ScreenScale(1)+ScreenScale(70), ScrH()-ScreenScale(27) , ScreenScale(26), ScreenScale(26) );	
	end
	
	local armor = LocalPlayer():Armor()
	if armor != 0 then
		local SColor = white
		if armor < 5 then
			SColor = red
		elseif armor < 10 then
			SColor = LerpColor( (armor-5)/5, red, yellow )
		elseif armor < 20 then
			SColor = LerpColor( (armor-10)/10, yellow, white )
		end
		surface.SetDrawColor( Alpha(team.GetColor(LocalPlayer():Team()),138) );
		surface.SetTexture( Fade_Bar );
		surface.DrawTexturedRect( ScreenScale(10), ScrH()-ScreenScale(48) , ScreenScale(56), ScreenScale(20) );
		draw.SimpleTextOutlined(armor, "Large_Text", ScreenScale(27), ScrH()-ScreenScale(51), SColor, 0, 0, 1, Color(25,25,25,255))
		surface.SetDrawColor( SColor );								
		surface.SetTexture( Sheild );
		surface.DrawTexturedRect( ScreenScale(1), ScrH()-ScreenScale(51) , ScreenScale(26), ScreenScale(26) );	
	end
--							
--- Ammo
--
	if !LocalPlayer():GetActiveWeapon():IsValid() then return end
	local Weapons = { weapon_physgun=true, weapon_physcannon=true, gmod_tool=true, weapon_stunstick=true, weapon_crowbar=true }	//don't draw the box if your using one of these weapons
	if LocalPlayer():InVehicle() or Weapons[LocalPlayer():GetActiveWeapon():GetClass()] then return end
	
	local clip1 = LocalPlayer():GetActiveWeapon():Clip1()
	local ammo1 = LocalPlayer():GetAmmoCount(LocalPlayer():GetActiveWeapon():GetPrimaryAmmoType())
	local clip2 = LocalPlayer():GetActiveWeapon():Clip2()
	local ammo2 = LocalPlayer():GetAmmoCount(LocalPlayer():GetActiveWeapon():GetSecondaryAmmoType())
	if ammo2 <= 0 then ammo2 = "" end
	if clip1 == -1 then 
		clip1 = ammo1
		ammo1 = "" 
	end
	surface.SetFont("Small_Text")
	local ammo1W, _ = surface.GetTextSize(ammo1)
	surface.SetFont("Large_Text")
	local clip1W, _ = surface.GetTextSize(clip1)
	local ammo2W, _ = surface.GetTextSize(ammo2)
	
	
	surface.SetDrawColor( Alpha(team.GetColor(LocalPlayer():Team()),138) );
	surface.SetTexture( Fade_Bar );
	local barW = ammo2W+ammo1W+clip1W+ScreenScale(18)
	ammoBarW = math.Approach( ammoBarW, barW, 1 )
	surface.DrawTexturedRect( ScrW()-ammoBarW-ScreenScale(22), ScrH()-ScreenScale(4)-ScreenScale(20) , ammoBarW, ScreenScale(20) );

	draw.SimpleTextOutlined(ammo2, "Large_Text", ScrW()-ScreenScale(27)-ammo2W, ScrH()-ScreenScale(27), white, 0, 0, 1, Color(25,25,25,255))
	draw.SimpleTextOutlined(ammo1, "Small_Text", ScrW()-ScreenScale(32)-ammo2W-ammo1W, ScrH()-ScreenScale(12), white, 0, 0, 1, Color(25,25,25,255))
	draw.SimpleTextOutlined(clip1, "Large_Text", ScrW()-ScreenScale(37)-ammo2W-ammo1W-clip1W, ScrH()-ScreenScale(27), white, 0, 0, 1, Color(25,25,25,255))
	
	surface.SetDrawColor( white );								
	surface.SetTexture( Ammo );
	surface.DrawTexturedRect( ScrW()-ScreenScale(27), ScrH()-ScreenScale(27) , ScreenScale(26), ScreenScale(26) );	
end)


//Thank you Lexic
local tohide = { -- This is a table where the keys are the HUD items to hide
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudCrosshair"] = false
}
//http://wiki.garrysmod.com/?title=Hud_Elements		<---more HUD elements
local function HUDShouldDraw(name)
	if name == "CHudCrosshair" then
		//return !tobool(UT2K4_Show_CrossHair)
	end
	if (tohide[name]) then     -- If the HUD name is a key in the table
		return false
	end
end
hook.Add("HUDShouldDraw", "How to: HUD Example HUD hider", HUDShouldDraw)