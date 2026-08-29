# VOIDZ file map (Studio placement)

Rojo maps this automatically. Use this only for manual copies.

## ReplicatedStorage/VOIDZ/Shared — ModuleScript each

| Name | Purpose |
| --- | --- |
| Config | Brand, economy, datastore names, developer ids |
| Constants | Pages, slots, rate limits, error strings |
| Types | Shape documentation |
| Utility | Copy/merge/format/retry |
| Signal | Lightweight signal |
| Maid | Cleanup |
| Validate | Names, amounts, settings |
| Sanitize | Client-safe data |
| GameRegistry | All games (add titles here) |
| AvatarCatalog | Cosmetics |
| InventoryCatalog | Extra items + shop union |
| Achievements | Achievement defs |

## ReplicatedStorage/VOIDZ/Remotes

| Name | Type |
| --- | --- |
| RemoteNames | ModuleScript (string table). Live remotes are created at runtime. |

## ReplicatedStorage/VOIDZ/Client — ModuleScript each

App, Net, Theme, UIKit, AudioController, AnimationController, InputController, NavigationController, ViewportAvatar, Chrome, Components/GameCard, Pages/*

## ServerScriptService/VOIDZ

| Name | Type | Purpose |
| --- | --- | --- |
| ServerBootstrap | **Script** | Wires remotes and player lifecycle |
| Services/* | ModuleScript | Authoritative systems |
| WorldService | ModuleScript | Builds lobby |

## StarterPlayer/StarterPlayerScripts

| Name | Type |
| --- | --- |
| VOIDZClient | **LocalScript** |

## ServerStorage/VOIDZ

| Name | Type |
| --- | --- |
| Assets | ModuleScript placeholder |
