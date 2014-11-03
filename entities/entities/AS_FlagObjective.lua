AddCSLuaFile()
ENT.Base = "base_point"
ENT.Type = "point"

function ENT:Initialize()
//	self.priority = self.priority or 0
	self.Enabled = (self:GetPriority() == 0)
	self:SetEnabled(self.Enabled)
	self.DoPreview = false
	self.hasPlayerAlert = false
	self.hadPlayerAlert = false
	self.halfCompleted = false
	self.Completed = false
	self:SetCompleted( false )
	self.optional = self:HasSpawnFlags(1)
	self:SetOptional( self.optional )
	self.announceNext = self:HasSpawnFlags(2)
	self.doAlarm = self:HasSpawnFlags(4)
	self.tripPlyExt = self:HasSpawnFlags(8)
	
	self:MakeFlag()

	hook.Run("UT2K4AddObjective", self)
	hook.Add( "EntityTakeDamage", self, self.UpdateDamage )
end

function ENT:MakeFlag()
	if CLIENT then return end
	self.flag = ents.Create("as_flag")
	self.flag:SetPos(ents.FindByName(self.spawnpos)[1]:GetPos())
	self.flag:SetModel( self.flagmodel or "models/roller.mdl" )
	self.flag:SetPhysicsCarry(self:HasSpawnFlags(32))
	self.flag:SetResetTime(self:GetResetTime())
	self.flag:SetCompletePos(self:GetPos())
	self.flag:SetPickUpRadius(self:GetPickUpRadius())
	self.flag:SetObjective(self)
	self.flag:Spawn()
	
	self.Distance = self.flag:GetPos():Distance( self:GetPos() )
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",	0, "Enabled" );--
	self:NetworkVar( "Bool",	1, "Completed" );--
	self:NetworkVar( "Bool",	2, "Optional" );--
	self:NetworkVar( "Bool",	3, "Alert" );--
	
	self:NetworkVar( "Int",		0, "Priority" );--
	self:NetworkVar( "Int",		1, "Icon" )
	
	self:NetworkVar( "Float",	0, "PercentComplete" )
	self:NetworkVar( "Float",	1, "AlertRadius" )
	self:NetworkVar( "Float",	2, "PickUpRadius" )
	
	self:NetworkVar( "String",	0, "InfoAttack" );
	self:NetworkVar( "String",	1, "InfoDefend" );
	self:NetworkVar( "String",	2, "InfoName" );
	self:NetworkVar( "String",	3, "InfoCapture" );

	self:NetworkVar( "Int",	2, "Radius" );--
	self:NetworkVar( "Int",	3, "ResetTime" );
	-- defaults
	if SERVER then
		self:SetPercentComplete( 0 )
	end
end

function ENT:Think()
//	if self.Completed and self.Completed + 10 < CurTime() then self:Initialize() self:TriggerOutput("OnReset", self) end

	if self:GetCompleted() or !self:GetEnabled() then return end
	local diff = CurTime() - (self.lastthink or CurTime())
	debugoverlay.Sphere( self:GetPos(), self:GetAlertRadius(), 0.06, Color(200,0,0,4), false )
	//debugoverlay.Text(  self:GetPos(), self:GetPercentComplete(), .07 )

	self.hadPlayerAlert = self.hasPlayerAlert	-- new think, we set hadPlayerAlert to what we had last think
	self.hasPlayerAlert = false			-- reset hasPlayerAlert
	//self:SetAlert(false)
	local ent = ents.FindInSphere( self:GetPos(), self:GetAlertRadius() )
	for k,v in pairs( ent ) do		-- search for players
		if v:IsPlayer() and v:IsAttacking() and v:Alive() then
			self.hasPlayerAlert = true	-- there is a player in the radius so we set hasPlayerAlert to true, else it would just stay false
			//self:SetAlert(true)
		end
	end
	
	if self.DoPreview then self.hasPlayerAlert = true end
	
	if self.hadPlayerAlert != self.hasPlayerAlert then	-- things have changed since last think
		self:SetAlert( self.hasPlayerAlert )
		if self.hasPlayerAlert then
			self:OnPlayerEnterAlert()
			self.Alert = self.Alert or CreateSound( self, "assault/ASAlarm.wav" )
			self.Alert:Play()
			self.Alert:SetSoundLevel( 0 )
			self.Alert:ChangeVolume( 2, 1 )
		else
			self:OnPlayerExitAlert()
			self.Alert:Stop()
		end
	end	
	if SERVER then
		local Distance = self.flag:GetPos():Distance( self:GetPos() )
		self:SetPercentComplete( math.Clamp( (Distance/self.Distance)*100, 0, 100) )
	end
	local ent = ents.FindInSphere( self:GetPos(), 100 or self:GetRadius() )
	for k,v in pairs( ent ) do		-- search for players
		if SERVER then
			if v == self.flag:GetPlayer() or v == self.flag then
				self:OnComplete()
			end
		end
	end	
	
	
	self.lastthink = CurTime()
	self:NextThink(CurTime())
	return true
end



function ENT:OnComplete()
	self.flag:Completed()
	if self.tripPlyExt then
		self:OnPlayerExitAlert()
	end
	if self.Alert then self.Alert:Stop() end
	self:SetAlert( false )
	self.Completed = true
	self:SetCompleted( true )
	local CompletedSet = hook.Run("UT2K4CompleteObjective", self)
	if !SERVER then return end
	self:TriggerOutput("OnComplete", self)
	if CompletedSet then
		self:TriggerOutput("OnCompleteSet", self)
	end
end

function ENT:OnPlayerEnterAlert()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerEnterAlert", self)
end

function ENT:OnPlayerExitAlert()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerExitAlert", self)
end

function ENT:Enable()
	self.Enabled = true
	self:SetEnabled(true)
end

function ENT:Disable()
	self.Enabled = false
	self:SetEnabled(false)
end

function ENT:Reset()
	self:Initialize() 
	if !SERVER then return end
	self:TriggerOutput("OnReset", self)
end

function ENT:OnRemove()
end

function ENT:KeyValue( key, value )
	if ( string.Left( key, 2 ) == "On" ) then
		self:StoreOutput( key, value )
	end
	if ( key == "priority" ) then
		self.priority = tonumber(value)
		self:SetPriority(self.priority)
	end
	if ( key == "infoattack" ) then
		self.infoattack = value
		self:SetInfoAttack(self.infoattack)
	end	
	if ( key == "infodefend" ) then
		self.infodefend = value
		self:SetInfoDefend(self.infodefend)
	end	
	if ( key == "infodescription" ) then
		self.infodescription = value
	end	
	if ( key == "infocaptureinfo" ) then
		self.infocaptureinfo = value
		self:SetInfoCapture(self.infocaptureinfo)
	end	
	if ( key == "infoname" ) then
		self.infoname = value
		self:SetInfoName(self.infoname)
	end	
	if ( key == "alert_radius" ) then
		self.alert_radius = tonumber(value)
		self:SetAlertRadius(self.alert_radius)
	end	
	if ( key == "radius" ) then
		self.radius = tonumber(value)
		self:SetRadius(self.radius)
	end	
	if ( key == "alertsound" ) then
		self.alertsound = value
	end	
	if ( key == "flagmodel" ) then
		self.flagmodel = value
	end	
	if ( key == "resettime" ) then
		self.resettime = value
		self:SetResetTime(value)
	end	
	if ( key == "spawnpos" ) then
		self.spawnpos = value
	end	
	if ( key == "icon" ) then
		self:SetIcon(value)
	end
	if ( key == "pickupradius" ) then
		self.pickupradius = tonumber(value)
		self:SetPickUpRadius(self.pickupradius)
	end	
//	if ( key == "spawnflags" ) then
//		self.spawnflags = value
		//self:HasSpawnFlags(num)
//	end	
end

function ENT:AcceptInput( inputName, activator, called, data )
	if ( inputName == "Enable" ) then
		self:Enable()
	end	
	if ( inputName == "Disable" ) then
		self:Disable()
	end	
	if ( inputName == "Reset" ) then
		self:Reset()
	end	
	if ( inputName == "DoPreview" ) then
		self:DoPreview()
	end	
end

function ENT:UpdateTransmitState()

	--
	-- The default behaviour for point entities is to not be networked.
	-- If you're deriving an entity and want it to appear clientside, override this
	-- TRANSMIT_ALWAYS = always send, TRANSMIT_PVS = send if in PVS
	--
	return TRANSMIT_ALWAYS

end