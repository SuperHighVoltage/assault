
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	self:SetModel( "models/Eli_anims.mdl" )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:DrawShadow( false )
	
	if self.angle then
		self:SetAngles(self.angle)
	end
	self.SpawnDelay = self.SpawnDelay or 30
	self.SpawnClass = self.SpawnClass or "ut2k4_adrenaline"
	self:SpawnEnt()
end

function ENT:SpawnEnt()
	self.ent = ents.Create(self.SpawnClass)
	self.ent:SetPos(self:GetPos())
	self.ent:SetAngles(self.angle)
	self.ent:Spawn()
	self.ent:Activate()
	self.RespawnTime = nil
	local effectdata = EffectData()
	effectdata:SetOrigin( self:GetPos() )
	util.Effect( "ut2k4_itemrespawn", effectdata )
	//self:FireOutput("ItemSpawned")	//will eventually trigger map outputs
end

local vAngle = Vector( 0, 0, 1 )
function ENT:Think()
	if !self.RespawnTime then
		//self:FireOutput("OnPickUp")	//will eventually trigger map outputs
//		MsgN("RespawnTime is nil "..CurTime())
	end
	
	if !IsValid(self.ent) or !IsEntity(self.ent) then
		if !self.RespawnTime then
			self.RespawnTime = CurTime()+self.SpawnDelay
		elseif self.RespawnTime and self.RespawnTime < CurTime() then		//If the entity doesn't exist
			self:SpawnEnt()
		end
	else
//		MsgN("Why am I being called?")
	end

end
			
function ENT:KeyValue( key, value )
	if ( key == "angles" ) then
		local Sep = string.Explode(" ", value)
		local ang = (Angle(tonumber(Sep[1]), tonumber(Sep[2]), tonumber(Sep[3])))
		self.angle = ang
	end
	
	if ( key == "item_class" ) then
		self.SpawnClass = value
	end
	
	if ( key == "spawn_delay" ) then
		self.SpawnDelay = value
	end
	
	if ( key == "effect_col" ) then
//		print("effect_col: ".. value)
		local Sep = string.Explode(" ", value)
//		PrintTable(Sep)
		local col = (Color(Sep[1], Sep[2], Sep[3]))
//		print("col: "..tostring(col))
		self.effect_col = col
	end
end

function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "ForceSpawn" ) then
		if !IsValid(self.ent) or !IsEntity(self.ent) then
			self:SpawnEnt()
		end
	end	
	if ( inputName == "ChangeDelay" ) then
		self.RespawnTime = self.RespawnTime-self.SpawnDelay	//undo the delay time
		self.SpawnDelay = data								//set the new delay
		self.RespawnTime = CurTime()+self.SpawnDelay			//apply the new delay
	end	
end
