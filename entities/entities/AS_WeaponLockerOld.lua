
AddCSLuaFile()
DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Weapon Locker"
ENT.Author			= "HighVoltage"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category		= "UT2K4"

ENT.Spawnable			= true
ENT.AdminOnly			= false
ENT.Editable			= true
 
function ENT:Initialize()
	if ( CLIENT ) then
		self.models = {}
		self.models.top = {Model = "models/props_junk/sawblade001a.mdl", Pos = Vector(0,0,45), Ang = Angle(0,0,0)}
		self.models.mid = {Model = "models/props_c17/canister01a.mdl", Pos = Vector(0,0,30), Ang = Angle(0,0,0)}
		self.models.bot = {Model = "models/props_vehicles/carparts_wheel01a.mdl", Pos = Vector(0,0,5), Ang = Angle(0,0,90)}
	else
		self:SetModel( "models/props_c17/oildrum001.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetUseType( ONOFF_USE )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
		self:SetTrigger( true )
		
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
		end
		if self.Frozen then
			self:SetMoveType( MOVETYPE_NONE )
		end	
		self.Weapons = {}
		
		
		local entSpriteEye = ents.Create("env_sprite")
		entSpriteEye:SetKeyValue("model", "effects/blueflare1.vmt")	//Find something else
		entSpriteEye:SetKeyValue("rendermode", "5") 
		entSpriteEye:SetKeyValue("rendercolor", "224 154 63") 
		entSpriteEye:SetKeyValue("scale", "0.6") 
		entSpriteEye:SetPos(self:LocalToWorld(Vector(0,0,60)))
		entSpriteEye:SetParent(self)
		//entSpriteEye:Fire("SetParentAttachment", "0", 0)
		entSpriteEye:Spawn()
		entSpriteEye:Activate()
		self:DeleteOnRemove(entSpriteEye)
		entSpriteEye:Fire("ShowSprite", "", 0)	
		self.entSpriteEye = entSpriteEye
	end
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	
	local ut2k4weps = {"ut2k4_lightning_gun", "ut2k4_shock_rifle", "ut2k4_bio_rifle", "ut2k4_minigun", "ut2k4_flak_cannon", "ut2k4_rocket_launcher", "ut2k4_assault_rifle", "ut2k4_grenade_launcher", "ut2k4_mine_layer", "ut2k4_classic_sniper"}
	local t = {}
	for i = 1, math.random( 4, 7 ) do
		local wep = table.Random( ut2k4weps )
		table.insert( t, wep )
		table.RemoveByValue( ut2k4weps, wep )
	end
	local ent = ents.Create( ClassName )
	ent:SetWeapons( t )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()
	
	return ent
	
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",	0, "Enabled", 	{ KeyName = "enabled", 	Edit = { type = "Boolean", 		order = 1 } }  );
	self:NetworkVar( "Float",	0, "LastPickup" );

	-- defaults
	self:SetEnabled( true )
	self:SetLastPickup( 0 )
end

function ENT:SetWeapons(weps)
	self:SetNetworkedInt( "WeaponCount", 0 )
	for k,v in pairs( weps ) do
		local count = self:GetNetworkedInt( "WeaponCount", 0 )
		count = count + 1
		self:SetNetworkedInt( "WeaponCount", count )
		self:SetNetworkedString( "Weapon"..count, v )
	end
end

/*---------------------------------------------------------
   Name: Touch
---------------------------------------------------------*/
function ENT:StartTouch( entity )
	
	if !self:GetEnabled() then return end		// Don't do anything if turned off
	
	if ( entity:IsValid() and entity:IsPlayer() and self:GetLastPickup() + 5 < CurTime() ) then
		self:SetLastPickup( CurTime() )
		for i = 1, self:GetNetworkedInt( "WeaponCount", 1 ) do
			local wep = self:GetNetworkedString( "Weapon"..i )
			if entity:HasWeapon(wep) then
				local ammotype = weapons.Get(wep).Primary.Ammo
				entity:GiveAmmo(weapons.Get(wep).Primary.DefaultAmmoAmmount, ammotype)
			else
				entity:Give(wep)
			end
		end
		self:EmitSound( "UT2K4/Weapons/SwitchToMiniGun.wav" )
		self:TriggerOutput("OnPickup", self)
		//PrintTable(entity:GetVehicle():GetSaveTable( ))
	end
end

function ENT:KeyValue( key, value )
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end
	if ( key == "angles" ) then
		local Sep = string.Explode(" ", value)
		local ang = (Angle(Sep[1], Sep[2], Sep[3]))
		self.angle = ang
	end	
	if ( string.Left( key, 6 ) == "Weapon" ) and value != "" then
		local count = self:GetNetworkedInt( "WeaponCount", 0 )
		count = count + 1
		self:SetNetworkedInt( "WeaponCount", count )
		self:SetNetworkedString( "Weapon"..count, value )
	end
	if ( key == "enabled" ) then
		self:SetEnabled(value)
	end	
	if ( key == "spawnflags" ) then
		if value == "1" then
			self.Frozen = true
		end
	end	
end

function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "TurnOn" ) then
		self:SetEnabled( true )
	end	
	if ( inputName == "TurnOff" ) then
		self:SetEnabled( false )
	end	
end

function ENT:Think()
	if SERVER and self.entSpriteEye then
		if !self:GetEnabled() then
			self.entSpriteEye:SetKeyValue("rendercolor", "255 0 0") 
		elseif self:GetLastPickup() + 5 > CurTime() then
			self.entSpriteEye:SetKeyValue("rendercolor", "0 0 255") 
		else
			self.entSpriteEye:SetKeyValue("rendercolor", "0 255 0") 
		end
	end
	if CLIENT then
		if self.models.top.Entity then
			self.models.top.Entity:SetPos(self:LocalToWorld( self.models.top.Pos ))
			self.models.top.Entity:SetAngles(self:LocalToWorldAngles( self.models.top.Ang ))
			self.models.mid.Entity:SetPos(self:LocalToWorld( self.models.mid.Pos ))
			self.models.mid.Entity:SetAngles(self:LocalToWorldAngles( self.models.mid.Ang ))
			self.models.bot.Entity:SetPos(self:LocalToWorld( self.models.bot.Pos ))
			self.models.bot.Entity:SetAngles(self:LocalToWorldAngles( self.models.bot.Ang ))
		end
		if self.WeaponModels then
			for k,v in pairs( self.WeaponModels ) do
				self.WeaponModels[k].Entity:SetPos(self:LocalToWorld( self.WeaponModels[k].Pos + (self.WeaponModels[k].Ang:Up()*15) ) )
				self.WeaponModels[k].Entity:SetAngles(self:LocalToWorldAngles( self.WeaponModels[k].Ang ))
			end
			if self:GetLastPickup() + 5 > CurTime() then
				if self.WeaponModels then
					for k,v in pairs( self.WeaponModels ) do
						if self.WeaponModels[k].Entity then
							self.WeaponModels[k].Entity:Remove()
							self.WeaponModels[k].Entity = nil
						end
					end
					self.WeaponModels = nil
				end
			end
		end
	end
end

function ENT:OnRemove()
	if CLIENT then
		self.models.top.Entity:Remove()
		self.models.mid.Entity:Remove()
		self.models.bot.Entity:Remove()
		if self.WeaponModels then
			for k,v in pairs( self.WeaponModels ) do
				self.WeaponModels[k].Entity:Remove()
			end
		end
	end
end

if SERVER then return end
if false then return end

ENT.HL2WepData = {["weapon_shotgun"] = "models/weapons/w_shotgun.mdl"}

local Laser = Material( "sprites/Gridplate" )
function ENT:Draw()
--[[
	render.SuppressEngineLighting( true )
	if !self:GetEnabled() then
		render.SetColorModulation( 1, 0, 0 )
	elseif self:GetLastPickup() + 5 > CurTime() then
		render.SetColorModulation( 1, 1, 1 )
	else
		render.SetColorModulation( 0, 1, 0 )
	end
//	render.SetBlend( 0.5 )
	self.Entity:DrawModel()
	render.SuppressEngineLighting( false )
	render.SetColorModulation( 1, 1, 1 )
//	render.SetBlend( 1 )
	--]]
	if !self.models.top.Entity then
		self.models.top.Entity = ClientsideModel(self.models.top.Model, RENDERGROUP_BOTH)
		self.models.top.Entity:SetPos(self:LocalToWorld( self.models.top.Pos ))
		self.models.top.Entity:SetAngles(self:LocalToWorldAngles( self.models.top.Ang ))
		self.models.mid.Entity = ClientsideModel(self.models.mid.Model, RENDERGROUP_BOTH)
		self.models.mid.Entity:SetPos(self:LocalToWorld( self.models.mid.Pos ))
		self.models.mid.Entity:SetAngles(self:LocalToWorldAngles( self.models.mid.Ang ))
		self.models.bot.Entity = ClientsideModel(self.models.bot.Model, RENDERGROUP_BOTH)
		self.models.bot.Entity:SetPos(self:LocalToWorld( self.models.bot.Pos ))
		self.models.bot.Entity:SetAngles(self:LocalToWorldAngles( self.models.bot.Ang ))
	end
		
	if self:GetLastPickup() + 5 < CurTime() then
		if !self.WeaponModels and self:GetNetworkedString( "Weapon1", "" ) != "" then			
			self.WeaponModels = {}
			for i = 1, self:GetNetworkedInt( "WeaponCount", 1 ) do
				self.WeaponModels["Weapon"..i] = {}
				self.WeaponModels["Weapon"..i].Class = self:GetNetworkedString( "Weapon"..i )
			end
		
			local numweps = self:GetNetworkedInt( "WeaponCount", 1 )
			local ang = 360/numweps
			local curwep = 0
			local startvec = Vector(0,0,35)
			for k,v in pairs( self.WeaponModels ) do
				local curang = ang*curwep
				self.WeaponModels[k].Model = self.HL2WepData[v.Class] or weapons.Get(v.Class).WorldModel
				self.WeaponModels[k].Entity = ClientsideModel(self.WeaponModels[k].Model, RENDERGROUP_BOTH)
				startvec:Rotate( Angle( 0,curang,0) )
				self.WeaponModels[k].Pos = startvec
				self.WeaponModels[k].Ang = Angle(-90,curang,0)
				self.WeaponModels[k].Entity:SetPos(self:LocalToWorld( self.WeaponModels[k].Pos ))
				self.WeaponModels[k].Entity:SetAngles(self:LocalToWorldAngles( self.WeaponModels[k].Ang ))
				curwep = curwep + 1
			//	MsgN("numweps "..numweps)
			end
		end
	else
--[[		if self.WeaponModels then
			for k,v in pairs( self.WeaponModels ) do
				if self.WeaponModels[k].Entity then
					self.WeaponModels[k].Entity:Remove()
					self.WeaponModels[k].Entity = nil
				end
			end
			//self.WeaponModels = nil
		end--]]
	end
	
--[[	
	render.SetMaterial(Laser)
	if !self:GetEnabled() then
		render.DrawSprite( self:LocalToWorld(Vector(0,0,60)), 10, 10, Color(255,0,0) )
	elseif self:GetLastPickup() + 5 > CurTime() then
		render.DrawSprite( self:LocalToWorld(Vector(0,0,60)), 10, 10, Color(0,0,255) )
	else
		render.DrawSprite( self:LocalToWorld(Vector(0,0,60)), 10, 10, Color(0,255,0) )
	end
	--]]
	
	
--[[	//uncomment to draw the Collision Bounds
	pos = self.Entity:GetPos()
	render.SetMaterial( Laser )
local Min,Max = self.Entity:GetCollisionBounds()
local a, b, c = Min.x, Min.y, Min.z		//Min
local d, e, f = Max.x, Max.y, Max.z		//Max
	render.DrawQuad(self:LocalToWorld(Vector( a, b, c )), self:LocalToWorld(Vector( a, b, f )), self:LocalToWorld(Vector( d, b, f )), self:LocalToWorld(Vector( d, b, c )))		//Front
	render.DrawQuad(self:LocalToWorld(Vector( a, e, c )), self:LocalToWorld(Vector( a, e, f )), self:LocalToWorld(Vector( a, b, f )), self:LocalToWorld(Vector( a, b, c )))		//Left
	render.DrawQuad(self:LocalToWorld(Vector( a, b, f )), self:LocalToWorld(Vector( a, e, f )), self:LocalToWorld(Vector( d, e, f )), self:LocalToWorld(Vector( d, b, f )))		//Top
	render.DrawQuad(self:LocalToWorld(Vector( d, b, c )), self:LocalToWorld(Vector( d, b, f )), self:LocalToWorld(Vector( d, e, f )), self:LocalToWorld(Vector( d, e, c )))		//Right
	render.DrawQuad(self:LocalToWorld(Vector( d, e, c )), self:LocalToWorld(Vector( d, b, c )), self:LocalToWorld(Vector( a, b, c )), self:LocalToWorld(Vector( a, e, c )))		//Bottom
	render.DrawQuad(self:LocalToWorld(Vector( d, e, c )), self:LocalToWorld(Vector( d, e, f )), self:LocalToWorld(Vector( a, e, f )), self:LocalToWorld(Vector( a, e, c )))		//Back
--]]--	
end
