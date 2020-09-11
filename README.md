This mod adds chatcommands for locations to which players can teleport:
* Teleport to a location: `/go <bookmark_name>`
* List all locations: `/listgo`
* Add a new location (admin only): `/setgo <bookmark_name>`
* Remove a location (admin only): `/delgo <bookmark_name>`

By default, in Minetest there is only the `spawn` chatcommand which
specifies a location where any player can teleport to at any time
(correct me if I'm wrong).
However, on many servers there are more than just one interesting location.
For example, there may be multiple spawn positions because the spawn point
has been migrated over time.
In my experience, the `go` chatcommand is a convenient way for the player to
move to a well-known public location.
In comparison to other teleportation mods, such as travelnet and teleporter
stones, the player does not need to go to, for example, a travelnet centre to
visit another location.

The mod is based on [mauvebic's bookmarks mod
](https://forum.minetest.net/viewtopic.php?id=2321).
