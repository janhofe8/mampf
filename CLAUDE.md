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
├── Views/                 List (3 Modi: Cards/Grid/List), Detail, Map, Filter, Settings, Profile, Login, EditProfile
├── Components/            Cards, Rating-Bars/Pills/Badges, SkeletonLoadingView, RatingHistogramFilter
├── Services/              SupabaseManager, AuthService, RestaurantRepository, UserRatingRepository, LocationManager, DeviceID, ImageCache, OpeningHoursParser
├── Config/                Secrets.swift (Supabase URL + Anon Key), Theme.swift
├── Data/                  PreviewSampleData.swift
└── PrivacyInfo.xcprivacy  App Store Privacy Manifest (Auth-Daten, Required Reason APIs)

web/                       ← Web App (Next.js) — Haupt-App + /privacy Route
├── app/                   layout.tsx, page.tsx, globals.css, privacy/page.tsx
├── components/            MapView, RestaurantList, RestaurantCard, RestaurantDetail, etc.
└── lib/                   supabase.ts, types.ts, utils.ts, device-id.ts

docs/                      PRIVACY_POLICY.md, GOOGLE_PHOTOS_MIGRATION.md
```

## Dev-Regeln

- **Änderungen nur für iOS** wenn nicht anders gesagt. Web nur wenn explizit gewünscht.
- Nach Code-Änderungen immer iOS Build testen
- Secrets liegen in `~/.zshenv` (SUPABASE_SECRET_KEY, GOOGLE_PLACES_API_KEY), nie im Code oder Chat
- Publishable Anon Key in Secrets.swift / lib/supabase.ts ist okay (read-only, RLS aktiv)
- **Google API Free Tier nie überschreiten** (Text Search: 5.000/Mo, Place Details: 5.000/Mo, Photo: 1.000/Mo). Vor jedem Call aktuellen Stand in `google-api-usage.md` prüfen. Wenn ein Call das Limit überschreiten würde → **IMMER** User fragen, nicht ausführen. Diese Regel gilt in jedem Modus (auch Bypass/autonom) und darf nie übersprungen werden.
- **Neue Restaurants:** Immer recherchieren (Cuisine, Preis). Namen folgen Google Places Schreibweise. Niemals Koordinaten/Metadaten ausdenken — exakte Google Places API Werte. Stadtteile aus PLZ ableiten.
- Projekt nutzt `PBXFileSystemSynchronizedRootGroup` — neue Dateien im FinestFinder/-Ordner werden automatisch erkannt
- **Quick Device Deploy:** Shell-Alias `mampf-device` in `~/.zshrc` baut + installiert + startet auf Jans iPhone (UDID `00008150-00095D410E93401C`). Funktioniert nur in interaktiven Shells — aus dem Claude-Session die 3 Commands direkt (xcodebuild → devicectl install → devicectl launch) ausführen.

## Design-System

- **Rating-Farben:** Purple (≥9), Lime (8-8.5), Amber (7-7.5), Grau (5-6.5), Rot (≤4.5)
- **Source-Farben:** Lila=MAMPF, Lime=Community, Grau=Google (immer in dieser Reihenfolge)
- **App-Farben:** Purple (.ffPrimary), Lime (.ffSecondary), Charcoal (.ffTertiary)
- **Appearance:** Light/Dark/System wählbar in Settings, gespeichert via `@AppStorage("appearanceMode")`
- **Emoji-Icons** statt Flaggen-Emojis (🍝 statt 🇮🇹) — Flaggen rendern in iOS Simulator als ?
- **Preiskategorien:** € (<15€), €€ (15-25€), €€€ (25-40€), €€€€ (40€+)

## UX-Patterns

- **Brand Typography:** SF Rounded für alle Brand-Headers — NavBar-Titles global via `applyBrandedNavBarAppearance()` in `MAMPFApp.init()`, inline via `.font(.system(.headline, design: .rounded))` für Section-Titles, Hero-Headings, Stats-Zahlen.
- **Hero-Animation:** `.matchedTransitionSource` + `.navigationTransition(.zoom)` für Liste→Detail
- **Haptic Feedback:** `.sensoryFeedback()` auf Favoriten-Toggle, View-Mode-Wechsel, Slider, Filter-Chips, Map-Controls. `UINotificationFeedbackGenerator` für Rating Submit/Delete.
- **Skeleton Loading:** Shimmer-Effekt beim App-Start (SkeletonCardView/SkeletonListRow statt ProgressView)
- **Suche:** Custom Suchbalken in Liste + Map. Card-Background = `Color(.secondarySystemBackground)` (NICHT `systemBackground` — sonst schwarz-auf-schwarz in Dark Mode). Debouncing: `searchText` instant → `activeSearchText` (250ms). `localizedCaseInsensitiveContains` für Unicode. List zeigt Dropdown nur bei Query; Map zeigt zusätzlich Küchen-Suggestions bei leerem+fokussiertem Feld.
- **List-Header Hide-on-Scroll:** `safeAreaInset(edge: .top)` + `frame(height: visible ? nil : 0) + clipped()`. NICHT conditional im Body-Tree — das zerstört TextField-Identity und die Suche "bricht sofort ab" beim Tippen.
- **Map-Focus-Dismiss nur bei echtem User-Drag:** `onMapCameraChange` feuert auch bei keyboard-induzierten Layout-Änderungen. Flag via `.simultaneousGesture(DragGesture(minimumDistance: 10))` setzen, im Callback prüfen.
- **Filter UX:**
  - **Filter-Sheet:** Custom Sheet (kein Form) mit Capsule-Chips im Grid. Header: nur X rechts (Settings lebt jetzt im Profil-Tab).
  - **Active-Filter-Bar (Liste):** Purple-tinted Capsule-Chips unter Suche. **Kein X-Icon** — Tap auf Chip entfernt Filter direkt. Bar liegt AUSSERHALB der ScrollView (sticky Header), sonst Gesture-Konflikt mit NavigationLinks.
  - **Map-Chip-Bar:** Open Now, Rating, Cuisine, Preis (keine Sort/Stadtteil — Pan erfüllt's). **Rating-Chip-Toggle:** aktiv → Tap resettet sofort (nicht Histogram öffnen); inaktiv → Tap öffnet Histogram.
- **Image Caching:** Eigener `ImageCache` (NSCache memory + URLCache disk) statt `AsyncImage`. Bilder laden aus Cache instant, Netzwerk-Bilder mit Fade-In.
- **Opening Hours:** `OpeningHoursParser` parst Google Places Format (`"Monday: 4:00 – 10:00 PM"`) und einfaches Format (`"Mon-Sun 12:00-22:30"`). Grüner/roter Dot auf Cards/List-Rows, "Open"/"Closed" Label im Detail. `showOpenOnly` Filter.
- **Share:** `ShareLink` im Detail-Toolbar mit Name, MAMPF-Rating, Cuisine/Stadtteil/Preis, Google Maps URL.
- **Mini-Map:** Eingebettete Map (150pt) mit Marker im Detail Info-Card, nicht interaktiv.
- **Keyboard:** `.scrollDismissesKeyboard(.interactively)` auf Listen-ScrollView
- **Distanz:** Entfernung auf Cards und Listenzeilen wenn Location aktiv
- **Community-Rating CTA:** "Be the first to rate!" im Detail wenn noch kein Rating vorhanden

## Auth & Account (Non-Obvious)

- **Login-Flow:** 3 Steps (Email → Password → Name). Step 1 ruft `check_email_exists` RPC, routet zu Welcome-back-Sign-in oder Create-Account-Signup. Name nur bei Signup, als `user_metadata.display_name`.
- **iCloud Keychain Save braucht Hidden Username-Field** auf Step 2: iOS pairt Email+Password nur wenn beide im View-Tree sind beim Submit. Deshalb hat Step 2 einen `TextField("", text: .constant(email)).textContentType(.username).frame(0,0).opacity(0).disabled(true)`. Ohne das kommt kein "Save Password"-Prompt.
- **Rating-Migration beim ersten Login:** Device-ID-Rows werden User zugeordnet. Konflikte (User hatte schon Rating für gleichen Spot) → **neuerer `updated_at` gewinnt**, Verlierer-Row wird gelöscht. Code: `UserRatingRepository.migrateDeviceRatingsToUser`, getriggert von `RestaurantStore.setCurrentUser`.
- **Favorites = Visited + WantToTry:** Profile-Tab splittet Favorites per Rating-Presence: mit Rating = „Your Ratings" (besucht), ohne = „Want to Try" (Wishlist). Favorites sind aktuell noch **lokal** (UserDefaults) — Server-Sync auf `user_favorites` ist Backlog.
- **Account Deletion** folgt App Store Guideline 5.1.1(v) via `delete_own_account` RPC. UI-Pattern: kleiner zentrierter roter Text-Link unten in Settings, NICHT prominenter destructive-Button.
- **Cancellation-Errors** (`CancellationError`, `URLError.cancelled`) werden in `RestaurantStore` silent gefiltert via `Error.isCancellation` — sonst Toast beim Pull-to-Refresh.

## UI-Struktur

- **Tabs:** Map ("Karte"), Food Spots, Profil — Standard iOS TabView
- **Food Spots-Tab:** Title "Hamburg ˅" (City-Selector Menu, inline title mode). Custom Suchbalken darunter (sticky, mit Restaurant-Suggestions beim Tippen — Tap auf Restaurant pusht auf Detail). Active-Filter-Bar darunter (nur wenn Filter aktiv). Dann Content: 3 View-Modi (Cards → Grid → Liste), Grid-Cards zeigen Cuisine-Emoji + Stadtteil + Preis. Trailing-Toolbar: Heart, ViewMode, Sort, Filter. **Header versteckt sich beim Scrollen nach unten**, kommt beim Scroll-up zurück.
- **Map:** Custom Suchbalken oben (identisch zur Liste, aber mit Küchen-Suggestions bei leerem+fokussiertem Feld), Quick-Filter-Chips darunter (Open Now, Rating, Cuisine, Preis). Location-Button unten rechts. Rating-Histogram als Bottom-Overlay (tappable Bars). Tap auf Such-Ergebnis schließt Suche + zoomt Map + öffnet Detail-Sheet.
- **Profil-Tab:** Logged-out Hero, logged-in Account-Header (tap → Edit Profile) + Stats + „Your Ratings" + „Want to Try" + Sign-Out. Settings via Gear oben rechts. User-Rating-Bubble = Community-Lime (differenziert von MAMPF-Lila).
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

**user_ratings**: id, restaurant_id, device_id, user_id (nullable — signed-in Nutzer haben user_id, anon Device-ID-only), rating (1-10), created_at, updated_at — UNIQUE(restaurant_id, device_id), UNIQUE(restaurant_id, user_id). **RLS-Policy** `"authed users manage own ratings"`: `FOR ALL TO authenticated USING (user_id = auth.uid())`.

**restaurant_community_ratings** (View): restaurant_id, community_rating, community_rating_count

### RPC Functions

- **`check_email_exists(p_email text) → jsonb`** — returns `{exists: bool, display_name: string|null}`. SECURITY DEFINER, granted to `anon, authenticated`. Benutzt vom Login-Flow für „Welcome back, Jan". **Trade-off:** Exposes Email-Existence + Display-Name zu jedem mit Email-Rate-Capability (Enumeration). Für Restaurant-App akzeptabel.
- **`delete_own_account() → void`** — löscht `auth.users` row für `auth.uid()`. SECURITY DEFINER, granted to `authenticated`. Genutzt vom Account-Deletion-Flow.

### Restaurant hinzufügen

1. Name und Jans Rating bekommen
2. **Erst DB prüfen** ob schon existiert (`name=ilike.*name*`), bevor Places API aufgerufen wird
3. Cuisine Type, Price Range recherchieren
4. Google Places API: Adresse, Koordinaten, Rating, Öffnungszeiten, Place ID, Maps URL
5. Foto (Landscape, Essen bevorzugt) → Supabase Storage **Root** (nicht `own/`)
6. Stadtteil aus PLZ ableiten → INSERT

### Enums

**Cuisine Types:** burger, pizza, italian, korean, vietnamese, japanese, chinese, thai, turkish, greek, mexican, german, indian, portuguese, oriental, seafood, poke, brunch, steak, peruvian, persian, asian, chicken

**Neighborhoods:** altona, ottensen, stPauli, sternschanze, eimsbüttel, neustadt, altstadt, winterhude, eppendorf, barmbek, stGeorg, hafenCity, uhlenhorst, karolinenviertel, hoheluft, other

**Price Ranges:** budget (€), moderate (€€), upscale (€€€), fine (€€€€)

## Compliance / Release

- **Privacy Manifest** (`FinestFinder/PrivacyInfo.xcprivacy`): bei neuen Auth-Feldern oder Datentypen aktualisieren.
- **Privacy Policy:** Source `docs/PRIVACY_POLICY.md` + Web-Render in `web/app/privacy/page.tsx` → live auf `mampf-nine.vercel.app/privacy`, in-App verlinkt in Settings. Beide synchron halten.
- **Google Photos Caching** = offener Blocker für Public Release. Plan in `docs/GOOGLE_PHOTOS_MIGRATION.md`.

## Bekannte Themen

- Google-Fotos in Supabase Storage verstoßen gegen Google ToS (Caching). Vor Public Release durch eigene Fotos ersetzen.
- **Storage-Struktur:** `restaurant-images/` Root = Google Places Fotos, `own/` = eigene Fotos. **Niemals Google Places Fotos in `own/` speichern.**
- `user_ratings` hat vorbereitete `user_id`-Spalte für zukünftigen Email-Login (Supabase Auth aktiviert, aktuell Device-ID)
- Custom DragGesture-Slider auf Map funktioniert nicht — nativen SwiftUI Slider verwenden
- `.toolbarTitleMenu` zeigt keinen sichtbaren Chevron im Large-Title-Modus — für City-Selector stattdessen inline Title mit Custom Menu + explizitem chevron.down verwenden
- Swift 6 Concurrency: `SupabaseManager` muss `Sendable` + `nonisolated static let shared` sein, `DeviceID` Properties müssen `nonisolated` sein, damit `actor UserRatingRepository` darauf zugreifen kann
- **Tap-Through bei ScrollView + NavigationLinks:** Ein `Button` oder `onTapGesture` im gleichen ScrollView-Scope wie NavigationLinks kann Taps an das erste NavigationLink durchreichen (erstes Card öffnet sich statt Button-Action zu feuern). Fix: Ziel-View strukturell außerhalb der ScrollView platzieren (sticky Header via VStack über der ScrollView), nicht via Button-Style oder Gesture-Priority tricksen. Passiert typischerweise bei Header-Bars (Filter-Chips etc.).
- **SourceKit-Warnings beim Editieren** ("Cannot find type 'Restaurant' in scope" etc.) sind meist stale Cross-File-Warnings wegen `PBXFileSystemSynchronizedRootGroup` — Index ist kurz nicht aktuell. Ignorieren solange `xcodebuild` sauber baut.
