import Foundation

struct RestaurantSeed {
    let name: String
    let cuisine: CuisineType
    let neighborhood: Neighborhood
    let price: PriceRange
    let address: String
    let lat: Double
    let lon: Double
    let hours: String
    let isClosed: Bool
    let personalRating: Double
    let googleRating: Double
    let googleReviewCount: Int
}

let allRestaurantSeeds: [RestaurantSeed] = [
    // MARK: - Burger
    RestaurantSeed(name: "Otto's Burger", cuisine: .burger, neighborhood: .sternschanze, price: .moderate, address: "Schanzenstraße 87, 20357 Hamburg", lat: 53.5630, lon: 9.9670, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 1850),
    RestaurantSeed(name: "Dulf's Burger", cuisine: .burger, neighborhood: .stPauli, price: .moderate, address: "Große Freiheit 16, 20359 Hamburg", lat: 53.5510, lon: 9.9580, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 1620),
    RestaurantSeed(name: "Billy the Butcher", cuisine: .burger, neighborhood: .sternschanze, price: .moderate, address: "Schulterblatt 73, 20357 Hamburg", lat: 53.5625, lon: 9.9635, hours: "Mon-Sun 12:00-22:30", isClosed: false, personalRating: 8.5, googleRating: 4.3, googleReviewCount: 1430),
    RestaurantSeed(name: "Murder Burger", cuisine: .burger, neighborhood: .altona, price: .moderate, address: "Bahrenfelder Straße 188, 22765 Hamburg", lat: 53.5535, lon: 9.9385, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 680),
    RestaurantSeed(name: "Hob's Hut of Burger", cuisine: .burger, neighborhood: .ottensen, price: .moderate, address: "Bahrenfelder Straße 130, 22765 Hamburg", lat: 53.5530, lon: 9.9320, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 9.0, googleRating: 4.6, googleReviewCount: 520),
    RestaurantSeed(name: "Burger Heroes", cuisine: .burger, neighborhood: .eimsbüttel, price: .moderate, address: "Osterstraße 52, 20259 Hamburg", lat: 53.5720, lon: 9.9580, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 890),
    RestaurantSeed(name: "Burger Vision", cuisine: .burger, neighborhood: .stPauli, price: .moderate, address: "Clemens-Schultz-Straße 52, 20359 Hamburg", lat: 53.5530, lon: 9.9620, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.3, googleReviewCount: 560),
    RestaurantSeed(name: "Underdocks", cuisine: .burger, neighborhood: .stPauli, price: .moderate, address: "Reeperbahn 46, 20359 Hamburg", lat: 53.5500, lon: 9.9600, hours: "Mon-Sun 12:00-01:00", isClosed: false, personalRating: 8.5, googleRating: 4.2, googleReviewCount: 920),

    // MARK: - Pizza / Italian
    RestaurantSeed(name: "L'Osteria", cuisine: .italian, neighborhood: .altstadt, price: .moderate, address: "Große Bleichen 23, 20354 Hamburg", lat: 53.5530, lon: 9.9890, hours: "Mon-Sun 11:30-23:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 1980),
    RestaurantSeed(name: "Pizza Social Club", cuisine: .pizza, neighborhood: .sternschanze, price: .moderate, address: "Bartelsstraße 27, 20357 Hamburg", lat: 53.5640, lon: 9.9650, hours: "Tue-Sun 17:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 740),
    RestaurantSeed(name: "Pizzamacher Trattoria", cuisine: .pizza, neighborhood: .ottensen, price: .moderate, address: "Friedensallee 26, 22765 Hamburg", lat: 53.5545, lon: 9.9250, hours: "Tue-Sun 12:00-22:30", isClosed: false, personalRating: 9.5, googleRating: 4.7, googleReviewCount: 620),
    RestaurantSeed(name: "Spaccaforno", cuisine: .pizza, neighborhood: .eimsbüttel, price: .moderate, address: "Eppendorfer Weg 57, 20259 Hamburg", lat: 53.5710, lon: 9.9620, hours: "Mon-Sun 12:00-22:30", isClosed: false, personalRating: 9.0, googleRating: 4.6, googleReviewCount: 510),
    RestaurantSeed(name: "Pizza Electric", cuisine: .pizza, neighborhood: .stPauli, price: .budget, address: "Hein-Hoyer-Straße 60, 20359 Hamburg", lat: 53.5520, lon: 9.9650, hours: "Tue-Sun 17:00-23:00", isClosed: false, personalRating: 8.0, googleRating: 4.4, googleReviewCount: 380),
    RestaurantSeed(name: "Tazzi Pizza", cuisine: .pizza, neighborhood: .altona, price: .budget, address: "Ottenser Hauptstraße 10, 22765 Hamburg", lat: 53.5525, lon: 9.9310, hours: "Mon-Sun 11:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.2, googleReviewCount: 450),
    RestaurantSeed(name: "Farina meets Mehl", cuisine: .pizza, neighborhood: .ottensen, price: .moderate, address: "Arnoldstraße 52, 22765 Hamburg", lat: 53.5540, lon: 9.9270, hours: "Tue-Sun 17:00-22:30", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 340),
    RestaurantSeed(name: "Farina Di Nonna", cuisine: .pizza, neighborhood: .eimsbüttel, price: .moderate, address: "Bismarckstraße 110, 20253 Hamburg", lat: 53.5740, lon: 9.9620, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.6, googleReviewCount: 280),
    RestaurantSeed(name: "60 seconds to Napoli", cuisine: .pizza, neighborhood: .neustadt, price: .budget, address: "Wexstraße 28, 20355 Hamburg", lat: 53.5560, lon: 9.9720, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.1, googleReviewCount: 620),
    RestaurantSeed(name: "Edmondo", cuisine: .italian, neighborhood: .ottensen, price: .moderate, address: "Eulenstraße 22, 22765 Hamburg", lat: 53.5555, lon: 9.9280, hours: "Tue-Sun 12:00-22:30", isClosed: false, personalRating: 7.5, googleRating: 4.3, googleReviewCount: 310),
    RestaurantSeed(name: "Spezzagrano", cuisine: .italian, neighborhood: .sternschanze, price: .moderate, address: "Susannenstraße 30, 20357 Hamburg", lat: 53.5620, lon: 9.9680, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.2, googleReviewCount: 250),
    RestaurantSeed(name: "The Pasta Club", cuisine: .italian, neighborhood: .stPauli, price: .moderate, address: "Detlev-Bremer-Straße 44, 20359 Hamburg", lat: 53.5545, lon: 9.9640, hours: "Tue-Sun 17:00-22:30", isClosed: false, personalRating: 8.0, googleRating: 4.4, googleReviewCount: 420),

    // MARK: - Korean
    RestaurantSeed(name: "Kimchi guys", cuisine: .korean, neighborhood: .sternschanze, price: .moderate, address: "Schulterblatt 62, 20357 Hamburg", lat: 53.5628, lon: 9.9640, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 680),
    RestaurantSeed(name: "Yong Korean", cuisine: .korean, neighborhood: .neustadt, price: .moderate, address: "Poolstraße 8, 20355 Hamburg", lat: 53.5510, lon: 9.9760, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 7.0, googleRating: 4.1, googleReviewCount: 420),
    RestaurantSeed(name: "Seoul 1988", cuisine: .korean, neighborhood: .stPauli, price: .moderate, address: "Marktstraße 120, 20357 Hamburg", lat: 53.5580, lon: 9.9620, hours: "Mon-Sun 12:00-22:30", isClosed: false, personalRating: 9.0, googleRating: 4.6, googleReviewCount: 750),
    RestaurantSeed(name: "Chingu", cuisine: .korean, neighborhood: .eimsbüttel, price: .moderate, address: "Stellinger Weg 2, 20255 Hamburg", lat: 53.5750, lon: 9.9530, hours: "Tue-Sun 17:00-22:30", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 380),

    // MARK: - Vietnamese
    RestaurantSeed(name: "Quan 19", cuisine: .vietnamese, neighborhood: .altona, price: .budget, address: "Königstraße 19, 22767 Hamburg", lat: 53.5520, lon: 9.9450, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.2, googleReviewCount: 530),
    RestaurantSeed(name: "An Vegan House", cuisine: .vietnamese, neighborhood: .stPauli, price: .budget, address: "Thadenstraße 1, 22767 Hamburg", lat: 53.5540, lon: 9.9530, hours: "Tue-Sun 12:00-21:00", isClosed: false, personalRating: 6.5, googleRating: 4.0, googleReviewCount: 310),
    RestaurantSeed(name: "Ai Yeu Ai", cuisine: .vietnamese, neighborhood: .ottensen, price: .budget, address: "Große Rainstraße 21, 22765 Hamburg", lat: 53.5550, lon: 9.9260, hours: "Closed", isClosed: true, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 290),
    RestaurantSeed(name: "XeOm Eatery", cuisine: .vietnamese, neighborhood: .eimsbüttel, price: .moderate, address: "Eppendorfer Weg 171, 20253 Hamburg", lat: 53.5760, lon: 9.9630, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 9.0, googleRating: 4.6, googleReviewCount: 480),
    RestaurantSeed(name: "Green Papaya", cuisine: .vietnamese, neighborhood: .altona, price: .budget, address: "Kleine Rainstraße 14, 22765 Hamburg", lat: 53.5528, lon: 9.9340, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.1, googleReviewCount: 620),
    RestaurantSeed(name: "Vietbowl", cuisine: .vietnamese, neighborhood: .sternschanze, price: .budget, address: "Schulterblatt 90, 20357 Hamburg", lat: 53.5635, lon: 9.9660, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.0, googleReviewCount: 350),
    RestaurantSeed(name: "Banh Banh", cuisine: .vietnamese, neighborhood: .sternschanze, price: .budget, address: "Schanzenstraße 36, 20357 Hamburg", lat: 53.5610, lon: 9.9660, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 9.0, googleRating: 4.5, googleReviewCount: 410),
    RestaurantSeed(name: "Litte Tiana", cuisine: .vietnamese, neighborhood: .barmbek, price: .budget, address: "Fuhlsbüttler Straße 108, 22305 Hamburg", lat: 53.5850, lon: 10.0420, hours: "Mon-Sat 11:30-21:30", isClosed: false, personalRating: 7.0, googleRating: 4.2, googleReviewCount: 280),

    // MARK: - Japanese
    RestaurantSeed(name: "Saito", cuisine: .japanese, neighborhood: .altona, price: .moderate, address: "Max-Brauer-Allee 207, 22769 Hamburg", lat: 53.5580, lon: 9.9470, hours: "Tue-Sun 12:00-14:30, 17:30-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 590),
    RestaurantSeed(name: "Tyo Tyo", cuisine: .japanese, neighborhood: .sternschanze, price: .moderate, address: "Bartelsstraße 12, 20357 Hamburg", lat: 53.5642, lon: 9.9645, hours: "Tue-Sun 17:30-22:30", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 430),
    RestaurantSeed(name: "Takumi", cuisine: .japanese, neighborhood: .stPauli, price: .moderate, address: "Beim Grünen Jäger 1, 20359 Hamburg", lat: 53.5600, lon: 9.9650, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 9.0, googleRating: 4.5, googleReviewCount: 1200),
    RestaurantSeed(name: "Lesser Panda Ramen", cuisine: .japanese, neighborhood: .sternschanze, price: .moderate, address: "Juliusstraße 16, 22769 Hamburg", lat: 53.5615, lon: 9.9590, hours: "Closed", isClosed: true, personalRating: 7.0, googleRating: 4.1, googleReviewCount: 340),
    RestaurantSeed(name: "Izakaya by dokuwa", cuisine: .japanese, neighborhood: .eimsbüttel, price: .moderate, address: "Hoheluftchaussee 58, 20253 Hamburg", lat: 53.5770, lon: 9.9680, hours: "Tue-Sun 17:30-23:00", isClosed: false, personalRating: 9.0, googleRating: 4.7, googleReviewCount: 350),
    RestaurantSeed(name: "YUYU", cuisine: .japanese, neighborhood: .stGeorg, price: .moderate, address: "Lange Reihe 72, 20099 Hamburg", lat: 53.5560, lon: 10.0100, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 480),

    // MARK: - Turkish / Middle Eastern
    RestaurantSeed(name: "Lokmam", cuisine: .turkish, neighborhood: .ottensen, price: .budget, address: "Ottenser Hauptstraße 52, 22765 Hamburg", lat: 53.5520, lon: 9.9290, hours: "Mon-Sun 10:00-22:00", isClosed: false, personalRating: 9.5, googleRating: 4.6, googleReviewCount: 820),
    RestaurantSeed(name: "Saray Koz", cuisine: .turkish, neighborhood: .altona, price: .budget, address: "Holstenstraße 108, 22767 Hamburg", lat: 53.5540, lon: 9.9490, hours: "Mon-Sun 10:00-23:00", isClosed: false, personalRating: 6.5, googleRating: 3.9, googleReviewCount: 380),
    RestaurantSeed(name: "Batman", cuisine: .turkish, neighborhood: .altona, price: .budget, address: "Holstenstraße 162, 22767 Hamburg", lat: 53.5555, lon: 9.9485, hours: "Mon-Sun 09:00-01:00", isClosed: false, personalRating: 8.5, googleRating: 4.3, googleReviewCount: 510),
    RestaurantSeed(name: "Authentikka", cuisine: .turkish, neighborhood: .ottensen, price: .moderate, address: "Bahrenfelder Straße 201, 22765 Hamburg", lat: 53.5548, lon: 9.9300, hours: "Tue-Sun 11:00-22:00", isClosed: false, personalRating: 9.0, googleRating: 4.5, googleReviewCount: 290),
    RestaurantSeed(name: "Honest Kebab", cuisine: .turkish, neighborhood: .sternschanze, price: .budget, address: "Schulterblatt 30, 20357 Hamburg", lat: 53.5615, lon: 9.9630, hours: "Mon-Sun 11:00-02:00", isClosed: false, personalRating: 9.0, googleRating: 4.4, googleReviewCount: 680),
    RestaurantSeed(name: "Hakan Abi", cuisine: .turkish, neighborhood: .stPauli, price: .budget, address: "Budapester Straße 40, 20359 Hamburg", lat: 53.5520, lon: 9.9700, hours: "Mon-Sun 10:00-03:00", isClosed: false, personalRating: 8.0, googleRating: 4.2, googleReviewCount: 750),
    RestaurantSeed(name: "Yemen Restaurant", cuisine: .middleEastern, neighborhood: .stGeorg, price: .budget, address: "Bremer Reihe 21, 20099 Hamburg", lat: 53.5555, lon: 10.0070, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 510),
    RestaurantSeed(name: "Maihan", cuisine: .middleEastern, neighborhood: .stGeorg, price: .moderate, address: "Lange Reihe 36, 20099 Hamburg", lat: 53.5558, lon: 10.0090, hours: "Mon-Sun 12:00-22:30", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 620),
    RestaurantSeed(name: "L'Orient", cuisine: .middleEastern, neighborhood: .sternschanze, price: .budget, address: "Schanzenstraße 29, 20357 Hamburg", lat: 53.5605, lon: 9.9660, hours: "Mon-Sun 11:00-23:00", isClosed: false, personalRating: 7.5, googleRating: 4.1, googleReviewCount: 430),

    // MARK: - Greek
    RestaurantSeed(name: "Corfu Grill", cuisine: .greek, neighborhood: .ottensen, price: .budget, address: "Bahrenfelder Straße 98, 22765 Hamburg", lat: 53.5532, lon: 9.9310, hours: "Mon-Sat 11:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 720),
    RestaurantSeed(name: "Xenios", cuisine: .greek, neighborhood: .eimsbüttel, price: .moderate, address: "Methfesselstraße 26, 20257 Hamburg", lat: 53.5690, lon: 9.9560, hours: "Tue-Sun 17:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 380),
    RestaurantSeed(name: "Mezedes", cuisine: .greek, neighborhood: .winterhude, price: .moderate, address: "Mühlenkamp 41, 22303 Hamburg", lat: 53.5830, lon: 10.0010, hours: "Tue-Sun 17:00-23:00", isClosed: false, personalRating: 9.5, googleRating: 4.7, googleReviewCount: 450),

    // MARK: - Mexican
    RestaurantSeed(name: "Chango", cuisine: .mexican, neighborhood: .ottensen, price: .moderate, address: "Friedensallee 42, 22765 Hamburg", lat: 53.5543, lon: 9.9240, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.2, googleReviewCount: 480),
    RestaurantSeed(name: "La Casita", cuisine: .mexican, neighborhood: .sternschanze, price: .moderate, address: "Bartelsstraße 65, 20357 Hamburg", lat: 53.5645, lon: 9.9640, hours: "Tue-Sun 17:00-23:00", isClosed: false, personalRating: 9.0, googleRating: 4.5, googleReviewCount: 520),
    RestaurantSeed(name: "Qrito", cuisine: .mexican, neighborhood: .stPauli, price: .budget, address: "Feldstraße 66, 20357 Hamburg", lat: 53.5585, lon: 9.9630, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.3, googleReviewCount: 410),
    RestaurantSeed(name: "Baborrito", cuisine: .mexican, neighborhood: .neustadt, price: .budget, address: "Großneumarkt 14, 20459 Hamburg", lat: 53.5500, lon: 9.9780, hours: "Mon-Sun 11:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.1, googleReviewCount: 530),
    RestaurantSeed(name: "Taqueria Mexiko Strasse", cuisine: .mexican, neighborhood: .eimsbüttel, price: .budget, address: "Mexikoring 25, 22297 Hamburg", lat: 53.5810, lon: 9.9870, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 340),

    // MARK: - Poke
    RestaurantSeed(name: "Poke Bar", cuisine: .poke, neighborhood: .neustadt, price: .moderate, address: "Dammtorstraße 29, 20354 Hamburg", lat: 53.5570, lon: 9.9850, hours: "Mon-Sun 11:30-21:00", isClosed: false, personalRating: 7.0, googleRating: 4.0, googleReviewCount: 320),
    RestaurantSeed(name: "Tiki Poke Bowl", cuisine: .poke, neighborhood: .sternschanze, price: .moderate, address: "Schanzenstraße 73, 20357 Hamburg", lat: 53.5618, lon: 9.9665, hours: "Mon-Sun 11:30-21:30", isClosed: false, personalRating: 8.5, googleRating: 4.3, googleReviewCount: 280),

    // MARK: - Seafood
    RestaurantSeed(name: "Daniel Wischer", cuisine: .seafood, neighborhood: .altstadt, price: .moderate, address: "Spitalerstraße 1, 20095 Hamburg", lat: 53.5530, lon: 10.0020, hours: "Mon-Sat 10:00-20:00", isClosed: false, personalRating: 8.0, googleRating: 4.2, googleReviewCount: 1350),
    RestaurantSeed(name: "Rive", cuisine: .seafood, neighborhood: .altona, price: .upscale, address: "Van-der-Smissen-Straße 1, 22767 Hamburg", lat: 53.5445, lon: 9.9420, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 1680),

    // MARK: - Asian
    RestaurantSeed(name: "Herr He", cuisine: .asian, neighborhood: .altona, price: .moderate, address: "Max-Brauer-Allee 168, 22765 Hamburg", lat: 53.5570, lon: 9.9460, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 590),
    RestaurantSeed(name: "JING JING", cuisine: .asian, neighborhood: .stGeorg, price: .moderate, address: "Steindamm 67, 20099 Hamburg", lat: 53.5540, lon: 10.0130, hours: "Mon-Sun 12:00-22:30", isClosed: false, personalRating: 7.0, googleRating: 3.8, googleReviewCount: 320),
    RestaurantSeed(name: "BATU Noodle Society", cuisine: .asian, neighborhood: .sternschanze, price: .moderate, address: "Schanzenstraße 62, 20357 Hamburg", lat: 53.5613, lon: 9.9668, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 350),
    RestaurantSeed(name: "bam! bam! noodles", cuisine: .asian, neighborhood: .altona, price: .budget, address: "Neue Große Bergstraße 17, 22767 Hamburg", lat: 53.5515, lon: 9.9460, hours: "Mon-Sat 11:30-21:30", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 290),
    RestaurantSeed(name: "Tao Tao", cuisine: .asian, neighborhood: .sternschanze, price: .moderate, address: "Schulterblatt 44, 20357 Hamburg", lat: 53.5622, lon: 9.9635, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 9.0, googleRating: 4.5, googleReviewCount: 680),
    RestaurantSeed(name: "Wen Cheng", cuisine: .asian, neighborhood: .stGeorg, price: .budget, address: "Steindamm 39, 20099 Hamburg", lat: 53.5545, lon: 10.0110, hours: "Mon-Sun 11:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.3, googleReviewCount: 520),
    RestaurantSeed(name: "Paledo", cuisine: .asian, neighborhood: .ottensen, price: .moderate, address: "Bahrenfelder Straße 216, 22765 Hamburg", lat: 53.5538, lon: 9.9295, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 9.0, googleRating: 4.6, googleReviewCount: 410),

    // MARK: - Streetfood
    RestaurantSeed(name: "Piri Piri", cuisine: .streetfood, neighborhood: .sternschanze, price: .budget, address: "Schanzenstraße 95, 20357 Hamburg", lat: 53.5632, lon: 9.9672, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 9.0, googleRating: 4.4, googleReviewCount: 560),
    RestaurantSeed(name: "Buns Streetfood", cuisine: .streetfood, neighborhood: .stPauli, price: .budget, address: "Neuer Pferdemarkt 5, 20359 Hamburg", lat: 53.5595, lon: 9.9610, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.2, googleReviewCount: 440),
    RestaurantSeed(name: "Diggi Smalls", cuisine: .streetfood, neighborhood: .sternschanze, price: .budget, address: "Schulterblatt 88, 20357 Hamburg", lat: 53.5633, lon: 9.9658, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 310),

    // MARK: - Cafes
    RestaurantSeed(name: "Cafe Nascherei", cuisine: .cafe, neighborhood: .ottensen, price: .moderate, address: "Ottenser Hauptstraße 28, 22765 Hamburg", lat: 53.5522, lon: 9.9300, hours: "Mon-Sun 09:00-18:00", isClosed: false, personalRating: 7.5, googleRating: 4.3, googleReviewCount: 460),
    RestaurantSeed(name: "Breakfastdream", cuisine: .cafe, neighborhood: .eimsbüttel, price: .moderate, address: "Osterstraße 166, 20255 Hamburg", lat: 53.5730, lon: 9.9540, hours: "Mon-Sun 08:30-16:00", isClosed: false, personalRating: 7.5, googleRating: 4.2, googleReviewCount: 520),
    RestaurantSeed(name: "Nord Coast Coffee", cuisine: .cafe, neighborhood: .altstadt, price: .moderate, address: "Mönckebergstraße 28, 20095 Hamburg", lat: 53.5535, lon: 10.0000, hours: "Mon-Sat 08:00-19:00, Sun 10:00-18:00", isClosed: false, personalRating: 7.5, googleRating: 4.1, googleReviewCount: 380),
    RestaurantSeed(name: "Honeybee", cuisine: .cafe, neighborhood: .ottensen, price: .moderate, address: "Eulenstraße 15, 22765 Hamburg", lat: 53.5557, lon: 9.9275, hours: "Mon-Fri 08:00-17:00, Sat-Sun 09:00-17:00", isClosed: false, personalRating: 7.0, googleRating: 4.2, googleReviewCount: 290),
    RestaurantSeed(name: "Morgenmuffel", cuisine: .cafe, neighborhood: .sternschanze, price: .moderate, address: "Bartelsstraße 36, 20357 Hamburg", lat: 53.5643, lon: 9.9648, hours: "Mon-Sun 09:00-16:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 610),
    RestaurantSeed(name: "Cafe Wundervoll", cuisine: .cafe, neighborhood: .altona, price: .moderate, address: "Hospitalstraße 28, 22767 Hamburg", lat: 53.5518, lon: 9.9470, hours: "Mon-Fri 08:30-17:00, Sat-Sun 09:30-17:00", isClosed: false, personalRating: 6.0, googleRating: 3.8, googleReviewCount: 210),
    RestaurantSeed(name: "Good One Cafe", cuisine: .cafe, neighborhood: .ottensen, price: .moderate, address: "Große Rainstraße 10, 22765 Hamburg", lat: 53.5552, lon: 9.9265, hours: "Mon-Sun 08:30-17:00", isClosed: false, personalRating: 7.0, googleRating: 4.1, googleReviewCount: 340),
    RestaurantSeed(name: "Cafe Mirel", cuisine: .cafe, neighborhood: .eimsbüttel, price: .moderate, address: "Stellinger Weg 21, 20255 Hamburg", lat: 53.5745, lon: 9.9525, hours: "Mon-Sun 09:00-18:00", isClosed: false, personalRating: 7.5, googleRating: 4.3, googleReviewCount: 280),
    RestaurantSeed(name: "Pancake Panda", cuisine: .cafe, neighborhood: .neustadt, price: .moderate, address: "Neuer Wall 43, 20354 Hamburg", lat: 53.5525, lon: 9.9870, hours: "Mon-Sun 09:00-17:00", isClosed: false, personalRating: 4.0, googleRating: 3.5, googleReviewCount: 540),

    // MARK: - German / Other
    RestaurantSeed(name: "Ottenser Foodkitchen", cuisine: .other, neighborhood: .ottensen, price: .moderate, address: "Ottenser Hauptstraße 2, 22765 Hamburg", lat: 53.5519, lon: 9.9305, hours: "Mon-Sat 11:30-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.2, googleReviewCount: 380),
    RestaurantSeed(name: "Puro", cuisine: .other, neighborhood: .altona, price: .moderate, address: "Max-Brauer-Allee 277, 22769 Hamburg", lat: 53.5595, lon: 9.9445, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.1, googleReviewCount: 260),
    RestaurantSeed(name: "Jill", cuisine: .other, neighborhood: .ottensen, price: .moderate, address: "Gaußstraße 33, 22765 Hamburg", lat: 53.5560, lon: 9.9310, hours: "Tue-Sun 17:30-23:00", isClosed: false, personalRating: 7.5, googleRating: 4.3, googleReviewCount: 350),
    RestaurantSeed(name: "kini", cuisine: .other, neighborhood: .altona, price: .moderate, address: "Große Bergstraße 223, 22767 Hamburg", lat: 53.5512, lon: 9.9455, hours: "Mon-Sun 11:30-22:00", isClosed: false, personalRating: 7.0, googleRating: 4.0, googleReviewCount: 290),
    RestaurantSeed(name: "Kohldampf", cuisine: .german, neighborhood: .stPauli, price: .moderate, address: "Wohlwillstraße 22, 20359 Hamburg", lat: 53.5555, lon: 9.9640, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 7.5, googleRating: 4.2, googleReviewCount: 320),
    RestaurantSeed(name: "Henssler Henssler", cuisine: .other, neighborhood: .hafenCity, price: .upscale, address: "Große Elbstraße 160, 22767 Hamburg", lat: 53.5440, lon: 9.9380, hours: "Mon-Sun 17:00-23:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 1950),
    RestaurantSeed(name: "Herzstueck", cuisine: .other, neighborhood: .stPauli, price: .moderate, address: "Clemens-Schultz-Straße 87, 20359 Hamburg", lat: 53.5535, lon: 9.9630, hours: "Tue-Sun 17:00-23:00", isClosed: false, personalRating: 7.5, googleRating: 4.2, googleReviewCount: 410),
    RestaurantSeed(name: "Eat.Drink.Love", cuisine: .other, neighborhood: .ottensen, price: .moderate, address: "Bahrenfelder Straße 110, 22765 Hamburg", lat: 53.5533, lon: 9.9315, hours: "Tue-Sun 09:00-16:00", isClosed: false, personalRating: 6.5, googleRating: 4.0, googleReviewCount: 280),
    RestaurantSeed(name: "44QM", cuisine: .other, neighborhood: .stPauli, price: .moderate, address: "Beim Grünen Jäger 18, 20359 Hamburg", lat: 53.5598, lon: 9.9645, hours: "Tue-Sat 18:00-23:00", isClosed: false, personalRating: 8.0, googleRating: 4.4, googleReviewCount: 320),
    RestaurantSeed(name: "Was wir wirklich lieben", cuisine: .cafe, neighborhood: .ottensen, price: .moderate, address: "Große Rainstraße 17, 22765 Hamburg", lat: 53.5548, lon: 9.9262, hours: "Mon-Sun 09:00-18:00", isClosed: false, personalRating: 7.0, googleRating: 4.2, googleReviewCount: 380),
    RestaurantSeed(name: "Das Peace", cuisine: .other, neighborhood: .eimsbüttel, price: .moderate, address: "Osterstraße 88, 20259 Hamburg", lat: 53.5725, lon: 9.9570, hours: "Mon-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 440),
    RestaurantSeed(name: "Hatari", cuisine: .other, neighborhood: .sternschanze, price: .moderate, address: "Schanzenstraße 2, 20357 Hamburg", lat: 53.5608, lon: 9.9655, hours: "Mon-Sun 11:30-23:00", isClosed: false, personalRating: 7.5, googleRating: 4.1, googleReviewCount: 370),
    RestaurantSeed(name: "Bolle", cuisine: .other, neighborhood: .eppendorf, price: .moderate, address: "Eppendorfer Landstraße 4, 20249 Hamburg", lat: 53.5830, lon: 9.9830, hours: "Mon-Sun 09:00-23:00", isClosed: false, personalRating: 8.0, googleRating: 4.3, googleReviewCount: 550),
    RestaurantSeed(name: "Ratsherrn Das Lokal", cuisine: .german, neighborhood: .sternschanze, price: .moderate, address: "Lagerstraße 28, 20357 Hamburg", lat: 53.5600, lon: 9.9690, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.0, googleRating: 4.4, googleReviewCount: 780),
    RestaurantSeed(name: "[m]eatery", cuisine: .other, neighborhood: .hafenCity, price: .upscale, address: "Am Kaiserkai 13, 20457 Hamburg", lat: 53.5410, lon: 9.9890, hours: "Mon-Sun 12:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 620),
    RestaurantSeed(name: "Roots", cuisine: .other, neighborhood: .stPauli, price: .moderate, address: "Feldstraße 58, 20357 Hamburg", lat: 53.5588, lon: 9.9625, hours: "Tue-Sun 12:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 380),
    RestaurantSeed(name: "Mirou", cuisine: .other, neighborhood: .ottensen, price: .moderate, address: "Barnerstraße 14, 22765 Hamburg", lat: 53.5560, lon: 9.9285, hours: "Tue-Sun 18:00-23:00", isClosed: false, personalRating: 8.5, googleRating: 4.5, googleReviewCount: 250),
    RestaurantSeed(name: "Traumkuh", cuisine: .other, neighborhood: .eimsbüttel, price: .moderate, address: "Osterstraße 47, 20259 Hamburg", lat: 53.5718, lon: 9.9575, hours: "Mon-Sun 10:00-22:00", isClosed: false, personalRating: 8.5, googleRating: 4.4, googleReviewCount: 480),
]
