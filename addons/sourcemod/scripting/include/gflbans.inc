#if defined _gflbans_included
#endinput
#endif
#define _gflbans_included

public SharedPlugin:__pl_gflbans =
{
	name = "gflbans-core", 
	file = "gflbans-core.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_sourcebans_SetNTVOptional()
{
	
}
#endif