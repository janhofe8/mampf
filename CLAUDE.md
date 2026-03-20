# FinestFinder

Persönliche Restaurant-Rating-App für Hamburg (~95 Restaurants). Jan bewertet Restaurants auf einer Skala von 1-10, die App zeigt diese neben Google-Bewertungen.

## Tech-Stack

- **iOS App:** SwiftUI, iOS 26.2, Swift 6 (MainActor default isolation)
- **Backend:** Supabase (PostgreSQL + Storage)
- **Dependencies:** supabase-swift v2.x (SPM)
- **Supabase Project ID:** nuriruulwjjpycdszdrn
- **Build:** `xcodebuild -scheme FinestFinder -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

## Architektur

```
FinestFinder/
├── Models/         Restaurant.swift (Codable struct + Enums), Rating.swift
├── ViewModels/     RestaurantStore.swift (@Observable), FilterViewModel.swift
├── Views/          List, Detail, Map, Favorites, Filter
├── Components/     Cards, Rating-Bars, Badges, Tags
├── Services/       SupabaseManager.swift, RestaurantRepository.swift
├── Config/         Secrets.swift (Supabase URL + Anon Key), Theme.swift
└── Data/           PreviewSampleData.swift, SeedData.swift (Legacy)
```

- **Datenfluss:** App startet → RestaurantStore.load() → zeigt Cache sofort → fetcht frisch von Supabase → aktualisiert UI
- **Offline:** JSON-Cache als Fallback, kein TTL — immer fresh fetch
- **Favoriten:** Lokal in UserDefaults (Set<UUID>)
- **Kein SwiftData** — alles über Supabase REST API

## Dev-Regeln

- Nach Code-Änderungen immer Build testen
- Neue Dateien werden automatisch von Xcode erkannt (PBXFileSystemSynchronizedRootGroup)
- Secrets liegen in `~/.zshenv` (SUPABASE_SECRET_KEY, GOOGLE_PLACES_API_KEY), nie im Code oder Chat
- Google Places API nur nach Absprache aufrufen (Kosten!)
- Publishable Anon Key in Secrets.swift ist okay (read-only, RLS aktiv)
- Design: Purple (.ffPrimary), Neon-Green (.ffSecondary), Charcoal (.ffTertiary)

## Content — Supabase-Datenbank

### Zugang

Alle Datenänderungen über Supabase REST API mit Secret Key aus `~/.zshenv`:

```bash
source ~/.zshenv
# Lesen
curl -s "https://nuriruulwjjpycdszdrn.supabase.co/rest/v1/restaurants?select=name,personal_rating&order=personal_rating.desc" \
  -H "apikey: $SUPABASE_SECRET_KEY" \
  -H "Authorization: Bearer $SUPABASE_SECRET_KEY"

# Updaten
curl -s -X PATCH "https://nuriruulwjjpycdszdrn.supabase.co/rest/v1/restaurants?name=eq.Lokmam" \
  -H "apikey: $SUPABASE_SECRET_KEY" \
  -H "Authorization: Bearer $SUPABASE_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d '{"personal_rating": 9.0}'
```

Schema-Änderungen (ALTER TABLE) müssen im Supabase SQL Editor ausgeführt werden — die REST API kann das nicht.

### Felder

| Spalte | Typ | Quelle | Beschreibung |
|--------|-----|--------|-------------|
| id | UUID | Auto | Eindeutige ID |
| name | TEXT | Jan | Restaurantname |
| cuisine_type | TEXT | Jan/LLM | Küchenkategorie (siehe Enums) |
| neighborhood | TEXT | Jan | Hamburger Stadtteil |
| price_range | TEXT | Jan/LLM | €, €€, €€€, €€€€ |
| address | TEXT | Google | Straßenadresse |
| latitude | DOUBLE | Google | Breitengrad (Karte) |
| longitude | DOUBLE | Google | Längengrad (Karte) |
| opening_hours | TEXT | Google | Öffnungszeiten |
| is_closed | BOOLEAN | Jan | Dauerhaft geschlossen? |
| notes | TEXT | Jan | Persönliche Notizen (optional) |
| image_url | TEXT | Storage | Link zum Foto in Supabase Storage |
| personal_rating | DOUBLE | Jan | Jans Bewertung 1-10 |
| google_rating | DOUBLE | Google | Google-Durchschnitt 1-5 |
| google_review_count | INT | Google | Anzahl Google-Reviews |
| google_place_id | TEXT | Google | Googles ID für Re-Fetch |
| google_maps_url | TEXT | Google | Link zur Google Maps Seite |

### Typische Content-Aufgaben

**Restaurant hinzufügen:**
1. Name und Jans Rating bekommen
2. Google Places API: Adresse, Koordinaten, Rating, Öffnungszeiten, Place ID, Maps URL holen
3. Foto aus Google Places holen → Supabase Storage hochladen
4. INSERT in restaurants-Tabelle

**Rating ändern:**
```bash
PATCH /rest/v1/restaurants?name=eq.{Name} → {"personal_rating": 8.5}
```

**Restaurant löschen:**
```bash
DELETE /rest/v1/restaurants?name=eq.{Name}
```

**Foto tauschen:**
1. Neues Foto in Supabase Storage hochladen (Bucket: restaurant-images)
2. image_url updaten

### Cuisine Types (Swift-Enum ↔ DB-Wert)

burger, pizza, italian, korean, vietnamese, japanese, chinese, thai, turkish, greek, mexican, german, middleEastern, portuguese, oriental, seafood, poke, brunch, steak, other

### Neighborhoods

altona, ottensen, stPauli, sternschanze, eimsbüttel, neustadt, altstadt, winterhude, eppendorf, barmbek, stGeorg, hafenCity, other

### Price Ranges

budget (€), moderate (€€), upscale (€€€), fine (€€€€)

## Bekannte Themen

- Google-Fotos in Supabase Storage verstoßen gegen Google ToS (Caching). Okay für privaten Gebrauch, vor Public Release durch eigene Fotos ersetzen.
- Flaggen-Emojis (🇬🇷 etc.) werden in kleinen Font-Größen als ? angezeigt — iOS-Bug
