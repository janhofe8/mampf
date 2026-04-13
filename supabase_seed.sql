-- MAMPF Seed Data
-- Run this in the Supabase SQL Editor after creating the schema

INSERT INTO restaurants (name, cuisine_type, neighborhood, price_range, address, latitude, longitude, opening_hours, is_closed, personal_rating, google_rating, google_review_count) VALUES
-- Burger
('Otto''s Burger', 'burger', 'sternschanze', 'moderate', 'Schanzenstraße 87, 20357 Hamburg', 53.5630, 9.9670, 'Mon-Sun 11:30-22:00', false, 8.5, 4.4, 1850),
('Dulf''s Burger', 'burger', 'stPauli', 'moderate', 'Große Freiheit 16, 20359 Hamburg', 53.5510, 9.9580, 'Mon-Sun 12:00-23:00', false, 8.5, 4.5, 1620),
('Billy the Butcher', 'burger', 'sternschanze', 'moderate', 'Schulterblatt 73, 20357 Hamburg', 53.5625, 9.9635, 'Mon-Sun 12:00-22:30', false, 8.5, 4.3, 1430),
('Murder Burger', 'burger', 'altona', 'moderate', 'Bahrenfelder Straße 188, 22765 Hamburg', 53.5535, 9.9385, 'Tue-Sun 12:00-22:00', false, 8.0, 4.3, 680),
('Hob''s Hut of Burger', 'burger', 'ottensen', 'moderate', 'Bahrenfelder Straße 130, 22765 Hamburg', 53.5530, 9.9320, 'Tue-Sun 12:00-22:00', false, 9.0, 4.6, 520),
('Burger Heroes', 'burger', 'eimsbüttel', 'moderate', 'Osterstraße 52, 20259 Hamburg', 53.5720, 9.9580, 'Mon-Sun 11:30-22:00', false, 8.5, 4.4, 890),
('Burger Vision', 'burger', 'stPauli', 'moderate', 'Clemens-Schultz-Straße 52, 20359 Hamburg', 53.5530, 9.9620, 'Mon-Sun 12:00-23:00', false, 8.5, 4.3, 560),
('Underdocks', 'burger', 'stPauli', 'moderate', 'Reeperbahn 46, 20359 Hamburg', 53.5500, 9.9600, 'Mon-Sun 12:00-01:00', false, 8.5, 4.2, 920),

-- Pizza / Italian
('L''Osteria', 'italian', 'altstadt', 'moderate', 'Große Bleichen 23, 20354 Hamburg', 53.5530, 9.9890, 'Mon-Sun 11:30-23:00', false, 8.0, 4.3, 1980),
('Pizza Social Club', 'pizza', 'sternschanze', 'moderate', 'Bartelsstraße 27, 20357 Hamburg', 53.5640, 9.9650, 'Tue-Sun 17:00-23:00', false, 8.5, 4.5, 740),
('Pizzamacher Trattoria', 'pizza', 'ottensen', 'moderate', 'Friedensallee 26, 22765 Hamburg', 53.5545, 9.9250, 'Tue-Sun 12:00-22:30', false, 9.5, 4.7, 620),
('Spaccaforno', 'pizza', 'eimsbüttel', 'moderate', 'Eppendorfer Weg 57, 20259 Hamburg', 53.5710, 9.9620, 'Mon-Sun 12:00-22:30', false, 9.0, 4.6, 510),
('Pizza Electric', 'pizza', 'stPauli', 'budget', 'Hein-Hoyer-Straße 60, 20359 Hamburg', 53.5520, 9.9650, 'Tue-Sun 17:00-23:00', false, 8.0, 4.4, 380),
('Tazzi Pizza', 'pizza', 'altona', 'budget', 'Ottenser Hauptstraße 10, 22765 Hamburg', 53.5525, 9.9310, 'Mon-Sun 11:00-23:00', false, 8.5, 4.2, 450),
('Farina meets Mehl', 'pizza', 'ottensen', 'moderate', 'Arnoldstraße 52, 22765 Hamburg', 53.5540, 9.9270, 'Tue-Sun 17:00-22:30', false, 8.5, 4.5, 340),
('Farina Di Nonna', 'pizza', 'eimsbüttel', 'moderate', 'Bismarckstraße 110, 20253 Hamburg', 53.5740, 9.9620, 'Tue-Sun 12:00-22:00', false, 8.5, 4.6, 280),
('60 seconds to Napoli', 'pizza', 'neustadt', 'budget', 'Wexstraße 28, 20355 Hamburg', 53.5560, 9.9720, 'Mon-Sun 11:30-22:00', false, 7.5, 4.1, 620),
('Edmondo', 'italian', 'ottensen', 'moderate', 'Eulenstraße 22, 22765 Hamburg', 53.5555, 9.9280, 'Tue-Sun 12:00-22:30', false, 7.5, 4.3, 310),
('Spezzagrano', 'italian', 'sternschanze', 'moderate', 'Susannenstraße 30, 20357 Hamburg', 53.5620, 9.9680, 'Mon-Sun 12:00-22:00', false, 7.5, 4.2, 250),
('The Pasta Club', 'italian', 'stPauli', 'moderate', 'Detlev-Bremer-Straße 44, 20359 Hamburg', 53.5545, 9.9640, 'Tue-Sun 17:00-22:30', false, 8.0, 4.4, 420),

-- Korean
('Kimchi guys', 'korean', 'sternschanze', 'moderate', 'Schulterblatt 62, 20357 Hamburg', 53.5628, 9.9640, 'Mon-Sun 12:00-22:00', false, 8.0, 4.3, 680),
('Yong Korean', 'korean', 'neustadt', 'moderate', 'Poolstraße 8, 20355 Hamburg', 53.5510, 9.9760, 'Tue-Sun 12:00-22:00', false, 7.0, 4.1, 420),
('Seoul 1988', 'korean', 'stPauli', 'moderate', 'Marktstraße 120, 20357 Hamburg', 53.5580, 9.9620, 'Mon-Sun 12:00-22:30', false, 9.0, 4.6, 750),
('Chingu', 'korean', 'eimsbüttel', 'moderate', 'Stellinger Weg 2, 20255 Hamburg', 53.5750, 9.9530, 'Tue-Sun 17:00-22:30', false, 8.5, 4.5, 380),

-- Vietnamese
('Quan 19', 'vietnamese', 'altona', 'budget', 'Königstraße 19, 22767 Hamburg', 53.5520, 9.9450, 'Mon-Sun 11:30-22:00', false, 7.5, 4.2, 530),
('An Vegan House', 'vietnamese', 'stPauli', 'budget', 'Thadenstraße 1, 22767 Hamburg', 53.5540, 9.9530, 'Tue-Sun 12:00-21:00', false, 6.5, 4.0, 310),
('Ai Yeu Ai', 'vietnamese', 'ottensen', 'budget', 'Große Rainstraße 21, 22765 Hamburg', 53.5550, 9.9260, 'Closed', true, 8.5, 4.4, 290),
('XeOm Eatery', 'vietnamese', 'eimsbüttel', 'moderate', 'Eppendorfer Weg 171, 20253 Hamburg', 53.5760, 9.9630, 'Tue-Sun 12:00-22:00', false, 9.0, 4.6, 480),
('Green Papaya', 'vietnamese', 'altona', 'budget', 'Kleine Rainstraße 14, 22765 Hamburg', 53.5528, 9.9340, 'Mon-Sun 11:30-22:00', false, 7.5, 4.1, 620),
('Vietbowl', 'vietnamese', 'sternschanze', 'budget', 'Schulterblatt 90, 20357 Hamburg', 53.5635, 9.9660, 'Mon-Sun 12:00-22:00', false, 7.5, 4.0, 350),
('Banh Banh', 'vietnamese', 'sternschanze', 'budget', 'Schanzenstraße 36, 20357 Hamburg', 53.5610, 9.9660, 'Tue-Sun 12:00-22:00', false, 9.0, 4.5, 410),
('Litte Tiana', 'vietnamese', 'barmbek', 'budget', 'Fuhlsbüttler Straße 108, 22305 Hamburg', 53.5850, 10.0420, 'Mon-Sat 11:30-21:30', false, 7.0, 4.2, 280),

-- Japanese
('Saito', 'japanese', 'altona', 'moderate', 'Max-Brauer-Allee 207, 22769 Hamburg', 53.5580, 9.9470, 'Tue-Sun 12:00-14:30, 17:30-22:00', false, 8.5, 4.5, 590),
('Tyo Tyo', 'japanese', 'sternschanze', 'moderate', 'Bartelsstraße 12, 20357 Hamburg', 53.5642, 9.9645, 'Tue-Sun 17:30-22:30', false, 8.5, 4.4, 430),
('Takumi', 'japanese', 'stPauli', 'moderate', 'Beim Grünen Jäger 1, 20359 Hamburg', 53.5600, 9.9650, 'Mon-Sun 12:00-22:00', false, 9.0, 4.5, 1200),
('Lesser Panda Ramen', 'japanese', 'sternschanze', 'moderate', 'Juliusstraße 16, 22769 Hamburg', 53.5615, 9.9590, 'Closed', true, 7.0, 4.1, 340),
('Izakaya by dokuwa', 'japanese', 'eimsbüttel', 'moderate', 'Hoheluftchaussee 58, 20253 Hamburg', 53.5770, 9.9680, 'Tue-Sun 17:30-23:00', false, 9.0, 4.7, 350),
('YUYU', 'japanese', 'stGeorg', 'moderate', 'Lange Reihe 72, 20099 Hamburg', 53.5560, 10.0100, 'Tue-Sun 12:00-22:00', false, 8.0, 4.3, 480),

-- Turkish / Middle Eastern
('Lokmam', 'turkish', 'ottensen', 'budget', 'Ottenser Hauptstraße 52, 22765 Hamburg', 53.5520, 9.9290, 'Mon-Sun 10:00-22:00', false, 9.5, 4.6, 820),
('Saray Koz', 'turkish', 'altona', 'budget', 'Holstenstraße 108, 22767 Hamburg', 53.5540, 9.9490, 'Mon-Sun 10:00-23:00', false, 6.5, 3.9, 380),
('Batman', 'turkish', 'altona', 'budget', 'Holstenstraße 162, 22767 Hamburg', 53.5555, 9.9485, 'Mon-Sun 09:00-01:00', false, 8.5, 4.3, 510),
('Authentikka', 'turkish', 'ottensen', 'moderate', 'Bahrenfelder Straße 201, 22765 Hamburg', 53.5548, 9.9300, 'Tue-Sun 11:00-22:00', false, 9.0, 4.5, 290),
('Honest Kebab', 'turkish', 'sternschanze', 'budget', 'Schulterblatt 30, 20357 Hamburg', 53.5615, 9.9630, 'Mon-Sun 11:00-02:00', false, 9.0, 4.4, 680),
('Hakan Abi', 'turkish', 'stPauli', 'budget', 'Budapester Straße 40, 20359 Hamburg', 53.5520, 9.9700, 'Mon-Sun 10:00-03:00', false, 8.0, 4.2, 750),
('Yemen Restaurant', 'middleEastern', 'stGeorg', 'budget', 'Bremer Reihe 21, 20099 Hamburg', 53.5555, 10.0070, 'Mon-Sun 12:00-23:00', false, 8.5, 4.4, 510),
('Maihan', 'middleEastern', 'stGeorg', 'moderate', 'Lange Reihe 36, 20099 Hamburg', 53.5558, 10.0090, 'Mon-Sun 12:00-22:30', false, 8.5, 4.5, 620),
('L''Orient', 'middleEastern', 'sternschanze', 'budget', 'Schanzenstraße 29, 20357 Hamburg', 53.5605, 9.9660, 'Mon-Sun 11:00-23:00', false, 7.5, 4.1, 430),

-- Greek
('Corfu Grill', 'greek', 'ottensen', 'budget', 'Bahrenfelder Straße 98, 22765 Hamburg', 53.5532, 9.9310, 'Mon-Sat 11:00-22:00', false, 8.5, 4.4, 720),
('Xenios', 'greek', 'eimsbüttel', 'moderate', 'Methfesselstraße 26, 20257 Hamburg', 53.5690, 9.9560, 'Tue-Sun 17:00-23:00', false, 8.5, 4.5, 380),
('Mezedes', 'greek', 'winterhude', 'moderate', 'Mühlenkamp 41, 22303 Hamburg', 53.5830, 10.0010, 'Tue-Sun 17:00-23:00', false, 9.5, 4.7, 450),

-- Mexican
('Chango', 'mexican', 'ottensen', 'moderate', 'Friedensallee 42, 22765 Hamburg', 53.5543, 9.9240, 'Mon-Sun 12:00-22:00', false, 8.0, 4.2, 480),
('La Casita', 'mexican', 'sternschanze', 'moderate', 'Bartelsstraße 65, 20357 Hamburg', 53.5645, 9.9640, 'Tue-Sun 17:00-23:00', false, 9.0, 4.5, 520),
('Qrito', 'mexican', 'stPauli', 'budget', 'Feldstraße 66, 20357 Hamburg', 53.5585, 9.9630, 'Mon-Sun 11:30-22:00', false, 8.5, 4.3, 410),
('Baborrito', 'mexican', 'neustadt', 'budget', 'Großneumarkt 14, 20459 Hamburg', 53.5500, 9.9780, 'Mon-Sun 11:00-22:00', false, 8.0, 4.1, 530),
('Taqueria Mexiko Strasse', 'mexican', 'eimsbüttel', 'budget', 'Mexikoring 25, 22297 Hamburg', 53.5810, 9.9870, 'Tue-Sun 12:00-22:00', false, 8.5, 4.4, 340),

-- Poke
('Poke Bar', 'poke', 'neustadt', 'moderate', 'Dammtorstraße 29, 20354 Hamburg', 53.5570, 9.9850, 'Mon-Sun 11:30-21:00', false, 7.0, 4.0, 320),
('Tiki Poke Bowl', 'poke', 'sternschanze', 'moderate', 'Schanzenstraße 73, 20357 Hamburg', 53.5618, 9.9665, 'Mon-Sun 11:30-21:30', false, 8.5, 4.3, 280),

-- Seafood
('Daniel Wischer', 'seafood', 'altstadt', 'moderate', 'Spitalerstraße 1, 20095 Hamburg', 53.5530, 10.0020, 'Mon-Sat 10:00-20:00', false, 8.0, 4.2, 1350),
('Rive', 'seafood', 'altona', 'upscale', 'Van-der-Smissen-Straße 1, 22767 Hamburg', 53.5445, 9.9420, 'Mon-Sun 12:00-23:00', false, 8.5, 4.4, 1680),

-- Asian
('Herr He', 'asian', 'altona', 'moderate', 'Max-Brauer-Allee 168, 22765 Hamburg', 53.5570, 9.9460, 'Mon-Sun 12:00-22:00', false, 8.5, 4.4, 590),
('JING JING', 'asian', 'stGeorg', 'moderate', 'Steindamm 67, 20099 Hamburg', 53.5540, 10.0130, 'Mon-Sun 12:00-22:30', false, 7.0, 3.8, 320),
('BATU Noodle Society', 'asian', 'sternschanze', 'moderate', 'Schanzenstraße 62, 20357 Hamburg', 53.5613, 9.9668, 'Tue-Sun 12:00-22:00', false, 8.0, 4.3, 350),
('bam! bam! noodles', 'asian', 'altona', 'budget', 'Neue Große Bergstraße 17, 22767 Hamburg', 53.5515, 9.9460, 'Mon-Sat 11:30-21:30', false, 8.5, 4.4, 290),
('Tao Tao', 'asian', 'sternschanze', 'moderate', 'Schulterblatt 44, 20357 Hamburg', 53.5622, 9.9635, 'Mon-Sun 12:00-23:00', false, 9.0, 4.5, 680),
('Wen Cheng', 'asian', 'stGeorg', 'budget', 'Steindamm 39, 20099 Hamburg', 53.5545, 10.0110, 'Mon-Sun 11:00-22:00', false, 8.5, 4.3, 520),
('Paledo', 'asian', 'ottensen', 'moderate', 'Bahrenfelder Straße 216, 22765 Hamburg', 53.5538, 9.9295, 'Tue-Sun 12:00-22:00', false, 9.0, 4.6, 410),

-- Streetfood
('Piri Piri', 'streetfood', 'sternschanze', 'budget', 'Schanzenstraße 95, 20357 Hamburg', 53.5632, 9.9672, 'Mon-Sun 12:00-23:00', false, 9.0, 4.4, 560),
('Buns Streetfood', 'streetfood', 'stPauli', 'budget', 'Neuer Pferdemarkt 5, 20359 Hamburg', 53.5595, 9.9610, 'Mon-Sun 11:30-22:00', false, 8.0, 4.2, 440),
('Diggi Smalls', 'streetfood', 'sternschanze', 'budget', 'Schulterblatt 88, 20357 Hamburg', 53.5633, 9.9658, 'Tue-Sun 12:00-22:00', false, 8.0, 4.3, 310),

-- Cafes
('Cafe Nascherei', 'cafe', 'ottensen', 'moderate', 'Ottenser Hauptstraße 28, 22765 Hamburg', 53.5522, 9.9300, 'Mon-Sun 09:00-18:00', false, 7.5, 4.3, 460),
('Breakfastdream', 'cafe', 'eimsbüttel', 'moderate', 'Osterstraße 166, 20255 Hamburg', 53.5730, 9.9540, 'Mon-Sun 08:30-16:00', false, 7.5, 4.2, 520),
('Nord Coast Coffee', 'cafe', 'altstadt', 'moderate', 'Mönckebergstraße 28, 20095 Hamburg', 53.5535, 10.0000, 'Mon-Sat 08:00-19:00, Sun 10:00-18:00', false, 7.5, 4.1, 380),
('Honeybee', 'cafe', 'ottensen', 'moderate', 'Eulenstraße 15, 22765 Hamburg', 53.5557, 9.9275, 'Mon-Fri 08:00-17:00, Sat-Sun 09:00-17:00', false, 7.0, 4.2, 290),
('Morgenmuffel', 'cafe', 'sternschanze', 'moderate', 'Bartelsstraße 36, 20357 Hamburg', 53.5643, 9.9648, 'Mon-Sun 09:00-16:00', false, 8.5, 4.5, 610),
('Cafe Wundervoll', 'cafe', 'altona', 'moderate', 'Hospitalstraße 28, 22767 Hamburg', 53.5518, 9.9470, 'Mon-Fri 08:30-17:00, Sat-Sun 09:30-17:00', false, 6.0, 3.8, 210),
('Good One Cafe', 'cafe', 'ottensen', 'moderate', 'Große Rainstraße 10, 22765 Hamburg', 53.5552, 9.9265, 'Mon-Sun 08:30-17:00', false, 7.0, 4.1, 340),
('Cafe Mirel', 'cafe', 'eimsbüttel', 'moderate', 'Stellinger Weg 21, 20255 Hamburg', 53.5745, 9.9525, 'Mon-Sun 09:00-18:00', false, 7.5, 4.3, 280),
('Pancake Panda', 'cafe', 'neustadt', 'moderate', 'Neuer Wall 43, 20354 Hamburg', 53.5525, 9.9870, 'Mon-Sun 09:00-17:00', false, 4.0, 3.5, 540),

-- German / Other
('Ottenser Foodkitchen', 'other', 'ottensen', 'moderate', 'Ottenser Hauptstraße 2, 22765 Hamburg', 53.5519, 9.9305, 'Mon-Sat 11:30-22:00', false, 8.0, 4.2, 380),
('Puro', 'other', 'altona', 'moderate', 'Max-Brauer-Allee 277, 22769 Hamburg', 53.5595, 9.9445, 'Tue-Sun 12:00-22:00', false, 7.5, 4.1, 260),
('Jill', 'other', 'ottensen', 'moderate', 'Gaußstraße 33, 22765 Hamburg', 53.5560, 9.9310, 'Tue-Sun 17:30-23:00', false, 7.5, 4.3, 350),
('kini', 'other', 'altona', 'moderate', 'Große Bergstraße 223, 22767 Hamburg', 53.5512, 9.9455, 'Mon-Sun 11:30-22:00', false, 7.0, 4.0, 290),
('Kohldampf', 'german', 'stPauli', 'moderate', 'Wohlwillstraße 22, 20359 Hamburg', 53.5555, 9.9640, 'Tue-Sun 12:00-22:00', false, 7.5, 4.2, 320),
('Henssler Henssler', 'other', 'hafenCity', 'upscale', 'Große Elbstraße 160, 22767 Hamburg', 53.5440, 9.9380, 'Mon-Sun 17:00-23:00', false, 8.0, 4.3, 1950),
('Herzstueck', 'other', 'stPauli', 'moderate', 'Clemens-Schultz-Straße 87, 20359 Hamburg', 53.5535, 9.9630, 'Tue-Sun 17:00-23:00', false, 7.5, 4.2, 410),
('Eat.Drink.Love', 'other', 'ottensen', 'moderate', 'Bahrenfelder Straße 110, 22765 Hamburg', 53.5533, 9.9315, 'Tue-Sun 09:00-16:00', false, 6.5, 4.0, 280),
('44QM', 'other', 'stPauli', 'moderate', 'Beim Grünen Jäger 18, 20359 Hamburg', 53.5598, 9.9645, 'Tue-Sat 18:00-23:00', false, 8.0, 4.4, 320),
('Was wir wirklich lieben', 'cafe', 'ottensen', 'moderate', 'Große Rainstraße 17, 22765 Hamburg', 53.5548, 9.9262, 'Mon-Sun 09:00-18:00', false, 7.0, 4.2, 380),
('Das Peace', 'other', 'eimsbüttel', 'moderate', 'Osterstraße 88, 20259 Hamburg', 53.5725, 9.9570, 'Mon-Sun 12:00-22:00', false, 8.0, 4.3, 440),
('Hatari', 'other', 'sternschanze', 'moderate', 'Schanzenstraße 2, 20357 Hamburg', 53.5608, 9.9655, 'Mon-Sun 11:30-23:00', false, 7.5, 4.1, 370),
('Bolle', 'other', 'eppendorf', 'moderate', 'Eppendorfer Landstraße 4, 20249 Hamburg', 53.5830, 9.9830, 'Mon-Sun 09:00-23:00', false, 8.0, 4.3, 550),
('Ratsherrn Das Lokal', 'german', 'sternschanze', 'moderate', 'Lagerstraße 28, 20357 Hamburg', 53.5600, 9.9690, 'Tue-Sun 12:00-22:00', false, 8.0, 4.4, 780),
('[m]eatery', 'other', 'hafenCity', 'upscale', 'Am Kaiserkai 13, 20457 Hamburg', 53.5410, 9.9890, 'Mon-Sun 12:00-23:00', false, 8.5, 4.4, 620),
('Roots', 'other', 'stPauli', 'moderate', 'Feldstraße 58, 20357 Hamburg', 53.5588, 9.9625, 'Tue-Sun 12:00-22:00', false, 8.5, 4.5, 380),
('Mirou', 'other', 'ottensen', 'moderate', 'Barnerstraße 14, 22765 Hamburg', 53.5560, 9.9285, 'Tue-Sun 18:00-23:00', false, 8.5, 4.5, 250),
('Traumkuh', 'other', 'eimsbüttel', 'moderate', 'Osterstraße 47, 20259 Hamburg', 53.5718, 9.9575, 'Mon-Sun 10:00-22:00', false, 8.5, 4.4, 480);
