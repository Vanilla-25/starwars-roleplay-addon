--[[----------------------------------------------------------------------

	████████╗░█████╗░░█████╗░██████╗░
	╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗
	░░░██║░░░██║░░██║██║░░██║██║░░██║
	░░░██║░░░██║░░██║██║░░██║██║░░██║
	░░░██║░░░╚█████╔╝╚█████╔╝██████╔╝
	░░░╚═╝░░░░╚════╝░░╚════╝░╚═════╝░

	Support: discord.gg/YSzU6MY2Yb

	If you touch anything in this file and it breaks then ALL support is void.
	If you don't know what you're doing then don't touch it.

--]]----------------------------------------------------------------------

TOOL.Name = "Dropship Tool"
TOOL.Category = "T-DROPSHIPS"

if CLIENT then
    language.Add( "tool.t_dropship_tool.name", "Tood's Dropship Tool v2" )
    language.Add( "tool.t_dropship_tool.desc", "Customize the tool fields then aim at the ground and left click!" )
    language.Add( "tool.t_dropship_tool.0", "" )
end

local vars = {
    npc_class = "npc_combine_s",
    npc_model = "",
    npc_weapon = "weapon_ar2",
    npc_health = "100",
    npc_amount = "5",
    min_spawn = "2",
    max_spawn = "8",
    npc_relations = "1",
    npc_prof = "1",
    dship_model = "models/combine_dropship.mdl",
    dship_health = "5000",
    dship_speed = "800",
    dship_remove = "5",
    dship_hover = "0",
}

table.Merge( TOOL.ClientConVar, vars )

function TOOL:LeftClick( tr )
    if CLIENT then return true end
    local target_pos = tr.HitPos
    local ply = self:GetOwner()
    local dropship = ents.Create( "dropship_ent" )
    self:DoVars( dropship )
    dropship:SetPos( ply:GetPos() + Vector( 0, 0, 500 ) )
    dropship:Spawn()
    dropship:Activate()
    dropship:SetTargetPosition( target_pos )

    undo.Create( "Dropship" )
        undo.AddEntity( dropship )
        undo.SetPlayer( self:GetOwner() )
        undo.SetCustomUndoText( "Dropship Removed!" )
    undo.Finish()
end

function TOOL:DoVars( ent )
    for k, v in pairs( vars ) do 
        ent:SetKeyValue( k, self:GetClientInfo( k ) )
    end
end

local cvars = TOOL:BuildConVarList()

function TOOL.BuildCPanel( pnl )
    pnl:SetName( "Tood's Dropship Tool v2" )
    pnl:AddControl( "Header", {
        Text = "Dropship Tool",
        Description = "Fill in the fields, aim at the ground and left click!"
    } )
    pnl:AddControl( "ComboBox", {
        MenuButton = 1,
        Folder = "dropship_tool",
        Options = {
            ["#preset.default"] = cvars
        },
        CVars = table.GetKeys( cvars )
    } )
    pnl:TextEntry( "NPC Class", "t_dropship_tool_npc_class" )
    pnl:ControlHelp( "Paste the class of the NPC you want to use." )

    pnl:TextEntry( "NPC Model", "t_dropship_tool_npc_model" )
    pnl:ControlHelp( "Paste the model path here to override the NPCs model. Leave blank if the NPC should use it's default model." )

    pnl:TextEntry( "NPC Weapon", "t_dropship_tool_npc_weapon" )
    pnl:ControlHelp( "Paste the weapon class the spawned NPC's should use. Leave blank if the NPC should use it's default weapons. If no default is found then it will default to weapon_ar2." )

    pnl:NumSlider( "NPC Health", "t_dropship_tool_npc_health", 100, 2500, 0 )
    pnl:ControlHelp( "Set the health of the NPCs that spawn." )

    pnl:NumSlider( "NPC Amount", "t_dropship_tool_npc_amount", 1, 10, 0 )
    pnl:ControlHelp( "How many NPC's should spawn from the dropship." )

    pnl:NumSlider( "Min Spawn Time", "t_dropship_tool_min_spawn", 1, 5, 0 )
    pnl:ControlHelp( "How long before the NPC's start spawning in." )

    pnl:NumSlider( "Max Spawn Time", "t_dropship_tool_max_spawn", 6, 15, 0 )
    pnl:ControlHelp( "What is the max amount of seconds it can be for the last NPC to spawn in." )

    pnl:TextEntry( "Dropship Model", "t_dropship_tool_dship_model" )
    pnl:ControlHelp( "Paste the model that the dropship should use. Cannot be blank." )

    pnl:NumSlider( "Dropship Health", "t_dropship_tool_dship_health", 1000, 10000, 0 )
    pnl:ControlHelp( "Set the health of the dropship." )
    
    pnl:NumSlider( "Dropship Speed", "t_dropship_tool_dship_speed", 800, 2000, 0 )
    pnl:ControlHelp( "Set the speed of the dropship." )

    pnl:NumSlider( "Crash Removal Time", "t_dropship_tool_dship_remove", 5, 60, 0 )
    pnl:ControlHelp( "How long, in seconds, after the dropship crashes should it be removed." )

    pnl:CheckBox( "Hover and Drop", "t_dropship_tool_dship_hover" )
    pnl:ControlHelp( "If this is checked, the dropship will hover above the landing position and NPC's will drop from ropes." )

    local RelationBox = pnl:ComboBox( "NPC Relationship", "t_dropship_tool_npc_relations" )
	RelationBox:AddChoice( "Enemy", "1" )
	RelationBox:AddChoice( "Friendly", "3" )
	pnl:ControlHelp( "Choose how NPCs react to all current players." )
    
    local WepBox = pnl:ComboBox( "Weapon Difficulty", "t_dropship_tool_npc_prof" )
	WepBox:AddChoice( "Poor", WEAPON_PROFICIENCY_POOR )
	WepBox:AddChoice( "Average", WEAPON_PROFICIENCY_AVERAGE )
	WepBox:AddChoice( "Good", WEAPON_PROFICIENCY_GOOD )
	WepBox:AddChoice( "Great", WEAPON_PROFICIENCY_VERY_GOOD )
	WepBox:AddChoice( "Perfect", WEAPON_PROFICIENCY_PERFECT )
	pnl:ControlHelp( "How good should these NPCs be when they fire their weapons." )
end