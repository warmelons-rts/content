
TOOL.Category		= "Construction"
TOOL.Name			= "#Fin"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar = {
	eff		= 50,
	pln		= 1,
	lift	= "lift_none",
	wind	= 0,
	cline	= 0,
}

cleanup.Register( "fin_2" )


// Add Default Language translation (saves adding it to the txt files)
if CLIENT then
	language.Add( "Tool_fin2_name", "Fin tool II" )
	language.Add( "Tool_fin2_desc", "Causes a prop to become a fin." )
	language.Add( "Tool_fin2_0", "Left click to turn a prop into a fin." )
	language.Add( "Tool_fin2_eff", "Efficiency of fin" )
	language.Add( "Undone_fin_2", "Undone fin" )
	language.Add( "Cleanup_fin_2", "Fin" )
	language.Add( "Cleaned_fin_2", "Cleaned up all Fins" )
	language.Add( "sboxlimit_fin_2", "You've reached the Fin limit!" )

end

if SERVER then
	CreateConVar('sbox_maxfin_2', 20)
end

function TOOL:LeftClick( trace )
	
	if (!trace.Hit or !trace.Entity:IsValid() or (trace.Entity:GetClass() != "prop_physics" and trace.Entity:GetClass() != "melon_baseprop")) then return false end
	if (SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )) then return false end
	if CLIENT then return true end
	
	local eff	= self:GetClientNumber( "eff" )
	local pln	= self:GetClientNumber( "pln" )
	local lft   = self:GetClientInfo( "lift" )
	local wnd	= self:GetClientNumber( "wind" )
	local cln	= self:GetClientNumber( "cline" )
	
	if trace.Entity.Fin2_Ent then
		local Data = {
			lift	= lft,
			pln		= pln,
			wind	= wnd,
			cline	= cln,
			efficiency = eff
		}
		table.Merge(trace.Entity.Fin2_Ent:GetTable(), Data)
		duplicator.StoreEntityModifier(trace.Entity, "fin2", Data)
		return true
	end
	
	if !self:GetSWEP():CheckLimit("fin_2") then return false end
	
	local Data = {
		--pos		= trace.Entity:WorldToLocal(trace.HitPos + trace.HitNormal * 4),
		ang		= trace.Entity:WorldToLocalAngles(trace.HitNormal:Angle()),
		lift	= lft,
		pln		= pln,
		wind	= wnd,
		cline	= cln,
		efficiency = eff
	}
	
	local fin = MakeFin2Ent(self:GetOwner(), trace.Entity, Data)
	
	undo.Create("fin_2")
		undo.AddEntity(fin)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()
	
	return true
end

--copy fin
function TOOL:RightClick( trace )
	if trace.Entity.Fin2_Ent then
		local fin = trace.Entity.Fin2_Ent
		local ply = self:GetOwner()
		ply:ConCommand("fin2_lift "..fin.lift)
		ply:ConCommand("fin2_pln "..fin.pln)
		ply:ConCommand("fin2_wind "..fin.wind)
		ply:ConCommand("fin2_cline "..fin.cline)
		ply:ConCommand("fin2_eff "..fin.efficiency)
		return true
	end
end

function TOOL:Reload( trace )
	if trace.Entity.Fin2_Ent then
		trace.Entity.Fin2_Ent:Remove() 
		return true
	end
end


if SERVER then

	function MakeFin2Ent( Player, Entity, Data )
		if !Data then return end
		if !Player:CheckLimit("fin_2") then return false end
		local cost = math.abs(math.floor((10000 * Data.wind + 50 * Data.efficiency) * server_settings.Int( "FinCostMul", 1 )))
	    if !InOutpostRange(Player, Entity:GetPos())  then return false end
		if !NRGCheck(Player, cost)  then return false end
		local fin = ents.Create( "fin_2" )
			--fin:SetPos(Entity:LocalToWorld(Data.pos))
			fin:SetPos(Entity:GetPos()) --its pos doesn't matter
			fin:SetAngles(Entity:LocalToWorldAngles(Data.ang))
			fin.ent			= Entity
			fin.efficiency	= Data.efficiency
			fin.lift		= Data.lift
			fin.pln			= Data.pln
			fin.wind		= Data.wind
			fin.cline		= Data.cline
		fin:Spawn()
		fin:Activate()

		fin:SetParent(Entity)
		Entity:DeleteOnRemove(fin)
		Entity.Fin2_Ent = fin

		duplicator.StoreEntityModifier(Entity, "fin2", Data)
		Player:AddCount("fin_2", fin)
		Player:AddCleanup("fin_2", fin)
		
		return fin
	end
	duplicator.RegisterEntityModifier("fin2", MakeFin2Ent)

end


function TOOL.BuildCPanel( CPanel )
	CPanel:NumSlider("#Tool_fin2_eff", "fin2_eff", 0, 100, 0)
	
 	CPanel:AddControl("ComboBox",
		{
			Label = "#Lift type",
			CVars = {},
			Options={
				["#No lift"]							= { fin2_lift = "lift_none" },
				["#Lift by plane normal"]				= { fin2_lift = "lift_normal" },
				["#Bernoulli effect by plane normal"]	= { fin2_lift = "lift_turncoat" },
			}
		}
	) 
	
	CPanel:CheckBox("#Use flat surface dynamics", "fin2_pln")
	CPanel:CheckBox("#Use Wind", "fin2_wind")
	CPanel:CheckBox("#Use Thermal Cline", "fin2_cline")
	
	CPanel:Help("To update fin angle:\nClear (reload) and remake")
end
