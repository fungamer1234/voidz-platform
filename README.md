# VOIDZ

A complete Roblox gaming platform: boot, in-game profile onboarding, home, discovery, **15 playable multiplayer games**, search, avatar, inventory, currency, friends, parties, quests, daily rewards, notifications, settings, DataStores, and a 3D lobby.

Platform name: **VOIDZ**  
Currency: **VoidCoins (VC)**  
Version: **1.1.0**

This is not a Roblox login clone. Players still join through Roblox. VOIDZ only stores an in-game profile (display name, avatar cosmetics, inventory, settings). It never asks for a Roblox password.

---

## Open in Studio (fastest)

Rojo 7.7+ is already on this machine at `/Users/GreysonAMcCann/bin/rojo`.

```bash
cd /Users/GreysonAMcCann/VOIDZ_Platform
/Users/GreysonAMcCann/bin/rojo build -o VOIDZ.rbxlx
```

Open `VOIDZ.rbxlx` in Roblox Studio.

Live sync (optional):

```bash
cd /Users/GreysonAMcCann/VOIDZ_Platform
/Users/GreysonAMcCann/bin/rojo serve
```

Then in Studio: Rojo plugin → Connect → `localhost:34872`.

---

## Studio settings you must turn on

1. **Game Settings → Security**
   - Enable Studio Access to API Services (DataStores)
   - Allow HTTP requests: off unless you add a legitimate HttpService use later
   - Third Party Teleports: on when you start launching real places
2. **Game Settings → Places** — this place is the platform lobby.
3. Put your Roblox userId in `src/ReplicatedStorage/VOIDZ/Shared/Config.lua` → `DeveloperUserIds`.
   - In Studio play-solo, the local player is treated as a developer automatically.
   - Live servers only grant admin if the userId is in that list.

Without DataStore API access, VOIDZ still runs in Studio using **session memory**. A settings note tells you progress will not persist.

---

## First play (expected)

1. Boot screen (real load steps, not a fake timer).
2. First join → onboarding: Welcome → display name → avatar → starter 250 VC → Home.
3. Rejoin (with API on) → skip onboarding, data restored.
4. Home / Discover / Search / game page / Avatar / Inventory / Friends / Profile / Settings all navigate.
5. **Play** on any of the 15 titles starts a real in-place match in this server (loading → lobby → countdown → play → results → return). Party members in the same server join that match.
6. Set a real `PlaceId` later and set `InPlace = false` to teleport that title to its own place. The same `Games/Modes` module can be copied there.

Keyboard: `Esc` back, `/` focus search, `F1` hide UI and walk the lobby. Proximity prompts on pedestals open game pages.

---

## Add a game later (do not rewrite the platform)

Edit `src/ReplicatedStorage/VOIDZ/Shared/GameRegistry.lua` and append:

```lua
{
  Id = "my_game",
  Name = "My Game",
  Description = "...",
  Category = "Adventure", -- must be one of Config.Categories
  MaxPlayers = 20,
  PlaceId = 0, -- set when you split this title into its own place
  InPlace = true, -- Play runs MatchService in this place
  Creator = "VOIDZ Studios",
  Featured = false,
  SeedPopularity = 1000,
  Accent = { 0.49, 0.36, 1 },
  Accent2 = { 0.18, 0.9, 0.65 },
  Tagline = "Short line.",
  Release = "Coming Soon",
}
```

UI, search, lobby pedestals (first 8 titles), and teleport all read this list. Do not hardcode games in page scripts.

---

## Architecture

```
ReplicatedStorage.VOIDZ
  Shared/     Config, catalogs, GameRegistry, validation
  Remotes/    RemoteNames + live RemoteEvent/Function instances (server-created)
  Client/     UI kit, audio, pages, App

ServerScriptService.VOIDZ
  ServerBootstrap.server.lua
  Services/   Data, Profile, Currency, Inventory, Avatar, Game, Friends,
              Notifications, Achievements, Admin, World, Marketplace

StarterPlayer.StarterPlayerScripts.VOIDZClient
```

Security rules actually enforced:

- Currency, inventory, equip, likes, teleports, names, admin: **server only**
- Client cannot grant itself VoidCoins
- Display names validated (length, charset, reserved, uniqueness store)
- Remotes rate-limited
- Failed DataStore **reads** never save a blank default over real data

---

## Config knobs

`Shared/Config.lua`

| Key | Purpose |
| --- | --- |
| `DeveloperUserIds` | Server-checked admins |
| `MaintenanceMode` | Kick non-devs |
| `StarterCurrency` | Onboarding grant |
| `Sounds.Music` | Licensed `rbxassetid://` when you have one |
| `Products` | Developer products → VoidCoins (`MarketplaceService`) |

Admin commands (Studio or listed userIds only), via `AdminCommand` remote:

- `announce` `{ text }`
- `maintenance` `{ enabled }`
- `grantCoins` `{ userId, amount }`
- `grantItem` `{ userId, itemId }`
- `setFeatured` `{ ids }`
- `stats`

---

## Manual Studio placement (if you are not using Rojo)

Mirror the `src/` tree:

| File | Location | Type |
| --- | --- | --- |
| Everything under `src/ReplicatedStorage/VOIDZ` | `ReplicatedStorage/VOIDZ` | ModuleScripts (folders stay folders) |
| `ServerBootstrap.server.lua` | `ServerScriptService/VOIDZ` | **Script** |
| `Services/*.lua` | `ServerScriptService/VOIDZ/Services` | ModuleScripts |
| `VOIDZClient.client.lua` | `StarterPlayer/StarterPlayerScripts` | **LocalScript** named `VOIDZClient` |

Do not parent client App as a LocalScript. Only `VOIDZClient` is a LocalScript.

---

## Testing checklist

- First-time player onboarding + 250 VC + starter cosmetics
- Rejoin restores name, coins, avatar, settings, favorites
- DataStore disabled in Studio → session fallback, no crash
- Invalid display names rejected
- Shop purchase deducts VC; cannot buy without funds
- Equip rejects items you don't own (try firing `EquipItem` from the command bar as the client)
- Play with PlaceId 0 → Coming Soon
- Search games / categories / lobby players
- Friends request / accept / remove (two Studio players)
- Settings persist (UI scale, volumes, reduce motion)
- Mobile-sized viewport uses bottom nav
- Leave during play → BindToClose save
- Two players joining at once → isolated profiles

---

## The 15 games (all live, in-place)

| Id | Loop |
| --- | --- |
| `brain_snatch` | Carry wandering Brains, bank in your vault, steal carriers, lock |
| `chaos_obby` | Checkpoint race with a random modifier each round |
| `last_one_alive` | One life, rotating disasters, last standing |
| `street_racers` | 3-lap kart circuit, checkpoints, boost, drift |
| `base_rush` | Plot income, upgrades, lock, melee raid |
| `haunted_shift` | Terminals + locker hide + pathfinding stalker + exit |
| `pet_planet` | Coin pads, buy eggs, pets follow, multiplier |
| `tower_clash` | Two cores, spawn marching units, optional melee |
| `grab_and_go` | Carry loot to extract, tag to steal, dash |
| `disaster_city` | City blocks, rotating disasters, fleeing NPCs |
| `sword_arena` | Server-range melee, block, dodge, sparring bots |
| `hideout` | Random seeker, lockers, tag, timer favors hiders |
| `sky_is_falling` | Islands drop one by one, shove, last on a platform |
| `build_battle` | Theme, grid place/delete, vote (not yourself) |
| `lucky_world` | Server RNG rolls with cooldown — no Robux |

Shared host: `MatchService` (one match per server). Damage, rewards, rolls, and scores are server-side. HUD / loading / results / mobile action bar: `Client/GameRuntime/MatchClient`.

Keyboard during a match: click or R2 = primary action (attack/roll/boost). `Q` dash, `E` grab, `F` lock/block, `Shift` sprint, `R` roll.

Daily drop is on Home. Party invite is on Friends → In this lobby. Quests show on Profile.

---

## Assumptions

- LuaU in Roblox Studio (not vanilla Lua 5.1).
- Cosmetics are platform-owned parts in a ViewportFrame. Live characters only receive BodyColors so movement/accessories are not destroyed.
- Built-in `rbxasset://sounds/...` are used until you replace them with licensed ids.
- Game thumbnails are generated from accent colors so you don't need uploaded images on day one.
- Player search is **this server + Roblox friends**, not a global directory (DataStores cannot be scanned by name).
