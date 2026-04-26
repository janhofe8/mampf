# Google Photos Migration — RESOLVED 2026-04-26

**Status:** ✅ Done. All restaurants now use own photos in `restaurant-images/own/`. Storage root is empty. Public-release blocker removed.

## Final state

- 158 / 158 restaurants point to `restaurant-images/own/<slug>.jpg`
- 0 Google-sourced photos in Supabase Storage
- 0 orphan files in `own/` (storage and DB are 1:1 synchronized)
- Local mirror in `~/Food Bilder/` matches DB content (Stand 2026-04-26)
- `ImageCache` applies the Foodie-Preset (CIGammaAdjust + CIHighlightShadowAdjust + temperature/saturation tweaks) to anything served from `/own/` — see `Services/ImageCache.swift:77`

## How it was resolved

Took the recommended path (Option A — own photos for all). Migration was executed across this conversation in three batches:

1. **Initial 19** (filename-matched against `~/Food Bilder/`): Ai Bánh Mì, An An Streetfood, An Vegan House, Bistro Cà Phê Viet, Breakfastdream, Café Näscherei, Das Peace, Diggi Smalls, Falafel Haus, Falafelstern, Good One Café, Green Papaya, Il Siciliano, Jill, L'Osteria, MUTTERLAND, The Pasta Club, SVAAdish, The Window
2. **Singles**: Spaccaforno (Rathaus/Altstadt), Josefs, Takumi (corrected from mistakenly-Ottensen-data to Schanze)
3. **Final 25** after the user added remaining named photos to the folder: Bolle, Kardelen, Karo Fisch, Kebaba, Kimchi Guys, Kimo, kini, Kleine Haie GF, Kohldampf, Köz-Antep, Little Tiana, Luigi's, memán, Monsieur Alfons, Neustädter Grill Meier, New City Smash, Pancake Panda, Pizzanatics, Poke Bar, Puro, Qrito, Qrito Grindel, Ruff's Burger, Saray Köz, Vu Food

After each migration: orphan Google files deleted from Storage root. 136 historical orphan files (from earlier renames/migrations) cleaned up in one bulk delete.

## Conventions for new restaurants going forward

- Always upload directly to `restaurant-images/own/<slug>.jpg`. Never to the storage root.
- Slug convention: lowercase, dashes for spaces, transliterated diacritics (ä→ae, ö→oe, ü→ue, ß→ss).
- Keep a local copy in `~/Food Bilder/` as a backup mirror.
- If a restaurant has multiple branches and the DB row name carries no suffix (because it's the original/main location), the local file may carry a location suffix for clarity (e.g., `Dulfs Burger Karoviertel.HEIC` for DB row `Dulf's Burger`).

## Historical reference (kept for posterity)

Original problem statement: Google Places Photos API Terms of Service prohibit caching/storing images. MAMPF historically downloaded Google photos into Supabase Storage root, which was a ToS violation.

Considered but rejected:
- **Runtime fetch** — would blow Place Photo API budget (1.000/month) instantly.
- **Cuisine-icon placeholders for all** — visually weaker than real photos.
- **Community photos** — possible v2 feature; deferred.
