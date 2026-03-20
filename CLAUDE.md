# MAMPF — Kuratierte Foodspots

Restaurant-Rating-App für Hamburg (~92 Restaurants). MAMPF-Rating (Jans persönliche Bewertung 1-10) neben Google- und Community-Bewertungen.

## Plattformen

- **iOS App:** SwiftUI, iOS 26.2, Swift 6 (MainActor default isolation)
- **Web App:** Next.js + Tailwind + TypeScript, gehostet auf Vercel
- **Backend:** Supabase (PostgreSQL + Storage)

## Infos

- **Supabase Project ID:** nuriruulwjjpycdszdrn
- **GitHub:** github.com/janhofe8/mampf
- **Web URL:** https://mampf-nine.vercel.app
- **iOS Build:** `xcodebuild -project MAMPF.xcodeproj -scheme MAMPF -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Web Build:** `cd web && npm run build`
- **Deploy Web:** `cd /Users/janhoferichter/test/FinestFinder && vercel --prod --yes` (Root Directory in Vercel auf `web` gesetzt)
- **Interner Projektname** ist noch "FinestFinder" (Ordner), Display-Name ist "MAMPF"

## Architektur

```
FinestFinder/              ← iOS App
├── Models/                Restaurant.swift (Codable struct + Enums), Rating.swift
├── ViewModels/            RestaurantStore.swift (@Observable), FilterViewModel.swift
├── Views/                 List, Detail, Map, Favorites, Filter
├── Components/            Cards, Rating-Bars, Badges, Tags
├── Services/              SupabaseManager, RestaurantRepository, UserRatingRepository, LocationManager, DeviceID
├── Config/                Secrets.swift (Supabase URL + Anon Key), Theme.swift
└── Data/                  PreviewSampleData.swift

web/                       ← Web App (Next.js)
├── app/                   layout.tsx, page.tsx, globals.css
├── components/            MapView, RestaurantList, RestaurantCard, RestaurantDetail, etc.
└── lib/                   supabase.ts, types.ts, utils.ts, device-id.ts
```

## Dev-Regeln

- **Änderungen für beide Plattformen** wenn nicht anders gesagt (iOS + Web)
- Nach Code-Änderungen immer Build testen (iOS + Web)
- Secrets liegen in `~/.zshenv` (SUPABASE_SECRET_KEY, GOOGLE_PLACES_API_KEY), nie im Code oder Chat
- Google Places API nur nach Absprache aufrufen (Kosten!)
- **Neue Restaurants immer recherchieren** — Cuisine Type, Preis etc. nicht raten
- Stadtteile basieren auf PLZ der Google-Adresse, nicht manuell vergeben
- Publishable Anon Key in Secrets.swift / lib/supabase.ts ist okay (read-only, RLS aktiv)

## Design

- **Rating-Farben:** Purple (≥9 elite), Lime (8-8.5 sehr gut), Amber (7-7.5 solide), Grau (5-6.5), Rot (≤4.5)
- **App-Farben:** Purple (.ffPrimary), Lime (.ffSecondary), Charcoal (.ffTertiary)
- **Emoji-Icons** statt Flaggen-Emojis (🍝 statt 🇮🇹) — Flaggen rendern in iOS Simulator als ?
- **Light Mode** auf beiden Plattformen
- **Preiskategorien:** € (<15€), €€ (15-25€), €€€ (25-40€), €€€€ (40€+)

## Content — Supabase-Datenbank

### Zugang

```bash
source ~/.zshenv
# Lesen
curl -s "https://nuriruulwjjpycdszdrn.supabase.co/rest/v1/restaurants?select=name,personal_rating&order=personal_rating.desc" \
  -H "apikey: $SUPABASE_SECRET_KEY" -H "Authorization: Bearer $SUPABASE_SECRET_KEY"

# Updaten
curl -s -X PATCH "https://nuriruulwjjpycdszdrn.supabase.co/rest/v1/restaurants?name=eq.Lokmam" \
  -H "apikey: $SUPABASE_SECRET_KEY" -H "Authorization: Bearer $SUPABASE_SECRET_KEY" \
  -H "Content-Type: application/json" -d '{"personal_rating": 9.0}'
```

Schema-Änderungen (ALTER TABLE) müssen im Supabase SQL Editor ausgeführt werden.

### Tabellen

**restaurants** (92 Einträge): id, name, cuisine_type, neighborhood, price_range, address, latitude, longitude, opening_hours, is_closed, notes, image_url, personal_rating, google_rating, google_review_count, google_place_id, google_maps_url, created_at, updated_at

**user_ratings**: id, restaurant_id, device_id, rating (1-10), created_at, updated_at — UNIQUE(restaurant_id, device_id)

**restaurant_community_ratings** (View): restaurant_id, community_rating, community_rating_count

### Restaurant hinzufügen

1. Name und Jans Rating bekommen
2. **Immer recherchieren:** Cuisine Type, Price Range über Google/Web
3. Google Places API: Adresse, Koordinaten, Rating, Öffnungszeiten, Place ID, Maps URL
4. Foto aus Google Places holen (Landscape, Essen bevorzugt) → Supabase Storage
5. Stadtteil aus PLZ der Adresse ableiten
6. INSERT in restaurants-Tabelle

### Cuisine Types

burger, pizza, italian, korean, vietnamese, japanese, chinese, thai, turkish, greek, mexican, german, middleEastern, portuguese, oriental, seafood, poke, brunch, steak

### Neighborhoods (basierend auf PLZ)

altona, ottensen, stPauli, sternschanze, eimsbüttel, neustadt, altstadt, winterhude, eppendorf, barmbek, stGeorg

### Price Ranges

budget (€ <15€), moderate (€€ 15-25€), upscale (€€€ 25-40€), fine (€€€€ 40€+)

## Bekannte Themen

- Google-Fotos in Supabase Storage verstoßen gegen Google ToS (Caching). Okay für privaten Gebrauch, vor Public Release durch eigene Fotos ersetzen.
