//static const char Name[] = "1732";
//static const char Model[] = "models/scp/scp173.mdl";
static const int Health = 800;
static const float Speed = 520.0;

static const char Downloads[][] =
{
	"models/scp/scp173.dx80.vtx",
	"models/scp/scp173.dx90.vtx",
	"models/scp/scp173.mdl",
	"models/scp/scp173.sw.vtx",
	"models/scp/scp173.vvd",

	"materials/models/psycedelicum/scp/scp173/173_albedo.vtf",
	"materials/models/psycedelicum/scp/scp173/face_01.vmt",
	"materials/models/psycedelicum/scp/scp173/face_01.vtf",
	"materials/models/psycedelicum/scp/scp173/face_02.vmt",
	"materials/models/psycedelicum/scp/scp173/face_02.vtf",
	"materials/models/psycedelicum/scp/scp173/face_03.vmt",
	"materials/models/psycedelicum/scp/scp173/face_03.vtf",
	"materials/models/psycedelicum/scp/scp173/face_04.vmt",
	"materials/models/psycedelicum/scp/scp173/face_04.vtf",
	"materials/models/psycedelicum/scp/scp173/face_05.vmt",
	"materials/models/psycedelicum/scp/scp173/face_05.vtf",
	"materials/models/psycedelicum/scp/scp173/face_06.vmt",
	"materials/models/psycedelicum/scp/scp173/face_06.vtf",
	"materials/models/psycedelicum/scp/scp173/face_07.vmt",
	"materials/models/psycedelicum/scp/scp173/face_07.vtf",
	"materials/models/psycedelicum/scp/scp173/face_08.vmt",
	"materials/models/psycedelicum/scp/scp173/face_08.vtf",
	"materials/models/psycedelicum/scp/scp173/face_09.vmt",
	"materials/models/psycedelicum/scp/scp173/face_09.vtf",
	"materials/models/psycedelicum/scp/scp173/face_10.vmt",
	"materials/models/psycedelicum/scp/scp173/face_10.vtf",
	"materials/models/psycedelicum/scp/scp173/flat_nm.vtf",
	"materials/models/psycedelicum/scp/scp173/scp173.vmt",
	"materials/models/psycedelicum/scp/scp173/scp173neo_low_merged_pm3d_sphere3d4_metallicsmoothness.vtf"
};

void SCP1732_Enable()
{
	Gamemode = Gamemode_Nut;

	int table = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	for(int i; i<sizeof(Downloads); i++)
	{
		if(!FileExists(Downloads[i], true))
		{
			LogError("Missing file: '%s'", Downloads[i]);
			continue;
		}

		AddToStringTable(table, Downloads[i]);
	}
	LockStringTables(save);
}

void SCP1732_Create(int client)
{
	SCP173_Create(client);

	Client[client].OnMaxHealth = SCP1732_OnMaxHealth;
	Client[client].OnSpeed = SCP1732_OnSpeed;
}

public void SCP1732_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP1732_OnSpeed(int client, float &speed)
{
	switch(Client[client].Radio)
	{
		case 0:
			speed = Speed;

		case 2:
			speed = FAR_FUTURE;
	}
}