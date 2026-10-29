# Healer Aggro

Warns you when a monster is attacking your group's healer. Works in WoW: Forever and MoP Classic.

It watches the group's healers (players set to the Healer role, or ones you mark) and warns you, with an optional sound, when a monster is attacking one.

Commands (`/hagro` or `/healeraggro`):

- `/hagro` — show the current settings
- `/hagro test` — show the warning so you can see what it looks like
- `/hagro mark` — mark or unmark your target as a healer (for players who didn't pick the Healer role)
- `/hagro sound` — turn the warning sound on or off
- `/hagro say` — also announce it in /say (dungeons and raids only)
- `/hagro anywhere` — warn anywhere in a group, not just dungeons and raids

## Install

**WowUp:** Get Addons → *Install from URL* → paste `https://github.com/addonsforever/HealerAggro`. WowUp will offer updates when a new release comes out.

**By hand:** download `HealerAggro-vX.Y.Z.zip` from [Releases](https://github.com/addonsforever/HealerAggro/releases/latest), unzip it, and put the `HealerAggro` folder in `World of Warcraft/_classic_beta_/Interface/AddOns/` (the Forever client folder) — or `_classic_/Interface/AddOns/` for MoP Classic. Then `/reload` or restart the game.

## License

MIT
