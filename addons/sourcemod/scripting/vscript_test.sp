#include <sourcemod>
#include <vscript>

#pragma semicolon 1
#pragma newdecls required

const HSCRIPT HSCRIPT_Invalid = view_as<HSCRIPT>(-1);

public void OnMapStart()
{
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "*")) != -1)
	{
		HSCRIPT scope = VScript_GetEntityScriptScope(entity);
		if(scope == HSCRIPT_Invalid)
			continue;
		
		PrintToServer("%d 0x%x", entity, scope);
		
		if(HScript_GetValue(scope, "ScriptHook_SCPDoorType"))
		{
			PrintToServer("Found");

			VScriptExecute execute = new VScriptExecute(HSCRIPT_RootTable.GetValue("ScriptHook_SCPDoorType"), scope);
			if(execute)
			{
				execute.Execute();

				PrintToServer("Execute %d", execute.ReturnValue);
				
				delete execute;
			}
		}
	}
}

bool HScript_GetValue(HSCRIPT pHScript, const char[] sKey)
{
	char buffer[256];
	Handle iterator = GetPluginIterator();
	
	bool result;

	while(MorePlugins(iterator))
	{
		Handle plugin = ReadPlugin(iterator);
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		if(StrContains(buffer, "vscript.smx") != -1)
		{
			Call_StartFunction(plugin, GetFunctionByName(plugin, "HScript_GetValue"));
			Call_PushCell(pHScript);
			Call_PushString(sKey);
			Call_PushCell(Address_Null);
			Call_Finish(result);
		}
	}

	delete iterator;
	return result;
}

bool FunctionExists(HSCRIPT scope, const char[] name)
{
	int i = -1;
	fieldtype_t type;
	char buffer[64];
	while((i=scope.GetKey(i, buffer, sizeof(buffer), type)) != -1)
	{
		PrintToServer("%d - %s - %d", i, buffer, type);
	}

	return false;
}