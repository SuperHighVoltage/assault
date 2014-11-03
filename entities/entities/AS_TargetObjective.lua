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
	self.damageables = ents.FindByName(self.target_name or "")
	hook.Run("UT2K4AddObjective", self)
	hook.Add( "EntityTakeDamage", self, self.UpdateDamage )
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
	
	self:NetworkVar( "String",	0, "InfoAttack" );
	self:NetworkVar( "String",	1, "InfoDefend" );
	self:NetworkVar( "String",	2, "InfoName" );
	self:NetworkVar( "String",	3, "InfoCapture" );

	self:NetworkVar( "Int",	2, "Radius" );--
//	self:NetworkVar( "Int",	3, "Radius" );
	-- defaults
	if SERVER then
		self:SetPercentComplete( 0 )
	end
end

function ENT:UpdateDamage( target, dmginfo )
	if table.HasValue( self.damageables, target ) then
		if self.Completed or !self.Enabled then dmginfo:SetDamage( 0 ) return dmginfo end
		if !dmginfo:GetAttacker():IsPlayer() or (dmginfo:GetAttacker():IsPlayer() and !dmginfo:GetAttacker():IsAttacking() or !dmginfo:GetAttacker():Alive() ) then dmginfo:SetDamage( 0 ) return dmginfo end
		self.wasDamaged = CurTime()
		self.health = math.Clamp( self.health - dmginfo:GetDamage(), 0, self.startHealth )
		self:SetPercentComplete( math.Clamp(((self.startHealth-self.health )/self.startHealth)*100, 0, 100) )
		dmginfo:SetDamage( 0 )
		if !self.halfCompleted and self.health <= self.startHealth/2 then
			self:OnHalfComplete()
		end
		if self.health <= 0 then
			self:OnComplete()
		end
		return dmginfo
	end
end

function ENT:Think()
//	if self.Completed and self.Completed + 10 < CurTime() then self:Initialize() self:TriggerOutput("OnReset", self) end

	if self:GetCompleted() or !self:GetEnabled() then return end
	local diff = CurTime() - (self.lastthink or CurTime())
	debugoverlay.Sphere( self:GetPos(), self:GetAlertRadius(), 0.06, Color(200,0,0,4), false )
	//debugoverlay.Text(  self:GetPos(), self:GetPercentComplete(), .07 )

	local fade = Pulse(255,0,10)--math.abs(math.sin(CurTime()*5))*255
	if self.wasDamaged then
		if !self.Alert or !self.Alert:IsPlaying() then
			self.Alert = self.Alert or CreateSound( self, "assault/ASAlarm.wav" )
			self.Alert:Play()
			self:SetAlert( true )
		end
		if self.wasDamaged + 5 > CurTime() then
			fade = Pulse(255,0,16)--math.abs(math.sin(CurTime()*8))*255
		else
			self.wasDamaged = false
			self.Alert:Stop()
			self:SetAlert( false )
		end
	end
	
	for k,v in pairs( self.damageables ) do
		if IsValid(v) then
			v:SetColor(Color(fade,fade,255))
		end
	end
	
	self.hadPlayerAlert = self.hasPlayerAlert	-- new think, we set hadPlayerAlert to what we had last think
	self.hasPlayerAlert = false			-- reset hasPlayerAlert
	local ent = ents.FindInSphere( self:GetPos(), self:GetAlertRadius() )
	for k,v in pairs( ent ) do		-- search for players
		if v:IsPlayer() and v:IsAttacking() and v:Alive() then
			self.hasPlayerAlert = true	-- there is a player in the radius so we set hasPlayerAlert to true, else it would just stay false
		end
	end
	if self.DoPreview then self.hasPlayerAlert = true self:OnComplete() end
	
	if self.hadPlayerAlert != self.hasPlayerAlert then	-- things have changed since last think
		//self:SetAlert( self.hasPlayerAlert )
		if self.hasPlayerAlert then
			self:OnPlayerEnterAlert()
			//self.Alert = self.Alert or CreateSound( self, "UT2K4/Misc/ASAlarm.wav" )
			//self.Alert:Play()
		else
			self:OnPlayerExitAlert()
			//self.Alert:Stop()
		end
	end	
	
	self.lastthink = CurTime()
	self:NextThink(CurTime())
	return true
end

function ENT:OnHalfComplete()
	self.halfCompleted = true
	if !SERVER then return end
	self:TriggerOutput("OnHalfComplete", self)
end

function ENT:OnComplete()
	if self.tripPlyExt then
		self:OnPlayerExitAlert()
	end
	for k,v in pairs( self.damageables  ) do
		v:Fire("Break",nil,0)
	end
	if self.Alert then self.Alert:Stop() end
	self:SetAlert( false )
	self.Completed = true
	self:SetCompleted( true )
	local CompletedSet = hook.Run("UT2K4CompleteObjective", self)
	self.DoPreview = false
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

function ENT:DoPreview()
	self.DoPreview = true
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
	end	
	if ( key == "alertsound" ) then
		self.alertsound = value
	end	
	if ( key == "health" ) then
		self.health = tonumber(value)
		self.startHealth = self.health
	end	
	if ( key == "target_name" ) then
		self.target_name = value
	end	
	if ( key == "icon" ) then
		self:SetIcon(value)
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