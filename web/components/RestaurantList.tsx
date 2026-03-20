"use client";

import { useState, useMemo } from "react";
import { RestaurantWithCommunity, SortOption, Filters } from "@/lib/types";
import { calculateDistance } from "@/lib/utils";
import RestaurantCard from "./RestaurantCard";
import FilterSheet from "./FilterSheet";

interface RestaurantListProps {
  restaurants: RestaurantWithCommunity[];
  favorites: Set<string>;
  onToggleFavorite: (id: string) => void;
  onSelectRestaurant: (restaurant: RestaurantWithCommunity) => void;
  userLocation: { lat: number; lng: number } | null;
}

export default function RestaurantList({
  restaurants,
  favorites,
  onToggleFavorite,
  onSelectRestaurant,
  userLocation,
}: RestaurantListProps) {
  const [search, setSearch] = useState("");
  const [sortOption, setSortOption] = useState<SortOption>("mampf_desc");
  const [compact, setCompact] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [showSort, setShowSort] = useState(false);
  const [filters, setFilters] = useState<Filters>({
    cuisines: [],
    neighborhoods: [],
    priceRanges: [],
    minRating: 0,
  });

  const activeFilterCount =
    filters.cuisines.length +
    filters.neighborhoods.length +
    filters.priceRanges.length +
    (filters.minRating > 0 ? 1 : 0);

  const filteredAndSorted = useMemo(() => {
    let result = [...restaurants];

    // Search
    if (search.trim()) {
      const query = search.toLowerCase();
      result = result.filter(
        (r) =>
          r.name.toLowerCase().includes(query) ||
          r.cuisine_type.toLowerCase().includes(query) ||
          r.neighborhood.toLowerCase().includes(query)
      );
    }

    // Filters
    if (filters.cuisines.length > 0) {
      result = result.filter((r) => filters.cuisines.includes(r.cuisine_type));
    }
    if (filters.neighborhoods.length > 0) {
      result = result.filter((r) =>
        filters.neighborhoods.includes(r.neighborhood)
      );
    }
    if (filters.priceRanges.length > 0) {
      result = result.filter((r) =>
        filters.priceRanges.includes(r.price_range)
      );
    }
    if (filters.minRating > 0) {
      result = result.filter(
        (r) => r.personal_rating != null && r.personal_rating >= filters.minRating
      );
    }

    // Sort
    result.sort((a, b) => {
      switch (sortOption) {
        case "mampf_desc":
          return (b.personal_rating ?? 0) - (a.personal_rating ?? 0);
        case "mampf_asc":
          return (a.personal_rating ?? 0) - (b.personal_rating ?? 0);
        case "google_desc":
          return (b.google_rating ?? 0) - (a.google_rating ?? 0);
        case "community_desc":
          return (b.community_rating ?? 0) - (a.community_rating ?? 0);
        case "recently_added":
          return (b.created_at ?? "").localeCompare(a.created_at ?? "");
        case "distance":
          if (!userLocation) return 0;
          const distA = calculateDistance(
            userLocation.lat,
            userLocation.lng,
            a.latitude,
            a.longitude
          );
          const distB = calculateDistance(
            userLocation.lat,
            userLocation.lng,
            b.latitude,
            b.longitude
          );
          return distA - distB;
        case "name_asc":
          return a.name.localeCompare(b.name);
        case "name_za":
          return b.name.localeCompare(a.name);
        default:
          return 0;
      }
    });

    return result;
  }, [restaurants, search, sortOption, filters, userLocation]);

  const sortLabels: Record<SortOption, string> = {
    mampf_desc: "MAMPF Rating \u2193",
    mampf_asc: "MAMPF Rating \u2191",
    google_desc: "Google Rating \u2193",
    community_desc: "Community \u2193",
    recently_added: "Zuletzt hinzugefügt",
    distance: "Distance",
    name_asc: "Name A-Z",
    name_za: "Name Z-A",
  };

  return (
    <div className="flex flex-col h-full">
      {/* Search and controls */}
      <div className="sticky top-0 z-20 bg-white/95 backdrop-blur-xl px-4 pt-3 pb-2 space-y-2">
        {/* Search bar */}
        <div className="relative">
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
            />
          </svg>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search restaurants..."
            className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-black/5 border border-black/10 text-gray-900 placeholder-gray-400 text-sm focus:outline-none focus:border-[rgb(115,51,217)] focus:ring-1 focus:ring-[rgb(115,51,217)] transition-colors"
          />
        </div>

        {/* Controls row */}
        <div className="flex items-center gap-2">
          {/* Sort dropdown */}
          <div className="relative flex-1">
            <button
              onClick={() => setShowSort(!showSort)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-black/5 text-gray-600 text-xs font-medium hover:bg-black/5 transition-colors w-full"
            >
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M3 7.5L7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5"
                />
              </svg>
              <span className="truncate">{sortLabels[sortOption]}</span>
            </button>
            {showSort && (
              <div className="absolute top-full left-0 mt-1 w-48 bg-gray-100 rounded-xl shadow-xl border border-black/10 overflow-hidden z-30">
                {(Object.entries(sortLabels) as [SortOption, string][]).map(
                  ([key, label]) => (
                    <button
                      key={key}
                      onClick={() => {
                        setSortOption(key);
                        setShowSort(false);
                      }}
                      className={`w-full px-3 py-2 text-left text-xs font-medium transition-colors ${
                        sortOption === key
                          ? "bg-[rgb(115,51,217)] text-white"
                          : "text-gray-600 hover:bg-black/5"
                      }`}
                    >
                      {label}
                    </button>
                  )
                )}
              </div>
            )}
          </div>

          {/* Filter button */}
          <button
            onClick={() => setShowFilters(true)}
            className={`relative flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
              activeFilterCount > 0
                ? "bg-[rgb(115,51,217)] text-white"
                : "bg-black/5 text-gray-600 hover:bg-black/5"
            }`}
          >
            <svg
              className="w-3.5 h-3.5"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 01-.659 1.591l-5.432 5.432a2.25 2.25 0 00-.659 1.591v2.927a2.25 2.25 0 01-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 00-.659-1.591L3.659 7.409A2.25 2.25 0 013 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0112 3z"
              />
            </svg>
            Filter
            {activeFilterCount > 0 && (
              <span className="ml-1 bg-white/30 rounded-full w-4 h-4 flex items-center justify-center text-[10px]">
                {activeFilterCount}
              </span>
            )}
          </button>

          {/* View toggle */}
          <button
            onClick={() => setCompact(!compact)}
            className="p-1.5 rounded-lg bg-black/5 text-gray-600 hover:bg-black/5 transition-colors"
          >
            {compact ? (
              <svg
                className="w-4 h-4"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                />
              </svg>
            ) : (
              <svg
                className="w-4 h-4"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z"
                />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Close sort dropdown on outside click */}
      {showSort && (
        <div
          className="fixed inset-0 z-10"
          onClick={() => setShowSort(false)}
        />
      )}

      {/* Results count */}
      <div className="px-4 py-2">
        <span className="text-xs text-gray-400">
          {filteredAndSorted.length} restaurant
          {filteredAndSorted.length !== 1 ? "s" : ""}
        </span>
      </div>

      {/* Restaurant grid/list */}
      <div className="flex-1 overflow-y-auto px-4 pb-24">
        {filteredAndSorted.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <span className="text-4xl mb-3">{"\ud83d\udd0d"}</span>
            <p className="text-gray-500 font-medium">No restaurants found</p>
            <p className="text-gray-400 text-sm mt-1">
              Try adjusting your search or filters
            </p>
          </div>
        ) : compact ? (
          <div className="grid grid-cols-2 gap-3">
            {filteredAndSorted.map((r) => (
              <RestaurantCard
                key={r.id}
                restaurant={r}
                compact
                isFavorite={favorites.has(r.id)}
                onToggleFavorite={onToggleFavorite}
                onClick={onSelectRestaurant}
              />
            ))}
          </div>
        ) : (
          <div className="space-y-3">
            {filteredAndSorted.map((r) => (
              <RestaurantCard
                key={r.id}
                restaurant={r}
                isFavorite={favorites.has(r.id)}
                onToggleFavorite={onToggleFavorite}
                onClick={onSelectRestaurant}
              />
            ))}
          </div>
        )}
      </div>

      {/* Filter Sheet */}
      <FilterSheet
        isOpen={showFilters}
        onClose={() => setShowFilters(false)}
        filters={filters}
        onApply={setFilters}
      />
    </div>
  );
}
