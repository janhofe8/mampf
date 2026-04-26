# Google Places API Usage Tracker

## Free Tier Limits (pro Monat)
- Text Search: 5.000
- Place Details: 5.000
- Place Photo: 1.000

## März 2026

### Vor Tracking (19.–20. März)
| SKU | Calls |
|-----|-------|
| Text Search | 394 |
| Place Photo | 198 |
| FindPlace (Legacy) | 1 |

### 2026-03-21
| SKU | Calls | Kontext |
|-----|-------|---------|
| Text Search | 47 | 11 pre-session (Namens-Check etc.) + 36 Content-Session (neue Restaurants) |
| Place Details | 239 | 97× Namens-Check + ~44× Photo-Lookups + 97× Koordinaten-Fix + 1× Bolle Koordinaten |
| Place Photo | 45 | ~36 Content-Session + 9 pre-session |

**Content-Session neue Spots:** Siggys, The Window, An An, Thämer's, Pizzanatics, Chingu→St.Pauli, Il Siciliano, Köz-Antep, Vu Food, Bolle→Schanze, memán, FAVORITA, Instinct Coffee, Yume Ramen, New City Smash, Falafel Haus, Monsieur Alfons, Atlantik Fisch, Ai Bánh Mì, Neustädter Grill Meier, Qrito Grindel, China Restaurant Spicy, MOMO Ramen, Fischereihafen, Bistro Cà Phê Viet, Kardelen, SVAAdish, Kebaba, Dulf's WH + Eimsbüttel, Mit Herz und Zucker, Hanging out Café, Kimo, Falafelstern, Confiserie Niko, Café Dailycioso, Karo Fisch, Kleine Haie, Spaccaforno WH, Burger Heroes Reeperbahn

### 2026-03-21 (Abend)
| SKU | Calls | Kontext |
|-----|-------|---------|
| Text Search | 4 | Hofbräu, Yaku, Kropkå, Luigi's |
| Place Details | 4 | Photo-Lookups für alle 4 |
| Place Photo | 4 | Download für alle 4 |

### Monats-Summe März
| SKU | Verbraucht | Gratis-Limit | Rest |
|-----|-----------|--------------|------|
| Text Search | ~445 | 5.000 | ~4.555 |
| Place Details | ~243 | 5.000 | ~4.757 |
| Place Photo | ~247 | 1.000 | ~753 |
| **Gesamt** | **~936** | | |

## April 2026

### 2026-04-19
| SKU | Calls | Kontext |
|-----|-------|---------|
| Text Search | 2 | Vienna, Pizzeria Michele Ottensen |

**Neue Spots:** Vienna (Karolinenviertel, 🥨 German, €€€, MAMPF 8.0), L'Antica Pizzeria da Michele (Ottensen, 🍕 Pizza, €€, MAMPF 6.5)

### 2026-04-24
| SKU | Calls | Kontext |
|-----|-------|---------|
| Place Details | 157 | Bulk-Refresh aller Restaurants: rating, review_count, opening_hours, business_status. 155 erfolgreich, 2 fehlgeschlagen (ungültige Place IDs). |
| Text Search | 2 | Place-ID-Fix für „New York Bagel Bar Gänsemarkt" + „Nord Coast Coffee Roastery". |

### 2026-04-26
| SKU | Calls | Kontext |
|-----|-------|---------|
| Text Search | 1 | Takumi Schanze (Schulterblatt 114) — Korrektur: bestehender „Takumi"-Eintrag hatte Ottensen-Adresse, ist eigentlich der Schanze-Standort. |
| Place Photo | 1 | Schanze-Foto für Takumi (ersetzt Ottensen-Foto, alte Datei aus Storage gelöscht). |
| Text Search | 1 | Hanoi Deli Rathaus (neuer Spot, Schauenburgerstraße 49, Altstadt, MAMPF 7.5). Eigenes Foto aus Folder verwendet, kein Place-Photo-Call. |

### Monats-Summe April
| SKU | Verbraucht | Gratis-Limit | Rest |
|-----|-----------|--------------|------|
| Text Search | 6 | 5.000 | 4.994 |
| Place Details | 157 | 5.000 | 4.843 |
| Place Photo | 1 | 1.000 | 999 |
