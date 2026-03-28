# MAMPF — Kuratierte Foodspots

Restaurant-Rating-App für Hamburg (~155 Restaurants). MAMPF-Rating (Jans persönliche Bewertung 1-10) neben Google- und Community-Bewertungen.

## Plattformen & Build

- **iOS:** SwiftUI, iOS 26.2, Swift 6 (MainActor default isolation)
  - Build: `xcodebuild -project MAMPF.xcodeproj -scheme MAMPF -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Web:** Next.js + Tailwind + TypeScript, Vercel
  - Build: `cd web && npm run build`
  - Deploy: `cd /Users/janhoferichter/test/FinestFinder && vercel --prod --yes` (Root Directory = `web`)
- **Backend:** Supabase (PostgreSQL + Storage), Project ID: `nuriruulwjjpycdszdrn`
- **GitHub:** github.com/janhofe8/mampf | **Web:** https://mampf-nine.vercel.app
- Interner Projektname ist noch "FinestFinder" (Ordner), Display-Name ist "MAMPF"

## Architektur

```
FinestFinder/              ← iOS App
├── Models/                Restaurant.swift (Codable struct + Enums), Rating.swift
├── ViewModels/            RestaurantStore.swift (@Observable), FilterViewModel.swift (debounced search)
├── Views/                 List (3 Modi: Cards/Grid/List), Detail, Map, Filter, Settings
├── Components/            Cards, Rating-Bars/Pills/Badges, SkeletonLoadingView, RatingHistogramFilter
├── Services/              SupabaseManager, RestaurantRepository, UserRatingRepository, LocationManager, DeviceID
├── Config/                Secrets.swift (Supabase URL + Anon Key), Theme.swift
└── Data/                  PreviewSampleData.swift

web/                       ← Web App (Next.js)
├── app/                   layout.tsx, page.tsx, globals.css
├── components/            MapView, RestaurantList, RestaurantCard, RestaurantDetail, etc.
└── lib/                   supabase.ts, types.ts, utils.ts, device-id.ts
```

## Dev-Regeln

- **Änderungen nur für iOS** wenn nicht anders gesagt. Web nur wenn explizit gewünscht.
- Nach Code-Änderungen immer iOS Build testen
- Secrets liegen in `~/.zshenv` (SUPABASE_SECRET_KEY, GOOGLE_PLACES_API_KEY), nie im Code oder Chat
- Publishable Anon Key in Secrets.swift / lib/supabase.ts ist okay (read-only, RLS aktiv)
- **Google API Free Tier nie überschreiten** (Text Search: 5.000/Mo, Place Details: 5.000/Mo, Photo: 1.000/Mo). Vor jedem Call aktuellen Stand in `google-api-usage.md` prüfen. Wenn ein Call das Limit überschreiten würde → **IMMER** User fragen, nicht ausführen. Diese Regel gilt in jedem Modus (auch Bypass/autonom) und darf nie übersprungen werden.
- **Neue Restaurants:** Immer recherchieren (Cuisine, Preis). Namen folgen Google Places Schreibweise. Niemals Koordinaten/Metadaten ausdenken — exakte Google Places API Werte. Stadtteile aus PLZ ableiten.
- Projekt nutzt `PBXFileSystemSynchronizedRootGroup` — neue Dateien im FinestFinder/-Ordner werden automatisch erkannt

## Design-System

- **Rating-Farben:** Purple (≥9), Lime (8-8.5), Amber (7-7.5), Grau (5-6.5), Rot (≤4.5)
- **Source-Farben:** Lila=MAMPF, Lime=Community, Grau=Google (immer in dieser Reihenfolge)
- **App-Farben:** Purple (.ffPrimary), Lime (.ffSecondary), Charcoal (.ffTertiary)
- **Appearance:** Light/Dark/System wählbar in Settings, gespeichert via `@AppStorage("appearanceMode")`
- **Emoji-Icons** statt Flaggen-Emojis (🍝 statt 🇮🇹) — Flaggen rendern in iOS Simulator als ?
- **Preiskategorien:** € (<15€), €€ (15-25€), €€€ (25-40€), €€€€ (40€+)

## UX-Patterns

- **Hero-Animation:** `.matchedTransitionSource` + `.navigationTransition(.zoom)` für Liste→Detail
- **Haptic Feedback:** `.sensoryFeedback()` auf Favoriten-Toggle, View-Mode-Wechsel, Slider, Filter-Chips, Map-Controls. `UINotificationFeedbackGenerator` für Rating Submit/Delete.
- **Skeleton Loading:** Shimmer-Effekt beim App-Start (SkeletonCardView/SkeletonListRow statt ProgressView)
- **Debounced Search:** `searchText` (sofort im UI) → `activeSearchText` (250ms Debounce für Filter). Map-Suggestions nutzen `searchText` direkt (instant). `localizedCaseInsensitiveContains` für Unicode-Korrektheit.
- **Filter UX:** Sheet mit Live-Count-Button ("Show X Food Spots"), Chips mit Checkmark-Animation. Aktive Filter als horizontale Capsule-Chips unter Suchleiste (tap to remove). Sort-Indikator als Pill wenn nicht Default.
- **Keyboard:** `.scrollDismissesKeyboard(.interactively)` auf Listen-ScrollView
- **Distanz:** Entfernung auf Cards und Listenzeilen wenn Location aktiv
- **Community-Rating CTA:** "Be the first to rate!" im Detail wenn noch kein Rating vorhanden

## UI-Struktur

- **Tabs:** Map ("Karte"), Food Spots — Standard iOS TabView
- **Food Spots-Tab:** 3 View-Modi (Cards → Grid → Liste), Heart-Toggle für Favoriten in Toolbar, View-Mode-Wechsel mit Crossfade-Transition
- **Map:** Suche via Lupen-Button, Rating-Histogramm-Filter via Stern-Button, Tap auf Karte schließt Overlays
- **Ratings immer:** MAMPF → Community → Google. Community "–" wenn nicht vorhanden.
- **Sortierung:** Inkl. "Zufällig" (stabiler Seed, nur bei erneutem Auswählen neu gemischt)
- **Localization:** EN/DE via `Localizable.strings`, "Food Spots" (EN) / "Foodspots" (DE)

## Supabase-Datenbank

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

**restaurants** (~155 Einträge): id, name, cuisine_type, neighborhood, price_range, address, latitude, longitude, opening_hours, is_closed, notes, image_url, personal_rating, google_rating, google_review_count, google_place_id, google_maps_url, created_at, updated_at

**user_ratings**: id, restaurant_id, device_id, user_id (nullable, für Auth-Login), rating (1-10), created_at, updated_at — UNIQUE(restaurant_id, device_id), UNIQUE(restaurant_id, user_id)

**restaurant_community_ratings** (View): restaurant_id, community_rating, community_rating_count

### Restaurant hinzufügen

1. Name und Jans Rating bekommen
2. **Erst DB prüfen** ob schon existiert (`name=ilike.*name*`), bevor Places API aufgerufen wird
3. Cuisine Type, Price Range recherchieren
4. Google Places API: Adresse, Koordinaten, Rating, Öffnungszeiten, Place ID, Maps URL
5. Foto (Landscape, Essen bevorzugt) → Supabase Storage **Root** (nicht `own/`)
6. Stadtteil aus PLZ ableiten → INSERT

### Enums

**Cuisine Types:** burger, pizza, italian, korean, vietnamese, japanese, chinese, thai, turkish, greek, mexican, german, indian, portuguese, oriental, seafood, poke, brunch, steak, peruvian, persian, asian

**Neighborhoods:** altona, ottensen, stPauli, sternschanze, eimsbüttel, neustadt, altstadt, winterhude, eppendorf, barmbek, stGeorg, hafenCity, uhlenhorst, karolinenviertel, hoheluft, other

**Price Ranges:** budget (€), moderate (€€), upscale (€€€), fine (€€€€)

## Bekannte Themen

- Google-Fotos in Supabase Storage verstoßen gegen Google ToS (Caching). Vor Public Release durch eigene Fotos ersetzen.
- **Storage-Struktur:** `restaurant-images/` Root = Google Places Fotos, `own/` = eigene Fotos. **Niemals Google Places Fotos in `own/` speichern.**
- `user_ratings` hat vorbereitete `user_id`-Spalte für zukünftigen Email-Login (Supabase Auth aktiviert, aktuell Device-ID)
- Custom DragGesture-Slider auf Map funktioniert nicht — nativen SwiftUI Slider verwenden
