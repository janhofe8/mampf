# MAMPF — Kuratierte Foodspots

Restaurant-Rating-App für Hamburg (~93 Restaurants). MAMPF-Rating (Jans persönliche Bewertung 1-10) neben Google- und Community-Bewertungen.

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
├── Views/                 List (3 Modi: Cards/Grid/List), Detail, Map, Filter
├── Components/            Cards, Rating-Bars, Badges, Tags, RatingHistogramFilter
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
- Google Places API nur nach Absprache aufrufen (Kosten!)
- **Google API Free Tier nie überschreiten** (Text Search: 5.000/Mo, Place Details: 5.000/Mo, Photo: 1.000/Mo). Vor jedem Call aktuellen Stand in `google-api-usage.md` prüfen. Wenn ein Call das Limit überschreiten würde → **IMMER** User fragen, nicht ausführen. Diese Regel gilt in jedem Modus (auch Bypass/autonom) und darf nie übersprungen werden.
- **Neue Restaurants immer recherchieren** — Cuisine Type, Preis etc. nicht raten
- **Restaurant-Namen immer der Google Places Schreibweise folgen** (displayName aus der API)
- **Niemals Koordinaten oder andere Metadaten ausdenken** — immer exakte Werte aus der Google Places API verwenden (Koordinaten, Adresse, Rating, Review Count etc.)
- Stadtteile basieren auf PLZ der Google-Adresse, nicht manuell vergeben
- Publishable Anon Key in Secrets.swift / lib/supabase.ts ist okay (read-only, RLS aktiv)

## Design

- **Rating-Farben:** Purple (≥9 elite), Lime (8-8.5 sehr gut), Amber (7-7.5 solide), Grau (5-6.5), Rot (≤4.5)
- **Source-Farben:** Lila=MAMPF, Lime=Community, Grau=Google (immer in dieser Reihenfolge)
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

**restaurants** (93 Einträge): id, name, cuisine_type, neighborhood, price_range, address, latitude, longitude, opening_hours, is_closed, notes, image_url, personal_rating, google_rating, google_review_count, google_place_id, google_maps_url, created_at, updated_at

**user_ratings**: id, restaurant_id, device_id, rating (1-10), created_at, updated_at — UNIQUE(restaurant_id, device_id)

**restaurant_community_ratings** (View): restaurant_id, community_rating, community_rating_count

### Restaurant hinzufügen

1. Name und Jans Rating bekommen
2. **Erst DB prüfen** ob Restaurant schon existiert (`name=ilike.*name*`), bevor Places API aufgerufen wird
3. **Immer recherchieren:** Cuisine Type, Price Range über Google/Web
4. Google Places API: Adresse, Koordinaten, Rating, Öffnungszeiten, Place ID, Maps URL
5. Foto aus Google Places holen (Landscape, Essen bevorzugt) → Supabase Storage
6. Stadtteil aus PLZ der Adresse ableiten
7. INSERT in restaurants-Tabelle

### Cuisine Types

burger, pizza, italian, korean, vietnamese, japanese, chinese, thai, turkish, greek, mexican, german, indian, portuguese, oriental, seafood, poke, brunch, steak

### Neighborhoods (basierend auf PLZ)

altona, ottensen, stPauli, sternschanze, eimsbüttel, neustadt, altstadt, winterhude, eppendorf, barmbek, stGeorg, hafenCity, other

### Price Ranges

budget (€ <15€), moderate (€€ 15-25€), upscale (€€€ 25-40€), fine (€€€€ 40€+)

## UI-Struktur

- **Tabs:** Map ("Karte"), Food Spots (kein separater Favorites-Tab mehr)
- **Food Spots-Tab:** 3 View-Modi (Cards → Grid 2-spaltig → Liste mit Thumbnail+Pills), Heart-Toggle für Favoriten-Filter in Toolbar
- **Favoriten:** In Food Spots-Tab integriert via Heart-Button, kein eigener Tab
- **Ratings immer in Reihenfolge:** MAMPF → Community → Google
- **Rating-Pills:** Farbige Capsule-Badges in Liste (wie Card-View), nicht nur Text
- **Community-Rating:** Immer anzeigen, "–" wenn nicht vorhanden (Listen- und Detailansicht)
- **Map:** Suche via Lupen-Button (Toggle), Rating-Histogramm-Filter via Stern-Button (Bottom-Overlay mit Slider + Balkendiagramm), Tap auf Karte schließt beides
- **Rating-Filter:** Mind. Rating Slider auf Map (Histogramm zeigt Verteilung ab niedrigstem Rating)
- **Sortierung:** Inkl. "Zufällig" (stabiler Seed, nur bei erneutem Auswählen neu gemischt)

## Localization

- **EN/DE** via `Localizable.strings` in `en.lproj/` und `de.lproj/`
- Alle UI-Strings über Localization-Keys (z.B. `"tab.restaurants"`, `"search.restaurants"`)
- Wording: "Food Spots" (EN) / "Foodspots" (DE) statt "Restaurants"
- Dynamischer Such-Placeholder mit Anzahl: `String(format: String(localized: "search.restaurants"), count)`
- Projekt nutzt `PBXFileSystemSynchronizedRootGroup` — neue Dateien im FinestFinder/-Ordner werden automatisch erkannt

## Feature-Matrix (iOS vs Web)

✅ = fertig, ❌ = fehlt, ⚠️ = anders gelöst

| Feature | iOS | Web | Hinweise |
|---------|-----|-----|----------|
| **2 Tabs (Map + Food Spots)** | ✅ | ✅ | Favorites via Heart-Toggle integriert |
| **3 View-Modi (Cards/Grid/Liste)** | ✅ | ✅ | Liste mit Thumbnail + Rating-Pills |
| **Rating-Pills (farbige Capsules)** | ✅ | ✅ | In Liste: MAMPF→Community→Google |
| **Such-Placeholder mit Anzahl** | ✅ | ✅ | "Search X food spots..." |
| **Random-Sortierung (stabiler Seed)** | ✅ | ✅ | |
| **Map: Suche (Lupen-Toggle)** | ✅ | ✅ | |
| **Map: Rating-Histogramm-Filter** | ✅ | ✅ | Slider + Balkendiagramm |
| **Map: Tap schließt Overlays** | ✅ | ✅ | |
| **Filter: Gleich breite Grid-Chips** | ✅ | ✅ | 3-Spalten Cuisine/Neighborhood |
| **Filter: Rating-Slider im Sheet** | ❌ entfernt | ❌ entfernt | Nur noch auf Map |
| **Detail: Mini-Map** | ❌ entfernt | ❌ entfernt | |
| **Detail: User-Rating + Delete** | ✅ | ✅ | |
| **Localization (EN/DE)** | ✅ | ❌ | Web ist nur Englisch (niedrige Prio) |
| **Rating-Reihenfolge** | ✅ | ✅ | MAMPF→Community→Google |
| **Closed-Badge auf Cards** | ✅ | ✅ | |
| **Wording "Food Spots"** | ✅ | ✅ | |

## Bekannte Themen

- Google-Fotos in Supabase Storage verstoßen gegen Google ToS (Caching). Okay für privaten Gebrauch, vor Public Release durch eigene Fotos ersetzen.
- Custom DragGesture-Slider auf Map funktioniert nicht (offset/position verschiebt Hit-Area nicht) — nativen SwiftUI Slider verwenden
