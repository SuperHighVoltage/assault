

/*---------------------------------------------------------
   Initializes the effect. The data is a table of data 
   which was passed from the server.
---------------------------------------------------------*/
function EFFECT:Init( data )

	self.Pos = data:GetOrigin()

//	self.endPos = data:GetStart()//self.p //+ (  (self.Pos-self.p):Angle():Up() * (data:GetMagnitude()*70)  )   //Vector(0,0,data:GetMagnitude()*20)
	self.color = data:GetStart() or Vector(255, 170, 0)
	self.angle = data:GetAngles()

	self.Emitter = ParticleEmitter(self.Pos)	

	self.DieTime = CurTime() + 0.3
	
//	MsgN(tostring(self.Pos+self.angle:Forward()*100))
	debugoverlay.Line( self.Pos, self.Pos+self.angle:Forward()*100, 0.22, Color(255,0,0), true )
	debugoverlay.Cross( self.Pos+self.angle:Forward()*100, 4, 0.22, Color(0,255,0), true )
end


/*---------------------------------------------------------
   THINK
   Returning false makes the entity die
---------------------------------------------------------*/
function EFFECT:Think( )

	local particle = self.Emitter:Add( "sprites/UT2K4/FlashFlare1", self.Pos + VectorRand()*10 )
	if particle then
		particle:SetVelocity(self.angle:Forward()*100)
		particle:SetDieTime( 1 )
		particle:SetStartAlpha( 255 )
		particle:SetStartSize( 3.5 )
		particle:SetEndAlpha( 1 )
		particle:SetEndSize( 2.5 )
		particle:SetColor( self.color.r, self.color.g, self.color.b )
		particle:VelocityDecay( false )
		particle:SetAngles( Angle(77,154,45) )
	end
	if self.DieTime > CurTime() then
		return true
	else
		return false
	end
end


/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()	
end



