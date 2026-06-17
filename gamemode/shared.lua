GM.Name = "Subasta"

function GM:Initialize()
  self.BaseClass.Initialize(self)
end

function setup_teams()
  team.SetUp(0, "Espectador", Color(128, 128, 128))
  team.SetUp(1, "Equipo 1", Color(255, 0, 0))
  team.SetUp(2, "Equipo 2", Color(0, 0, 255))
end
setup_teams()

hook.Add( "CreateTeams", "CreateTeamsSubasta", function()
  setup_teams()
end)