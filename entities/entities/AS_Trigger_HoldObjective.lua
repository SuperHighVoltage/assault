
ENT.Base = "base_brush"
ENT.Type = "anim"
 
function ENT:Initialize()
	self:SetTrigger( true )
//	self.priority = self.priority or 0
	self.Enabled = false //(self:GetPriority() == 0)
	self:SetEnabled(self.Enabled)
	self.DoPreview = false
	self.hasPlayer = false
	self.hasPlayerAlert = false
	self.hadPlayer = false
	self.hadPlayerAlert = false
	self.holdTime = self.holdTime or 0
	self.heldTime = 0
	self.halfCompleted = false
	self.Completed = false
	self:SetCompleted( false )
	self.optional = self:HasSpawnFlags(1)
	self:SetOptional( self.optional )
	self.announceNext = self:HasSpawnFlags(2)
	self.doAlarm = self:HasSpawnFlags(4)
	self.tripPlyExt = self:HasSpawnFlags(8)
	self.switches = ents.FindByName(self.switchname or "")
//	print(self.switchname or "")
//	PrintTable(self.switches )
	if self.switches and self.posename then
		self.poselow = self.poselow or 0
		self.posehigh = self.posehigh or 1
		for k,v in pairs( self.switches  ) do
		//	v.AutomaticFrameAdvance = true 
		//	v.OldThink = v.OldThink or v.Think
		//	v.Think = function()  self:NextThink(CurTime());  return true;  end
			v:SetPoseParameter(self.posename, self.poselow)
		end
	end
	--hook.Run("UT2K4AddObjective", self)
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",	0, "Enabled" )
	self:NetworkVar( "Bool",	1, "Completed" )
	self:NetworkVar( "Bool",	2, "Optional" )
	self:NetworkVar( "Bool",	3, "Alert" )
	
	self:NetworkVar( "Int",		0, "Priority" )
	self:NetworkVar( "Int",		1, "Icon" )
	
	self:NetworkVar( "Float",	0, "PercentComplete" )
	self:NetworkVar( "Float",	1, "AlertRadius" )
	
	self:NetworkVar( "String",	0, "InfoAttack" )
	self:NetworkVar( "String",	1, "InfoDefend" )
	self:NetworkVar( "String",	2, "InfoName" )
	self:NetworkVar( "String",	3, "InfoCapture" )

	self:NetworkVar( "Int",		2, "HoldTime" )
	-- defaults
	if SERVER then
		self:SetPercentComplete( 0 )
	end
end

--[[---------------------------------------------------------
   Name: StartTouch
-----------------------------------------------------------]]
function ENT:StartTouch( ent )
	if ent:IsPlayer() and ent:IsAttacking() then
		self:OnPlayerEnter()
	end
end

--[[---------------------------------------------------------
   Name: EndTouch
-----------------------------------------------------------]]
function ENT:EndTouch( ent )
	if ent:IsPlayer() and ent:IsAttacking() then
		self:OnPlayerExit()
	end
end

--[[---------------------------------------------------------
   Name: Touch
-----------------------------------------------------------]]
function ENT:Touch( ent )
local diff = CurTime() - (self.lastthink or CurTime())
	if ent:IsPlayer() and ent:IsAttacking() then
		self:SetPercentComplete( math.Clamp((self.heldTime/self:GetHoldTime())*100, 0, 100) )
		if self:GetHoldTime() != 0 and !self.halfCompleted and self.heldTime >= self:GetHoldTime()/2 then
			self.halfCompleted = true
			if SERVER then
				self:TriggerOutput("OnHalfComplete", self)
			end
		end
		if self.heldTime >= self:GetHoldTime() then
			self:OnComplete()
			self.Alert:Stop()
		else
			self.heldTime = self.heldTime + diff
		end
		if self.switches and self.posename then
			for k,v in pairs( self.switches  ) do
				v:SetPoseParameter(self.posename, Lerp( (self.heldTime/self:GetHoldTime()), self.poselow, self.posehigh ))
			end
		end
	end
	self.lastthink = CurTime()
end

function ENT:Think()
//	if self.Completed and self.Completed + 10 < CurTime() then self:Initialize() self:TriggerOutput("OnReset", self) end

	if self:GetCompleted() or !self:GetEnabled() then return end
	debugoverlay.Sphere( self:GetPos(), self:GetAlertRadius(), 0.06, Color(200,0,0,4), false )
//	debugoverlay.Text(  self:GetPos(), self:GetPercentComplete(), .07 )
	
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

	local fade = math.abs(math.sin(CurTime()*5))*255	
	if self.hasPlayerAlert then
		fade = math.abs(math.sin(CurTime()*8))*255
	end
	for k,v in pairs( self.switches ) do
		v:SetColor(Color(fade,fade,255))
	end

	self:NextThink(CurTime())
	return true
end

function ENT:OnPlayerEnter()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerEnter", self)
end

function ENT:OnPlayerExit()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerExit", self)
end
 
function ENT:OnPlayerEnterAlert()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerEnterAlert", self)
end

function ENT:OnPlayerExitAlert()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerExitAlert", self)
end

function ENT:OnComplete()
	if self.tripPlyExt then
		self:OnPlayerExitAlert()
		self:OnPlayerExit()
	end
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
	end	
	if ( key == "infodescription" ) then
		self.infodescription = value
	end	
	if ( key == "infocaptureinfo" ) then
		self.infocaptureinfo = value
	end	
	if ( key == "infoname" ) then
		self.infoname = value
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
	if ( key == "holdtime" ) then
		self.holdTime = tonumber(value)
		self:SetHoldTime(self.holdTime)
	end	
	if ( key == "switchname" ) then
		self.switchname = value
	end	
	if ( key == "posename" ) then
		self.posename = value
	end	
	if ( key == "poselow" ) then
		self.poselow = tonumber(value) 
	end	
	if ( key == "posehigh" ) then
		self.posehigh = tonumber(value)
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