AddCSLuaFile()
ENT.Base = "base_point"
ENT.Type = "point"

function ENT:Initialize()
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
	self.objectiveprop = ents.FindByName(self.objectivepropname or "")
	self.Alert = self.Alert or CreateSound( self, "assault/ASAlarm.wav" )
	hook.Run("UT2K4AddObjective", self)
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

function ENT:Think()
//	MsgN("dfdf")
//	if self.Completed and self.Completed + 10 < CurTime() then self:Initialize() self:TriggerOutput("OnReset", self) end

	if CLIENT or self:GetCompleted() or !self:GetEnabled() then return end
	local diff = CurTime() - (self.lastthink or CurTime())

	local fade = Pulse(255,0,10)--math.abs(math.sin(CurTime()*5))*255	
	if self.hasPlayerAlert then
		fade = Pulse(255,0,16)--math.abs(math.sin(CurTime()*8))*255
	end
	for k,v in pairs( self.objectiveprop ) do
		v:SetColor(Color(fade,fade,255))
	end

	if self.DoPreview then self.hasPlayer = true end
	
	if self.hasPlayer then
		self:SetPercentComplete( math.Clamp( (self.heldTime/self:GetHoldTime())*100, 0, 100) )
		if self:GetHoldTime() > 0 and !self.halfCompleted and self.heldTime >= self:GetHoldTime()/2 then
			self.halfCompleted = true
			if SERVER then
				self:TriggerOutput("OnHalfComplete", self)
			end
		end
		if self.heldTime >= self:GetHoldTime() then
			self:OnComplete()
		else
			self.heldTime = self.heldTime + diff
		end
	end
	
	self.lastthink = CurTime()
	self:NextThink(CurTime())
	return true
end

function ENT:OnPlayerEnter()
	self.hasPlayer = true
	if !SERVER then return end
	self:TriggerOutput("OnPlayerEnter", self)
end

function ENT:OnPlayerExit()
	self.hasPlayer = false
	if !SERVER then return end
	self:TriggerOutput("OnPlayerExit", self)
end
 
function ENT:OnPlayerEnterAlert()
	self.hasPlayerAlert = true
	self:SetAlert(true)
	self.Alert:Play()
	self.Alert:SetSoundLevel( 0 )
	self.Alert:ChangeVolume( 2, 1 )
	if !SERVER then return end
	self:TriggerOutput("OnPlayerEnterAlert", self)
end

function ENT:OnPlayerExitAlert()
	self.hasPlayerAlert = false
	self:SetAlert(false)
	self.Alert:Stop()
	if !SERVER then return end
	self:TriggerOutput("OnPlayerExitAlert", self)
end

function ENT:OnComplete()
	if self.tripPlyExt then
		self:OnPlayerExitAlert()
		self:OnPlayerExit()
	end
	for k,v in pairs( self.objectiveprop ) do
		v:SetColor(Color(255,255,255))
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
	if ( key == "alertsound" ) then
		self.alertsound = value
	end	
	if ( key == "holdtime" ) then
		self.holdTime = tonumber(value)
		self:SetHoldTime(self.holdTime)
	end	
	if ( key == "objectiveprop" ) then
		self.objectivepropname = value
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
	
//	if self:GetCompleted() then return end
	
	if ( inputName == "SetCompletion" ) then
		if !self:GetCompleted() then
			self:SetPercentComplete(tonumber(data))
		end
	end	
	if ( inputName == "TriggerComplete" ) then
		if !self:GetCompleted() then
			self:OnComplete()
		end
	end	
	if ( inputName == "TriggerHalfComplete" ) then
		if !self:GetCompleted() then
			self:TriggerOutput("OnHalfComplete", self)
		end
	end	
	if ( inputName == "TriggerPlayerEnter" ) then
		if !self:GetCompleted() then
			self:OnPlayerEnter()
		end
	end	
	if ( inputName == "TriggerPlayerExit" ) then
		if !self:GetCompleted() then
			self:OnPlayerExit()
		end
	end	
	if ( inputName == "TriggerPlayerEnterAlert" ) then
		if !self:GetCompleted() then
			self:OnPlayerEnterAlert()
		end
	end	
	if ( inputName == "TriggerPlayerExitAlret" ) then
		if !self:GetCompleted() then
			self:OnPlayerExitAlert()
		end
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