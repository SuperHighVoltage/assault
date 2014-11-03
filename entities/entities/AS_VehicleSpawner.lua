ENT.Type = "anim"

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
	self.SpawnDelay = self.SpawnDelay or 10
	self:SpawnVehicle()
end

function ENT:SpawnVehicle()
	self.Veh = SpawnVehicle(self:GetPos(), self.angle, self.vehiclename, self.team or 1)
	if !IsValid(self.Veh) then MsgN("Warning: Couldn't create vehicle "..self.vehiclename) end
	self.RespawnTime = nil
end

local vAngle = Vector( 0, 0, 1 )
function ENT:Think()
	if !self.RespawnTime then
		//self:FireOutput("OnPickUp")	//will eventually trigger map outputs
//		MsgN("RespawnTime is nil "..CurTime())
	end
	
	if !IsValid(self.Veh) or !IsEntity(self.Veh) then
		if !self.RespawnTime then
			self.RespawnTime = CurTime()+self.SpawnDelay
		elseif self.RespawnTime and self.RespawnTime < CurTime() then		//If the entity doesn't exist
			self:SpawnVehicle()
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
	
	if ( key == "vehiclename" ) then
		self.vehiclename = value
	end
	
	if ( key == "spawn_delay" ) then
		self.SpawnDelay = tonumber(value)
	end
	
	if ( key == "team" ) then
		self.team = tonumber(value)
	end
end

function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "ForceSpawn" ) then
		if !IsValid(self.Veh) or !IsEntity(self.Veh) then
			self:SpawnVehicle()
		end
	end	
	if ( inputName == "Enable" ) then
		self:Enable()
	end	
	if ( inputName == "Disable" ) then
		self:Disable()
	end	
	if ( inputName == "ChangeDelay" ) then
		self.RespawnTime = self.RespawnTime-self.SpawnDelay	//undo the delay time
		self.SpawnDelay = data								//set the new delay
		self.RespawnTime = CurTime()+self.SpawnDelay		//apply the new delay
	end	
end