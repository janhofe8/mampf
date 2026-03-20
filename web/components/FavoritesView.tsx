"use client";

import { RestaurantWithCommunity } from "@/lib/types";
import RestaurantCard from "./RestaurantCard";

interface FavoritesViewProps {
  restaurants: RestaurantWithCommunity[];
  favorites: Set<string>;
  onToggleFavorite: (id: string) => void;
  onSelectRestaurant: (restaurant: RestaurantWithCommunity) => void;
}

export default function FavoritesView({
  restaurants,
  favorites,
  onToggleFavorite,
  onSelectRestaurant,
}: FavoritesViewProps) {
  const favoriteRestaurants = restaurants
    .filter((r) => favorites.has(r.id))
    .sort((a, b) => (b.personal_rating ?? 0) - (a.personal_rating ?? 0));

  if (favoriteRestaurants.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full px-6 text-center">
        <div className="w-20 h-20 rounded-full bg-black/5 flex items-center justify-center mb-4">
          <svg
            className="w-10 h-10 text-gray-300"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={1.5}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
            />
          </svg>
        </div>
        <h3 className="text-lg font-bold text-gray-900 mb-1">No Favorites Yet</h3>
        <p className="text-sm text-gray-400 max-w-xs">
          Tap the heart icon on any restaurant to save it here for quick access.
        </p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto px-4 pt-3 pb-24">
      <p className="text-xs text-gray-400 mb-3">
        {favoriteRestaurants.length} favorite
        {favoriteRestaurants.length !== 1 ? "s" : ""}
      </p>
      <div className="space-y-3">
        {favoriteRestaurants.map((r) => (
          <RestaurantCard
            key={r.id}
            restaurant={r}
            isFavorite={true}
            onToggleFavorite={onToggleFavorite}
            onClick={onSelectRestaurant}
          />
        ))}
      </div>
    </div>
  );
}
