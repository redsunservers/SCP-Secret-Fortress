# SCP: Secret Fortress

SCP: Secret Fortress is a gamemode for Team Fortress 2 inspired by the game [SCP: Secret Labortory](https://store.steampowered.com/app/700330/SCP_Secret_Laboratory/ "SCP: Secret: Laboratory on Steam"). It contains many elements that differ from normal TF2 such as the ability to pick up serveral different items and weapons, using no weapon slots and custom ammo types.

Alterative gamemodes can be created using the same plugin, some ones already made includes SCP-3008-1 survival game using a custom map and [SCP: Pandemic](https://store.steampowered.com/app/872670/SCP_Pandemic_Early_Access/ "SCP: Pandemic (Early Access) on Steam") using [Super Zombie Fortress](https://github.com/redsunservers/SuperZombieFortress "redsunservers/SuperZombieFortress: Custom Team Fortress 2 Gamemode, inspired from Left 4 Dead") (szf) maps.

## Compatibility Notice

This plugin uses different features which may cause some other plugins to misbehave:
- Uses it's own chat processor for proximity chat which causes other chat processors to not function (See scp_sf.inc about SCPSF_CanTalkTo)
- Team 0 (Unassigned) is used as a playable team (Check if a player is alive along with team check)
- Pop up menus during gameplay can be neagtive to weapon switching
- Player's class swap often for plugins that may check one time
- Without SendProxy can cause trippy viewmodels
- Custom model plugins may not function at all

## Required Dependencies:
[TF2Attributes](https://github.com/FlaminSarge/tf2attributes "FlaminSarge/tf2attributes: TF2Attributes SourceMod plugin")  
[TF2Items](https://github.com/asherkin/TF2Items "asherkin/TF2Items: Items with custom attributes.")  
[DHooks 2](https://github.com/peace-maker/DHooks2 "peace-maker/DHooks: Dynamic detouring support for the DHooks 2 SourceMod extension")  
[MemoryPatch](https://github.com/Kenzzer/MemoryPatch "Kenzzer/MemoryPatch: A simple .inc file to patch memory efficiently.") (Compiling)  
[More Colors](https://forums.alliedmods.net/showthread.php?t=185016 "[INC] More Colors (1.9.1) - AlliedModders") (Compiling)

## Recommend Dependencies:
[Basic SendProxy](https://github.com/SlidyBat/sendproxy "SlidyBat/sendproxy: Fork of Afronanny's SendProxy Manager extension.") **or**
[Per-Client SendProxy](https://github.com/TheByKotik/sendproxy "TheByKotik/sendproxy: Fork of Afronanny's SendProxy Manager extension.") **or**
[Linux-Only SendProxy](https://github.com/arthurdead/sendproxy "arthurdead/sendproxy")

## Supported Plugins:
[Source Vehicles](https://github.com/Mikusch/source-vehicles "Mikusch/source-vehicles: Driveable vehicles for TF2, CS:S and Black Mesa") (Whitelist/Blacklist classes that can drive)  
[SourceBans++](https://github.com/sbpp/sourcebans-pp "sbpp/sourcebans-pp: Admin, ban, and comms management system for the Source engine") (For integrated chat processor)  
[Goomba Stomp](https://github.com/Flyflo/SM-Goomba-Stomp "Flyflo/SM-Goomba-Stomp") (Restricted to SCP classes)

## Credits:
Mikusch - Many many related DHooks and SDKCalls  
[GitHub Profile](https://github.com/Mikusch "Mikusch") - [Fortress Royale](https://github.com/Mikusch/fortress-royale "Team Fortress 2 battle royale gamemode")

42 - Some other related DHooks  
[GitHub Profile](https://github.com/FortyTwoFortyTwo "FortyTwoFortyTwo (42)") - [Randomizer](https://github.com/FortyTwoFortyTwo/Randomizer "TF2 Gamemode where everyone plays as random class with random weapons")

sarysa - Eye-based system for SCPs like SCP-173  
[GitHub Profile](https://github.com/sarysa "sarysa") - [Forum Thread](https://forums.alliedmods.net/showthread.php?t=309245 "[FF2] Releasing all my private rages/bosses to the public. - AlliedModders")

Benoist - Spectator team swap  
[GitHub Profile](https://github.com/Kenzzer "Kenzzer (Benoist)") - [Forum Thread](https://forums.alliedmods.net/showthread.php?t=314271 "[ANY] How to properly switch team - AlliedModders")

nosoop - Per-player outlines  
[GitHub Profile](https://github.com/nosoop "nosoop") - [TF2 Custom Attribute Starter Pack](https://github.com/nosoop/SM-TFCustomAttributeStarterPack "nosoop/SM-TFCustomAttributeStarterPack: A collection of plugins to be used with the TF2 Custom Attribute framework.")

Deathreus - Increased movement speed cap  
[GitHub Profile](https://github.com/Deathreus "Deathreus") - [Forum Thread](https://forums.alliedmods.net/showthread.php?t=317520 "[TF2] Move Speed Unlocker - AlliedModders")

naydef - Medi-Gun DHook  
[GitHub Profile](https://github.com/naydef "naydef") - [Forum Thread](https://forums.alliedmods.net/showthread.php?t=311520 "[Solved] [TF2] Medigun healing enemy players help - AlliedModders")

Koishi - Revive markers  
[GitHub Profile](https://github.com/shadow93 "shadow93 (Koishi)") - [Forum Thread](https://forums.alliedmods.net/showthread.php?t=248320 "[FF2] [BOSS] 弾幕ドクター ～ Blitzkrieg (BETA 3.35)")

Artvin - Map/Model development  
[GitHub Profile](https://github.com/artvin01 "artvin01 (Artvin)")

Crust - SCP custom animations  
[Steam Profile](https://steamcommunity.com/profiles/76561198097667312 "Steam Community :: Crust")

DoctorKrazy - Chaos & SCP-049-2 rigs  
[AlliedModders Profile](https://forums.alliedmods.net/member.php?u=288676 "AlliedModders - View Profile: DoctorKrazy")

JuegosPablo - MTF rig  
[AlliedModders Profile](https://forums.alliedmods.net/member.php?u=268021 "AlliedModders - View Profile: JuegosPablo")

RavensBro - SCP-173 rig  
[AlliedModders Profile](https://forums.alliedmods.net/member.php?u=60510 "AlliedModders - View Profile: RavensBro")

Marxvee - Special thanks  
[GitHub Profile](https://github.com/spundarce "spundarce (Marxvee)")

SCP: Secret Labortory - Game assets  
[Steam Game](https://store.steampowered.com/app/700330/SCP_Secret_Laboratory/ "SCP: Secret: Laboratory on Steam")

And [GitHub Contributors](https://github.com/Batfoxkid/SCP-Secret-Fortress/graphs/contributors "Contributors to Batfoxkid/SCP-Secret-Fortress")
