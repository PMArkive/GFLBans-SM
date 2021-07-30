int TYPE_MUTE       = 1;
int TYPE_UNMUTE     = 2;
int TYPE_GAG        = 3;
int TYPE_UNGAG      = 4;
int TYPE_SILENCE    = 5;
int TYPE_UNSILENCE  = 6;

Handle g_hTopMenu = INVALID_HANDLE;

public void OnAdminMenuReady(Handle menu)
{
    if (menu == g_hTopMenu)
    {
        return;
    }

    g_hTopMenu = menu;

    TopMenuObject adminMenu = AddToTopMenu(g_hTopMenu, "gflbans", TopMenuObject_Category, AdminMenu_Handler, INVALID_TOPMENUOBJECT);
    if (adminMenu == INVALID_TOPMENUOBJECT)
    {
        return;
    }

    AddToTopMenu(g_hTopMenu, "gflbans_mute", TopMenuObject_Item, AdminMenu_Mute, adminMenu, "sm_mute", ADMFLAG_CHAT);
    AddToTopMenu(g_hTopMenu, "gflbans_gag", TopMenuObject_Item, AdminMenu_Gag, adminMenu, "sm_gag", ADMFLAG_CHAT);
    AddToTopMenu(g_hTopMenu, "gflbans_silence", TopMenuObject_Item, AdminMenu_Silence, adminMenu, "sm_silence", ADMFLAG_CHAT);
    AddToTopMenu(g_hTopMenu, "gflbans_unmute", TopMenuObject_Item, AdminMenu_Unmute, adminMenu, "sm_unmute", ADMFLAG_CHAT);
    AddToTopMenu(g_hTopMenu, "gflbans_ungag", TopMenuObject_Item, AdminMenu_Ungag, adminMenu, "sm_ungag", ADMFLAG_CHAT);
    AddToTopMenu(g_hTopMenu, "gflbans_unsilence", TopMenuObject_Item, AdminMenu_Unsilence, adminMenu, "sm_unsilence", ADMFLAG_CHAT);
}

public void AdminMenu_Handler(Handle menu, TopMenuAction action, TopMenuObject menuObj, int lang, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
            Format(buffer, maxlength, "GFLBans Commands");
        case TopMenuAction_DisplayTitle:
            Format(buffer, maxlength, "GFLBans Commands:");
    }
}

public void AdminMenu_Mute(Handle menu, TopMenuAction action, TopMenuObject menuObj, int client, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "Mute a Player");
        }

        case TopMenuAction_SelectOption:
        {
            AdminMenu_TargetHandler(client, TYPE_MUTE);
        }
    }
}

public void AdminMenu_Gag(Handle menu, TopMenuAction action, TopMenuObject menuObj, int client, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "Gag a Player");
        }

        case TopMenuAction_SelectOption:
        {
            AdminMenu_TargetHandler(client, TYPE_GAG);
        }
    }
}

public void AdminMenu_Silence(Handle menu, TopMenuAction action, TopMenuObject menuObj, int client, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "Silence a Player");
        }

        case TopMenuAction_SelectOption:
        {
            AdminMenu_TargetHandler(client, TYPE_SILENCE);
        }
    }
}

public void AdminMenu_Unmute(Handle menu, TopMenuAction action, TopMenuObject menuObj, int client, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "Unmute a Player");
        }

        case TopMenuAction_SelectOption:
        {
            AdminMenu_TargetHandler(client, TYPE_UNMUTE);
        }
    }
}

public void AdminMenu_Ungag(Handle menu, TopMenuAction action, TopMenuObject menuObj, int client, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "Ungag a Player");
        }

        case TopMenuAction_SelectOption:
        {
            AdminMenu_TargetHandler(client, TYPE_UNGAG);
        }
    }
}

public void AdminMenu_Unsilence(Handle menu, TopMenuAction action, TopMenuObject menuObj, int client, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "Unsilence a Player");
        }

        case TopMenuAction_SelectOption:
        {
            AdminMenu_TargetHandler(client, TYPE_UNSILENCE);
        }
    }
}

public void AdminMenu_TargetHandler(int client, int infractionType)
{
    // We need to display a list of players for the admin to choose from.
    // TBA
}