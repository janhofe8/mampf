export interface Restaurant {
  id: string;
  name: string;
  cuisine_type: string;
  neighborhood: string;
  price_range: string;
  address: string;
  latitude: number;
  longitude: number;
  opening_hours: string | null;
  is_closed: boolean;
  notes: string | null;
  image_url: string | null;
  personal_rating: number | null;
  google_rating: number | null;
  google_review_count: number | null;
  google_place_id: string | null;
  google_maps_url: string | null;
}

export interface CommunityRating {
  restaurant_id: string;
  community_rating: number | null;
  community_rating_count: number | null;
}

export interface UserRating {
  id: string;
  restaurant_id: string;
  device_id: string;
  rating: number;
  created_at: string;
  updated_at: string;
}

export interface RestaurantWithCommunity extends Restaurant {
  community_rating?: number | null;
  community_rating_count?: number | null;
  user_rating?: number | null;
}

export type SortOption =
  | "mampf_desc"
  | "mampf_asc"
  | "google_desc"
  | "community_desc"
  | "distance"
  | "name_asc"
  | "name_za";

export interface Filters {
  cuisines: string[];
  neighborhoods: string[];
  priceRanges: string[];
  minRating: number;
}

export const CUISINE_TYPES: Record<string, string> = {
  burger: "\ud83c\udf54",
  pizza: "\ud83c\udf55",
  italian: "\ud83c\udf5d",
  korean: "\ud83e\udd58",
  vietnamese: "\ud83c\udf5c",
  japanese: "\ud83c\udf63",
  chinese: "\ud83e\udd61",
  thai: "\ud83c\udf5b",
  turkish: "\ud83e\udd59",
  greek: "\ud83e\udeda",
  mexican: "\ud83c\udf2e",
  german: "\ud83e\udd68",
  middleEastern: "\ud83e\uddc6",
  portuguese: "\ud83d\udc19",
  oriental: "\ud83e\uddc6",
  seafood: "\ud83d\udc1f",
  poke: "\ud83e\udd57",
  brunch: "\ud83e\udd5e",
  steak: "\ud83e\udd69",
  other: "\ud83c\udf7d\ufe0f",
};

export const PRICE_LABELS: Record<string, string> = {
  budget: "\u20ac",
  moderate: "\u20ac\u20ac",
  upscale: "\u20ac\u20ac\u20ac",
  fine: "\u20ac\u20ac\u20ac\u20ac",
};

export const NEIGHBORHOODS: string[] = [
  "altona",
  "ottensen",
  "stPauli",
  "sternschanze",
  "eimsb\u00fcttel",
  "neustadt",
  "altstadt",
  "winterhude",
  "eppendorf",
  "barmbek",
  "stGeorg",
  "hafenCity",
  "other",
];
