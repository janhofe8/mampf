# MAMPF — Kuratierte Foodspots

Restaurant-Rating-App für Hamburg (~155 Restaurants). MAMPF-Rating (Jans persönliche Bewertung 1-10) neben Google- und Community-Bewertungen.

## Plattformen & Build

- **iOS:** SwiftUI, iOS 26.2, Swift 6 (MainActor default isolation)
  - Build: `xcodebuild -project MAMPF.xcodeproj -scheme MAMPF -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
  - **Simulator-Deploy** (wenn User „deploy" oder „simulator" sagt ohne „iphone"): verwende booteten Simulator via `xcrun simctl`. UDID vorher mit `xcrun simctl list devices booted` prüfen (kann sich ändern). Drei-Schritte: build → `simctl install` → `simctl launch janhoferichter.FinestFinder`.
  - **iPhone-Deploy** (Default für „deploy"): `mampf-device` Alias. UDID `00008150-00095D410E93401C`. Aus der Claude-Session die 3 Commands direkt (xcodebuild → `devicectl install` → `devicectl launch`).
- **Web:** Next.js + Tailwind + TypeScript, Vercel
  - Build: `cd web && npm run build`
  - Deploy: `cd /Users/janhoferichter/test/FinestFinder && vercel --prod --yes` (Root Directory = `web`)
- **Backend:** Supabase (PostgreSQL + Storage), Project ID: `nuriruulwjjpycdszdrn`
- **GitHub:** github.com/janhofe8/mampf | **Web:** https://mampf-nine.vercel.app
- Interner Projektname ist noch "FinestFinder" (Ordner), Display-Name ist "MAMPF"

## Architektur

```
FinestFinder/              ← iOS App
├── Models/                Restaurant.swift (Codable struct + Enums), Rating.swift (+ RatingTier enum)
├── ViewModels/            RestaurantStore.swift (@Observable), FilterViewModel.swift (debounced search)
├── Views/                 List (3 Modi: Cards/Grid/List), Detail, Map, Filter, Settings, Profile, Login, EditProfile
├── Components/            Cards, Rating-Bars/Pills/Badges, RatingSlider (custom), SkeletonLoadingView, RatingHistogramFilter, FilterBarChip (+FiltersEntryChip), RotatingPlaceholder
├── Services/              SupabaseManager, AuthService, RestaurantRepository, UserRatingRepository, LocationManager, DeviceID, ImageCache (mit Foodie-Preset für /own/), MapSnapshotCache, OpeningHoursParser
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
- **Navigation Bar:** `configureWithOpaqueBackground()` + `backgroundColor = .systemBackground` + `shadowColor = .clear`. Kein Translucent/Material — User zieht solide Flächen vor. Auf Profile-Tab `.navigationBarTitleDisplayMode(.inline)` (kein Large-Title-Collapse).
- **Hero-Animation:** `.matchedTransitionSource` + `.navigationTransition(.zoom)` für Liste→Detail. Namespace nur in `RestaurantListView`.
- **Haptic Feedback:** `.sensoryFeedback()` auf Favoriten-Toggle, View-Mode-Wechsel, Slider, Filter-Chips, Map-Controls. `UINotificationFeedbackGenerator` für Rating Submit/Delete.
- **Skeleton Loading:** Shimmer-Effekt beim App-Start (SkeletonCardView/SkeletonListRow statt ProgressView)
- **Suche:** Custom Suchbalken in Liste + Map mit `Color(.tertiarySystemBackground)` (im Dark Mode hell genug, dass Card lesbar bleibt) + 1pt `systemGray4` Stroke, 22pt continuous corner radius. Debouncing: `searchText` instant → `activeSearchText` (250ms). List zeigt Dropdown nur bei Query; Map zeigt zusätzlich Küchen-Suggestions bei leerem+fokussiertem Feld.
  - **Ranking via `RestaurantListView.rankMatches(_:in:)`** (shared helper, auch von Map benutzt): Name-Prefix (100) > Name-Contains (80) > Cuisine-Prefix (60) > Cuisine-Contains (40) > Hood-Prefix (30) > Hood-Contains (20). Ties nach MAMPF-Rating.
  - **Suggestions sind `@State`, nicht computed** — werden per `refreshSuggestions()` bei `searchText`-Change gepuscht, nicht pro Render neu berechnet.
  - **Rotating Placeholder:** `RotatingPlaceholder` (@Observable) cycled alle 4s durch Beispiele, pausiert bei Fokus/Typing. Als Custom-Overlay implementiert (nicht `prompt:`), weil iOS 26 prompt-foregroundStyle unzuverlässig rendert. Placeholder-Color via `Color(.systemGray2)` (genug Kontrast auf dunkler Card).
  - **Map-Suchbalken im Fokus:** Lupe links wird zu `chevron.backward` (tappable → schließt Suche), das X rechts ist weg.
- **List-Header Hide-on-Scroll:** `safeAreaInset(edge: .top)` + `frame(height: visible ? nil : 0) + clipped()` mit `.animation(.easeOut(0.22), value: headerVisible)`. **Funktioniert in allen 3 View-Modi** (Cards/Grid/List). `onScrollGeometryChange` füllt nur den `ScrollTracker.accumulator` (Plain Class — `@State CGFloat` invalidiert den Body pro Scroll-Event und stuttert). Visibility-Toggle aber **NICHT** in dem Callback, sondern in `onScrollPhaseChange` und nur bei `newPhase == .decelerating`. Slow-Drags enden in `.idle` → Header reagiert nicht. Sonst hatte sich die Liste während Drag-mit-Finger-drauf sichtbar nach oben/unten verschoben (`safeAreaInset`-Frame-Toggle = Content-Shift). Auto-Show bei `newValue < 20` bleibt direkt im Geometry-Callback (gegated auf `phase != .tracking`). Thresholds: 40pt hide, 30pt show. Nur `isHeaderVisible` ist `@State`. **NICHT conditional im Body-Tree** — das zerstört TextField-Identity und die Suche "bricht sofort ab" beim Tippen.
- **Map-Focus-Dismiss nur bei echtem User-Drag:** `onMapCameraChange` feuert auch bei keyboard-induzierten Layout-Änderungen. Flag via `.simultaneousGesture(DragGesture(minimumDistance: 10))` setzen, im Callback prüfen.
- **Filter UX (Liste + Map einheitlich):**
  - **Chip-Bar** nutzt shared `FilterBarChip` (Pill mit Icon + Text + optional Chevron). `FiltersEntryChip` ist die Entry-Pill ganz links (mit lila Badge für Active-Filter-Count) — öffnet `FilterSheetView`.
  - **Chip-Backgrounds = solides `Color(.tertiarySystemBackground)`**, KEIN `.regularMaterial`. Material über bewegtem Map-Content rendert pro Frame neuen Live-Blur (5 Chips + Location-Button = 6 Blur-Passes/Frame) → Map-Pan ruckelt. Solide Fläche + Shadow gibt visuell den gleichen „elevated"-Effekt ohne GPU-Kosten.
  - **Liste:** Filters → Sort → Open Now → Cuisine → Preis → Stadtteil. Kein separater Clear-X-Button (Sheet hat Reset-Button).
  - **Map:** Filters → Open Now → Rating → Cuisine → Preis (kein Sort/Stadtteil — Pan erfüllt's). **Rating-Chip-Toggle:** aktiv → Tap resettet sofort (nicht Histogram öffnen); inaktiv → Tap öffnet Histogram.
  - **Sort-Chip** (Liste): Leading-Icon = aktuelle Richtung (`arrow.up`/`arrow.down`), Text = nur Field-Name, Menu-Chevron trailing. Kein redundanter Direction-Suffix.
  - **Filter-Sheet:** Custom Sheet mit Capsule-Chips im Grid.
  - **Rating-Histogram (Map):** Single-Line-Header — Rating-Pill in Tier-Color (links) + Match-Count (mitte) + X-Button (rechts). KEIN separater Reset-Button — Reset via Tap auf den aktiven Rating-Chip in der Chip-Bar. Location-Button schiebt animiert hoch (`padding(.bottom, showRatingFilter ? 168 : 0)`) wenn Histogram offen ist, sonst überlappt er den Slider.
- **Map-Pin-LOD:** `ZoomTier` (far/medium/close) basiert auf `latitudeDelta`. Weit raus (>0.12): nur Rating ≥ 8. Mittel: nur bewertete Spots. Nah (<0.035): alle. `onMapCameraChange(frequency: .onEnd)` updatet nur bei Tier-Wechsel. **Pins ohne weißen Rand.** Rating ≥ 9 bekommt zusätzlich lila Glow-Shadow.
- **Image Caching:** Eigener `ImageCache` (NSCache memory + URLCache disk). **NICHT `@MainActor`** — als `final class: @unchecked Sendable`, weil NSCache + URLSession thread-safe sind. So laufen Cache-Writes (besonders Prefetch-Completions) off-main und konkurrieren nicht mit Scroll-Rendering. **Echtes Downsampling** via `CGImageSourceCreateThumbnailAtIndex` im Background-Task — Call-Sites geben `targetSize` mit (× `displayScale`). `totalCostLimit: 80 MB`, `countLimit: 1000` (300 evictete bei 6 Bucket-Sizes × 155 Spots zu aggressiv → Cache-Hits wurden zu Misses bei Scroll-Back).
  - **Sync-Lookup `cachedImage(for:maxPixelSize:)`** für sofortiges Render auf Cache-Hit — `AsyncRestaurantImage` checkt erst sync, dann ggf. async. Verhindert Placeholder-Flash beim Zurückscrollen in LazyVStacks (Cell-Recreation → `@State image = nil`).
  - **Prefetch via `prefetch(urls:maxPixelSize:concurrency:)`** in `RestaurantStore.prefetchListImages()` — fire-and-forget Task `.background`, **1.5s delayed** damit erste Tap- und Hero-Zoom-Animation Vorrang hat. Nur Cards-Größe (430pt) gewärmt; Grid (220) + List (80) lazy on demand.
  - **Foodie-Preset für `/own/`-URLs:** `CIGammaAdjust` (adaptive Helligkeit pro Bild, Ziel-Luminanz 0.45, gamma clamped 0.55–1.25) + `CIHighlightShadowAdjust` (Highlights 0.65, Shadows 0.25) + `CITemperatureAndTint` (+150K) + `CIColorControls` (Saturation 1.13, Contrast 1.03). Google-Photos bleiben unberührt.
- **Rating-Eingabe (Detail):** Custom `RatingSlider` (1-10, 0.5 Steps) — minimalistisch: dünner grauer Track, farbige Filled-Portion bis Thumb, 22pt Thumb in Rating-Farbe, Scale +35% + Callout-Bubble beim Drag. **Auto-Save on Release** via `onEditingChanged(false)` — KEIN Rate/Update-Button mehr. Trash-Button sitzt inline neben Slider, reserved space via `opacity(0)` wenn nicht bewertet (Card-Höhe bleibt konstant). Optimistic UI: State direkt clearen, nur bei Server-Error zurückrollen.
- **Rating-Hero-Card:** Progress-Ring (140×140pt, 10pt lineWidth) um die Zahl, gefüllt proportional zum Rating. Farbe wechselt mit Tier. Card-Background = subtiler Rating-Tier-Gradient (opacity 0.14 → 0.03) + 1pt Stroke.
- **`RatingTier` Enum** (in `Rating.swift`): avoid (<5) / okay (<7) / good (<8) / recommended (<9) / mampf (≥9) — wird als UPPERCASE-Label neben der Zahl angezeigt damit User:innen die Skala teilen (eine 7 bei Jan = „Gut"). Locale: DE „Meiden/Okay/Gut/Empfehlung/MAMPF", EN „Avoid/Okay/Good/Recommended/MAMPF".
- **Opening Hours:** `OpeningHoursParser` splittet auf `;` UND `\n` (Supabase liefert Google-Format mit Newlines). Akzeptiert Google-Format (`"Monday: 4:00 – 10:00 PM"`) + simples Format (`"Mon-Sun 12:00-22:30"`). Detail-View nutzt Accordion: heute prominent (Status + Zeit), Chevron aufklappen für alle 7 Tage.
- **Share:** `ShareLink` im Detail-Toolbar mit Name, MAMPF-Rating, Cuisine/Stadtteil/Preis, Google Maps URL.
- **Mini-Map:** Statischer `MKMapSnapshotter` (`MapSnapshotCache` shared) statt Live-`Map()` im Detail — Sheet öffnet deutlich schneller. Coord + Size als Cache-Key. Scale kommt vom `@Environment(\.displayScale)` des Call-Site (nicht deprecated `UIScreen.main`).
- **Keyboard:** `.scrollDismissesKeyboard(.interactively)` auf Listen-ScrollView
- **Distanz:** Gecacht in `distanceCache: [UUID: String]` in RestaurantListView — berechnet einmal bei Location-/Data-Change (via `LocationManager.lastLocationToken`), nicht pro Row-Render.
- **Swipe-to-Favorite** (List-Mode): `SwiftUI.List` mit `.swipeActions(edge: .leading, allowsFullSwipe: true)`. Cards/Grid benutzen LazyVStack/Grid (Heart-Icon auf Card reicht).
- **Swipe-to-Delete im Profil:** „Your Ratings" + „Want to Try" nutzen `List` mit `.scrollDisabled(true)` + fixed height — native `.swipeActions` für Delete/Remove-Favorite, Outer-ScrollView scrollt weiter vertikal. **Navigation programmatisch via `Button { navigatedRestaurant = ... }` + `.navigationDestination(item: $navigatedRestaurant)`**, NICHT NavigationLink — der System-Chevron in `List` ist nicht zuverlässig zu unterdrücken (`.tint(.clear)` killt auch swipe-action-Farben). Eigener Inline-Chevron rechts neben der Pill bleibt unter Kontrolle.

## Auth & Account (Non-Obvious)

- **Login-Flow:** 3 Steps (Email → Password → Name). Step 1 ruft `check_email_exists` RPC, routet zu Welcome-back-Sign-in oder Create-Account-Signup. Name nur bei Signup, als `user_metadata.display_name`.
- **iCloud Keychain Save braucht Hidden Username-Field** auf Step 2: iOS pairt Email+Password nur wenn beide im View-Tree sind beim Submit. Deshalb hat Step 2 einen `TextField("", text: .constant(email)).textContentType(.username).frame(0,0).opacity(0).disabled(true)`. Ohne das kommt kein "Save Password"-Prompt.
- **Rating-Migration beim ersten Login:** Device-ID-Rows werden User zugeordnet. Konflikte (User hatte schon Rating für gleichen Spot) → **neuerer `updated_at` gewinnt**, Verlierer-Row wird gelöscht. Code: `UserRatingRepository.migrateDeviceRatingsToUser`, getriggert von `RestaurantStore.setCurrentUser`.
- **Favorites = Visited + WantToTry:** Profile-Tab splittet Favorites per Rating-Presence: mit Rating = „Your Ratings" (besucht), ohne = „Want to Try" (Wishlist). Favorites sind aktuell noch **lokal** (UserDefaults) — Server-Sync auf `user_favorites` ist Backlog.
- **Account Deletion** folgt App Store Guideline 5.1.1(v) via `delete_own_account` RPC. UI-Pattern: kleiner zentrierter roter Text-Link unten in Settings, NICHT prominenter destructive-Button.
- **Cancellation-Errors** (`CancellationError`, `URLError.cancelled`) werden in `RestaurantStore` silent gefiltert via `Error.isCancellation` — sonst Toast beim Pull-to-Refresh.

## UI-Struktur

- **Tabs:** Map ("Karte"), Food Spots, Profil — Standard iOS TabView
- **Food Spots-Tab:** Title "Hamburg ˅" (City-Selector Menu, inline title mode). Custom Suchbalken darunter (sticky, mit Restaurant-Suggestions beim Tippen). Chip-Bar darunter (Filters · Sort · Open Now · Cuisine · Preis · Stadtteil). Content: 3 View-Modi (Cards → Grid → Liste). Trailing-Toolbar: Heart, ViewMode (Sort ist jetzt als Chip, nicht mehr Toolbar). **Header versteckt sich in allen 3 View-Modi beim Scrollen**, kommt zurück bei Scroll-Up oder nahe am Top.
- **Map:** Custom Suchbalken oben, Quick-Filter-Chips darunter (Filters · Open Now · Rating · Cuisine · Preis). Location-Button unten rechts. Rating-Histogram als Bottom-Overlay (tappable Bars, Balken mit Vertical-Gradient innerhalb Rating-Farbe für Depth). Tap auf Such-Ergebnis schließt Suche + zoomt Map + öffnet Detail-Sheet. **Pins:** Rating-Bubble (28pt, Rating-Farbe, Zahl zentriert), unbewertete 14pt Grau-Dot — **ohne weißen Rand**. Rating ≥ 9 hat zusätzlich lila Glow-Shadow. LOD basiert auf Zoom-Level.
- **Profil-Tab:** Zeigt **gleiche Struktur für anon + signed-in** — Stats + „Your Ratings" + „Want to Try". Anon Ratings kommen via `device_id` (DB) + Wishlist aus UserDefaults. Oben:
  - Signed-in: Account-Header (tap → Edit Profile) + Sign-Out-Button unten
  - Signed-out: Inline Email-Entry-Card mit Envelope-Icon + Arrow-Button (lila wenn valid email, sonst grau). Submit → LoginSheet mit `prefilledEmail` → skippt Email-Step direkt zu Password
  - Settings via Gear oben rechts
  - Title „Profil" immer inline (kein Large-Title-Collapse)
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

**user_ratings**: id, restaurant_id, device_id, user_id (nullable — signed-in Nutzer haben user_id, anon Device-ID-only), rating (1-10), created_at, updated_at — UNIQUE(restaurant_id, device_id), UNIQUE(restaurant_id, user_id).
- **RLS-Policies:**
  - `"authed users manage own ratings"`: `FOR ALL TO authenticated USING (user_id = auth.uid())`
  - `"anon users manage own anon ratings"`: `FOR ALL TO anon USING (user_id IS NULL) WITH CHECK (user_id IS NULL)` — ohne diese Policy fallen anon-Deletes silent durch (HTTP 204 ohne DB-Change). Client-side device_id-Filter begrenzt Scope.
- **Delete-Logik robuster:** `UserRatingRepository.deleteRating` führt **zwei** Deletes aus — bei signed-in den user_id-Match, immer zusätzlich den device_id-anon-Match. Fängt Migrations-Edge-Cases ab, wo ein Row halb-migriert steckt.

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
- **Storage-Struktur:** `restaurant-images/` Root = Google Places Fotos, `own/` = eigene Fotos. **Niemals Google Places Fotos in `own/` speichern.** Eigene Fotos werden beim Decode automatisch angepasst (siehe ImageCache Foodie-Preset).
- `user_ratings` hat vorbereitete `user_id`-Spalte für zukünftigen Email-Login (Supabase Auth aktiviert, aktuell Device-ID)
- Custom DragGesture-Slider auf Map funktioniert nicht — nativen SwiftUI Slider verwenden (der custom `RatingSlider` in der Detail-Card ist OK — Map-Context ist anders)
- `.toolbarTitleMenu` zeigt keinen sichtbaren Chevron im Large-Title-Modus — für City-Selector stattdessen inline Title mit Custom Menu + explizitem chevron.down verwenden
- Swift 6 Concurrency: `SupabaseManager` muss `Sendable` + `nonisolated static let shared` sein, `DeviceID` Properties müssen `nonisolated` sein, damit `actor UserRatingRepository` darauf zugreifen kann
- **Tap-Through bei ScrollView + NavigationLinks:** Ein `Button` oder `onTapGesture` im gleichen ScrollView-Scope wie NavigationLinks kann Taps an das erste NavigationLink durchreichen (erstes Card öffnet sich statt Button-Action zu feuern). Fix: Ziel-View strukturell außerhalb der ScrollView platzieren (sticky Header via VStack über der ScrollView), nicht via Button-Style oder Gesture-Priority tricksen.
- **Performance-Killer die wir gefunden haben:**
  - `PulseDot` (Infinite `.repeatForever`-Animation) pro sichtbarer Card × 4-5 sichtbare → Tap-Latenz + Scroll-Stutter. **Entfernt.** Open/Closed-Dots sind jetzt statisch.
  - Body-Tree-Switch im List-View (`if showingDropdown { … } else { … }`) zerstört TextField-Identity und Gesture-State → Suche hakt. **Nicht tun** — immer gleichen View-Tree rendern, Dropdown inline expandieren.
  - **`@State` Schreiben pro Scroll-Event** invalidiert den Body → mit 155 LazyVStack-Cells extrem teuer, fühlt sich an als "springt der Scroll". Akkumulator/Tracker-State **immer in Plain Class halten** und `@State` nur auf Properties die wirklich UI driven (z.B. `isHeaderVisible`).
  - **Animated `safeAreaInset` height-change WÄHREND aktivem Drag** → iOS justiert `contentOffset` zur Kompensation, Liste folgt nicht mehr 1:1 dem Finger. Toggle nur direkt beim Threshold-Cross (kurze Animation 0.22s) — Debounce über `onScrollPhaseChange` ist auf iOS 26 unzuverlässig.
  - **`.regularMaterial`-Backgrounds über bewegtem Map/Scroll-Content** = Live-Blur-Recompute pro Frame. 5 Filter-Chips + Location-Button im Map-Overlay = 6 Blur-Passes/Frame → spürbares Pan-Ruckeln. Solides `Color(.tertiarySystemBackground)` + Shadow gibt visuell den gleichen Floating-Look ohne GPU-Kosten.
  - **`ImageCache` als `@MainActor`** zwang alle Cache-Writes (besonders ~155 Prefetch-Completions) durch den Main Actor → konkurrierte mit Scroll-Rendering, sichtbares Stuttering. Fix: NSCache + URLSession sind eh thread-safe, also `final class: @unchecked Sendable`, alle Methoden nonisolated.
  - **O(n²) Joins in Profile-Stats:** `store.restaurants.first(where: { $0.id == entry.restaurantId })` pro Rating × N Restaurants. Fix: `RestaurantStore.restaurantsById: [UUID: Restaurant]` Dict einmal beim `restaurants` didSet aufgebaut. Profile-Stats (`ratedCount`, `averageRating`, `favoriteCuisine`, `ratedEntriesWithRestaurants`) werden einmal in `recomputeStats()` via `.onChange(of: store.myRatingEntries)` berechnet, nicht pro Render.
  - **`.task { ... }` ohne `id` läuft jedes Mal beim View-Re-Appear** (z.B. Zurück-Navigation vom Detail). Wenn die Task schwere Arbeit macht (155 Restaurants filtern + sortieren), blockiert sie die Hero-Zoom-Animation → 2s Wartezeit bis die Liste wieder reagiert. Fix: `.onChange(of: token, initial: true)` statt unconditional `.task`. Initial:true deckt First-Render mit ab.
- **iOS 26 TextField `prompt: Text(...).foregroundStyle(...)`** wird manchmal ignoriert (Placeholder bleibt tint-farbig/blau). Workaround: Custom `Text` als ZStack-Overlay, `if $binding.wrappedValue.isEmpty` einblenden. Siehe `ProfileTabView.signInBanner`.
- **AsyncRestaurantImage** braucht `targetSize` pro Call-Site — sonst lädt iOS das volle 1600px-Google-Foto auch für 36px-Thumbnails in den RAM. Bucket-Größen: 36 (search), 44 (profile rows), 80 (list row), 220 (grid card), 430 (full card), ≥350 (detail hero).
- **SourceKit-Warnings beim Editieren** ("Cannot find type 'Restaurant' in scope" etc.) sind meist stale Cross-File-Warnings wegen `PBXFileSystemSynchronizedRootGroup` — Index ist kurz nicht aktuell. Ignorieren solange `xcodebuild` sauber baut.
