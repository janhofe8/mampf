# Google Photos Migration Plan

**Problem:** Google Places Photos API Terms of Service prohibit caching/storing images. MAMPF currently downloads Google photos into Supabase Storage (`restaurant-images/` root), which is a ToS violation. Must be resolved before public release.

**Current state (as of 2026-04-24):**
- ~155 restaurants with `image_url` pointing to cached Google Places photos in Supabase Storage root
- Handful of own photos in `restaurant-images/own/`
- App reads `image_url` directly via `AsyncRestaurantImage`

## Options (ranked)

### A — Replace with own photos (recommended)
Jan shoots photos himself for the ~30 most-visited / top-rated spots, uses cuisine icons for the rest. Realistic, ToS-safe, gives the app a distinctive visual voice.

- Effort: 2–3 weekends of shooting + upload
- Quality: controlled, cohesive
- Scale: manual, but fine for 155 spots

### B — Fetch Google photos at runtime (no caching)
App calls Google Places Photo API on each load, server-side proxies if needed. Pros: no ToS issue, no manual work. **Cons: API budget blows instantly.** Place Photo free tier: 1.000/month. Every user browsing 10 restaurants = 10 calls. Doesn't scale past a handful of users.

### C — Cuisine-icon placeholders for all
Drop photos entirely, use the cuisine emoji + a colored gradient per category. Visual consistency, zero effort, zero photo problem. **Downside:** app looks less appealing without photos.

### D — User-submitted photos
Community photo uploads with moderation. Requires build + ongoing moderation. Future feature, not v1.

## Recommended plan (combining A + C)

**Phase 1 — Unblock App Store submission (1–2 hours)**
1. Delete all Google-sourced images from Supabase Storage root (`restaurant-images/` except `own/`)
2. Set `image_url = NULL` on all restaurants whose current photo came from Google
3. `AsyncRestaurantImage` already falls back to the cuisine-emoji placeholder when image_url is nil — verify and polish the fallback visual
4. Release

**Phase 2 — Own photos (ongoing)**
5. Jan shoots photos for top 30 spots (highest MAMPF rating first)
6. Upload to `restaurant-images/own/<slug>.jpg`, update `image_url`
7. Continue incrementally

**Phase 3 — Community photos (optional, v2)**
8. Add "Add photo" button on restaurant detail for signed-in users
9. Supabase Storage bucket `user-photos/<restaurant_id>/<user_id>.jpg`
10. Moderation queue (Jan approves before public display)

## Concrete cleanup SQL (Phase 1)

```sql
-- Identify Google-sourced photo URLs (in Supabase Storage root, not 'own/')
SELECT id, name, image_url
FROM restaurants
WHERE image_url LIKE '%/storage/v1/object/public/restaurant-images/%'
  AND image_url NOT LIKE '%/restaurant-images/own/%';

-- Null them out
UPDATE restaurants
SET image_url = NULL
WHERE image_url LIKE '%/storage/v1/object/public/restaurant-images/%'
  AND image_url NOT LIKE '%/restaurant-images/own/%';
```

Then in Supabase Dashboard → Storage → `restaurant-images` bucket → delete all files NOT inside the `own/` folder.

## Fallback UI checks needed

Before Phase 1 ship, verify cuisine-emoji fallback looks good in:
- `RestaurantCardView` (cards mode)
- `RestaurantCardView` (grid mode, `compact: true`)
- `listRow` (list mode)
- `RestaurantDetailView` hero image
- `searchSuggestionRow` (list + map dropdown)
- `ratingRow` / `wishlistRow` in ProfileTabView

`AsyncRestaurantImage` should already handle nil URL → render cuisine emoji on a muted background.

## Decision needed from Jan
- [ ] Confirm photo strategy: A+C combined as above, or different approach?
- [ ] Timeline for Phase 1 execution (ideally before Google API audit or public launch)
- [ ] Budget for Phase 2 photo sessions
