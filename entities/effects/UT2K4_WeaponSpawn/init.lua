/*---------------------------------------------------------
   Initializes the effect. The data is a table of data 
   which was passed from the server.
---------------------------------------------------------*/
function EFFECT:Init( data )
	self:SetPos(data:GetOrigin() + Vector(0,0,32))
//	print("kajsgjdfjashd "..data:GetColor())
	local col = data:GetStart()
	if col then
		self.effect_col = Color(col.x, col.y, col.z)
	else
		self.effect_col = Color(255, 170, 0)
	end
//	print("color in effect:")
//	PrintTable(self.effect_col)
	
	local AMOUNTOFEFFECTS = 15
    self.RandVecs = {}
    for I=1,AMOUNTOFEFFECTS do
        table.insert(self.RandVecs, VectorRand())
    end
--[[	// Keep the start and end pos - we're going to interpolate between them
	local NumParticles = 0
	Pos = data:GetOrigin() + Vector(0,0,32)
	
	WorldSound( "weapons/slam/mine_mode.wav", Pos, 140 )

	local emitter = ParticleEmitter( Pos )
	
		for i= 0, 32 do
			local VRand = VectorRand()
			local particle = emitter:Add( "sprites/gmdm_pickups/light", Pos + VRand*16 )
			local bla = VRand * math.Rand( 10, 30 )
				particle:SetVelocity( bla )
				particle:SetDieTime( math.Rand( 3, 4 ) )
				particle:SetStartAlpha( 250 )
				particle:SetEndAlpha( 250 )
				particle:SetStartSize( 10 )
				particle:SetEndSize( 5 )
				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -5.5, 5.5 ) )
//				particle:SetColor( 255, 255, 255 )
				if i > 16 then
					particle:SetAirResistance(60)
					particle:SetColor( 0, 255, 0 )
				else
					particle:SetColor( 255, 255, 255 )
				end
				
		end
				
	emitter:Finish()
	]]--
end


/*---------------------------------------------------------
   THINK
   Returning false makes the entity die
---------------------------------------------------------*/
function EFFECT:Think( )
	return true
end

/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
EFFECT.BallMat = Material( "sprites/UT2K4/FlashFlare1" )
function EFFECT:Render()
    for _,vec in pairs(self.RandVecs) do
        local Rand = vec
        local bla = (math.sin( ( CurTime()/.8 ) +(Rand.x*10) )) *20
        local pos = self:GetPos() + (Rand * bla )
        local width = math.abs(bla)-10
        local color = self.effect_col
        if ( width > 0 ) then
            render.SetMaterial(self.BallMat)
            render.DrawSprite( pos, width, width, color )  
        end
    end
--[[
self.VRand = self.VRand or VectorRand()	
local bla = (math.sin( CurTime()+(self.VRand.x*20) )) *30
	local pos = self:GetPos() + (self.VRand * bla )
	local width = math.abs(bla)-10
	local color = Color(0, 0, 255)
	if ( width > 0 ) then
		render.SetMaterial(self.BallMat)
		render.DrawSprite( pos, width, width, color )	
	end	
self.VRand2 = self.VRand2 or VectorRand()	
local bla2 = (math.sin( CurTime()+(self.VRand2.x*20) )) *30
	local pos2 = self:GetPos() + (self.VRand2 * bla2 )
	local width2 = math.abs(bla2)-10
	if ( width2 > 0 ) then
		render.SetMaterial(self.BallMat)
		render.DrawSprite( pos2, width2, width2, color )	
	end	
self.VRand3 = self.VRand3 or VectorRand()	
local bla3 = (math.sin( CurTime()+(self.VRand3.x*20) )) *30
	local pos3 = self:GetPos() + (self.VRand3 * bla3 )
	local width3 = math.abs(bla3)-10
	if ( width3 > 0 ) then
		render.SetMaterial(self.BallMat)
		render.DrawSprite( pos3, width3, width3, color )	
	end	
self.VRand4 = self.VRand4 or VectorRand()	
local bla4 = (math.sin( CurTime()+(self.VRand4.x*20) )) *30
	local pos4 = self:GetPos() + (self.VRand4 * bla4 )
	local width4 = math.abs(bla4)-10
	if ( width4 > 0 ) then
		render.SetMaterial(self.BallMat)
		render.DrawSprite( pos4, width4, width4, color )	
	end	
--]]	
end

