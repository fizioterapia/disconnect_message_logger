# Disconnect Message Logger
This plugin was created to save all disconnect messages that doesn't matches with built-in ignored default messages, like timeout or game errors.  
Mainly created to find malformed disconnect messages used by cheaters or people abusing various exploits.

## Dependencies
* SourceBans++ (https://sbpp.dev/) (optional)
* morecolors.inc (build only - https://forums.alliedmods.net/showthread.php?t=185016) **(required)**

## Cvars
* sm_disconnect_loginvalid [0/1] - toggles logging to file.
* sm_disconnect_ban [0/1] - bans confirmed disconnect messages.

**Built using spcomp from SourceMod 1.11.**
