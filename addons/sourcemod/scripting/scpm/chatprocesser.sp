#pragma semicolon 1
#pragma newdecls required

static Action HandleChatMessage(int client, char[] name, char[] message, ArrayList recipients, bool userids)
{
	ForwardOld_OnMessage(client, name, 64, message, 512);

	if(recipients)
	{
		int length = recipients.Length;
		for(int i; i < length; i++)
		{
			int target = recipients.Get(i);
			if(userids)
				target = GetClientOfUserId(target);
			
			if(!Client(client).CanTalkTo(target))
				recipients.Erase(i);
		}
	}

	return Plugin_Changed;
}

public Action CCP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message)
{
	return HandleChatMessage(author, name, message, recipients, true);
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	return HandleChatMessage(author, name, message, recipients, true);
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message)
{
	return HandleChatMessage(author, name, message, view_as<ArrayList>(recipients), false);
}
