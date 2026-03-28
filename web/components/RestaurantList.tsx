"use client";

import { useState, useMemo, useDeferredValue } from "react";
import Image from "next/image";
import { RestaurantWithCommunity, SortOption, Filters } from "@/lib/types";
import {
  calculateDistance,
  getRatingBgClass,
  getRatingTextClass,
  getCuisineEmoji,
  getCuisineLabel,
  getPriceLabel,
  getNeighborhoodLabel,
  formatRating,
  formatDistance,
  filterRestaurants,
} from "@/lib/utils";
import RestaurantCard from "./RestaurantCard";
import FilterSheet from "./FilterSheet";
import HeartIcon from "./HeartIcon";

interface RestaurantListProps {
  restaurants: RestaurantWithCommunity[];
  favorites: Set<string>;
  onToggleFavorite: (id: string) => void;
  onSelectRestaurant: (restaurant: RestaurantWithCommunity) => void;
  userLocation: { lat: number; lng: number } | null;
  showFavoritesOnly: boolean;
  onToggleFavoritesOnly: () => void;
}

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = hash * 31 + str.charCodeAt(i);
    hash |= 0;
  }
  return hash;
}

const SORT_LABELS: Record<SortOption, string> = {
  mampf_desc: "MAMPF Rating \u2193",
  mampf_asc: "MAMPF Rating \u2191",
  google_desc: "Google Rating \u2193",
  community_desc: "Community \u2193",
  recently_added: "Recently Added",
  distance: "Distance",
  name_asc: "Name A\u2013Z",
  name_za: "Name Z\u2013A",
  random: "Random",
};

export default function RestaurantList({
  restaurants,
  favorites,
  onToggleFavorite,
  onSelectRestaurant,
  userLocation,
  showFavoritesOnly,
  onToggleFavoritesOnly,
}: RestaurantListProps) {
  const [search, setSearch] = useState("");
  const deferredSearch = useDeferredValue(search);
  const [sortOption, setSortOption] = useState<SortOption>("mampf_desc");
  const [viewMode, setViewMode] = useState(0);
  const [showFilters, setShowFilters] = useState(false);
  const [showSort, setShowSort] = useState(false);
  const [filters, setFilters] = useState<Filters>({
    cuisines: [],
    neighborhoods: [],
    priceRanges: [],
    minRating: 0,
  });
  const [randomSeed, setRandomSeed] = useState(() => Date.now());

  const activeFilterCount =
    filters.cuisines.length +
    filters.neighborhoods.length +
    filters.priceRanges.length;

  const isNonDefaultSort = sortOption !== "mampf_desc";

  const filteredAndSorted = useMemo(() => {
    let base = showFavoritesOnly
      ? restaurants.filter((r) => favorites.has(r.id))
      : restaurants;

    let result = filterRestaurants(base, {
      search: deferredSearch,
      cuisines: filters.cuisines,
      neighborhoods: filters.neighborhoods,
      priceRanges: filters.priceRanges,
      minRating: filters.minRating,
    });

    result = [...result].sort((a, b) => {
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
          return (
            calculateDistance(userLocation.lat, userLocation.lng, a.latitude, a.longitude) -
            calculateDistance(userLocation.lat, userLocation.lng, b.latitude, b.longitude)
          );
        case "name_asc":
          return a.name.localeCompare(b.name);
        case "name_za":
          return b.name.localeCompare(a.name);
        case "random":
          return hashCode(a.id + randomSeed) - hashCode(b.id + randomSeed);
        default:
          return 0;
      }
    });

    return result;
  }, [restaurants, deferredSearch, sortOption, filters, userLocation, showFavoritesOnly, favorites, randomSeed]);

  const getDistance = (r: RestaurantWithCommunity) => {
    if (!userLocation) return null;
    return calculateDistance(userLocation.lat, userLocation.lng, r.latitude, r.longitude);
  };

  const removeCuisine = (c: string) =>
    setFilters((f) => ({ ...f, cuisines: f.cuisines.filter((x) => x !== c) }));
  const removeNeighborhood = (n: string) =>
    setFilters((f) => ({ ...f, neighborhoods: f.neighborhoods.filter((x) => x !== n) }));
  const removePrice = (p: string) =>
    setFilters((f) => ({ ...f, priceRanges: f.priceRanges.filter((x) => x !== p) }));
  const resetSort = () => setSortOption("mampf_desc");

  return (
    <div className="flex flex-col h-full">
      {/* Search and controls */}
      <div className="sticky top-0 z-20 bg-white border-b border-black/5 px-4 pt-3 pb-2 space-y-2">
        {/* Search bar */}
        <div className="relative">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={`Search ${restaurants.length} food spots...`}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-black/5 border border-black/10 text-gray-900 placeholder-gray-400 text-sm focus:outline-none focus:border-[rgb(115,51,217)] focus:ring-1 focus:ring-[rgb(115,51,217)] transition-colors"
          />
        </div>

        {/* Controls row */}
        <div className="flex items-center gap-2">
          {/* Sort dropdown */}
          <div className="relative flex-1">
            <button
              onClick={() => setShowSort(!showSort)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-black/5 text-gray-600 text-xs font-medium hover:bg-black/10 transition-colors w-full"
            >
              <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 7.5L7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5" />
              </svg>
              <span className="truncate">{SORT_LABELS[sortOption]}</span>
            </button>
            {showSort && (
              <div className="absolute top-full left-0 mt-1 w-48 bg-gray-100 rounded-xl shadow-xl border border-black/10 overflow-hidden z-30">
                {(Object.entries(SORT_LABELS) as [SortOption, string][]).map(([key, label]) => (
                  <button
                    key={key}
                    onClick={() => {
                      if (key === "random") setRandomSeed(Date.now());
                      setSortOption(key);
                      setShowSort(false);
                    }}
                    className={`w-full px-3 py-2 text-left text-xs font-medium transition-colors ${
                      sortOption === key ? "bg-[rgb(115,51,217)] text-white" : "text-gray-600 hover:bg-black/5"
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Filter button */}
          <button
            onClick={() => setShowFilters(true)}
            className={`relative flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
              activeFilterCount > 0
                ? "bg-[rgb(115,51,217)] text-white"
                : "bg-black/5 text-gray-600 hover:bg-black/10"
            }`}
          >
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 01-.659 1.591l-5.432 5.432a2.25 2.25 0 00-.659 1.591v2.927a2.25 2.25 0 01-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 00-.659-1.591L3.659 7.409A2.25 2.25 0 013 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0112 3z" />
            </svg>
            Filter
            {activeFilterCount > 0 && (
              <span className="ml-1 bg-white/30 rounded-full w-4 h-4 flex items-center justify-center text-[10px]">
                {activeFilterCount}
              </span>
            )}
          </button>

          {/* Favorites toggle */}
          <button onClick={onToggleFavoritesOnly} className="p-1.5 rounded-lg bg-black/5 hover:bg-black/10 transition-colors">
            <HeartIcon filled={showFavoritesOnly} className={`w-4 h-4 ${!showFavoritesOnly ? "text-gray-600 fill-transparent" : ""}`} />
          </button>

          {/* View toggle */}
          <button onClick={() => setViewMode((viewMode + 1) % 3)} className="p-1.5 rounded-lg bg-black/5 text-gray-600 hover:bg-black/10 transition-colors">
            {viewMode === 0 ? (
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z" />
              </svg>
            ) : viewMode === 1 ? (
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
              </svg>
            ) : (
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
              </svg>
            )}
          </button>
        </div>

        {/* Active filter chips */}
        {(isNonDefaultSort || activeFilterCount > 0) && (
          <div className="flex gap-1.5 overflow-x-auto pb-1 -mx-4 px-4 scrollbar-hide">
            {isNonDefaultSort && (
              <button
                onClick={resetSort}
                className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-[rgb(115,51,217)]/10 text-[rgb(115,51,217)] text-xs font-medium whitespace-nowrap flex-shrink-0 hover:bg-[rgb(115,51,217)]/20 transition-colors"
              >
                {SORT_LABELS[sortOption]}
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            )}
            {filters.cuisines.map((c) => (
              <button
                key={c}
                onClick={() => removeCuisine(c)}
                className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-black/5 text-gray-700 text-xs font-medium whitespace-nowrap flex-shrink-0 hover:bg-black/10 transition-colors"
              >
                {getCuisineEmoji(c)} {getCuisineLabel(c)}
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            ))}
            {filters.neighborhoods.map((n) => (
              <button
                key={n}
                onClick={() => removeNeighborhood(n)}
                className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-black/5 text-gray-700 text-xs font-medium whitespace-nowrap flex-shrink-0 hover:bg-black/10 transition-colors"
              >
                {getNeighborhoodLabel(n)}
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            ))}
            {filters.priceRanges.map((p) => (
              <button
                key={p}
                onClick={() => removePrice(p)}
                className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-black/5 text-gray-700 text-xs font-medium whitespace-nowrap flex-shrink-0 hover:bg-black/10 transition-colors"
              >
                {getPriceLabel(p)}
                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Close sort dropdown on outside click */}
      {showSort && <div className="fixed inset-0 z-10" onClick={() => setShowSort(false)} />}

      {/* Results count */}
      <div className="px-4 py-2">
        <span className="text-xs text-gray-400">{filteredAndSorted.length} food spots</span>
      </div>

      {/* Restaurant grid/list */}
      <div className="flex-1 overflow-y-auto px-4 pb-24">
        {filteredAndSorted.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <span className="text-4xl mb-3">{"\ud83d\udd0d"}</span>
            <p className="text-gray-500 font-medium">No food spots found</p>
            <p className="text-gray-400 text-sm mt-1">Try adjusting your search or filters</p>
          </div>
        ) : viewMode === 1 ? (
          <div className="grid grid-cols-2 gap-3">
            {filteredAndSorted.map((r) => (
              <RestaurantCard key={r.id} restaurant={r} compact isFavorite={favorites.has(r.id)} onToggleFavorite={onToggleFavorite} onClick={onSelectRestaurant} />
            ))}
          </div>
        ) : viewMode === 2 ? (
          <div>
            {filteredAndSorted.map((r, index) => {
              const dist = getDistance(r);
              return (
                <button
                  key={r.id}
                  onClick={() => onSelectRestaurant(r)}
                  className={`flex items-center gap-3 py-3 w-full text-left ${index < filteredAndSorted.length - 1 ? "border-b border-black/5" : ""}`}
                >
                  {r.image_url ? (
                    <Image src={r.image_url} alt={r.name} width={80} height={80} className="w-20 h-20 rounded-xl object-cover flex-shrink-0" sizes="80px" />
                  ) : (
                    <div className="w-20 h-20 rounded-xl bg-black/5 flex items-center justify-center flex-shrink-0">
                      <span className="text-2xl">{getCuisineEmoji(r.cuisine_type)}</span>
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <h3 className="text-base font-bold truncate text-gray-900">{r.name}</h3>
                    <div className="flex items-center gap-1.5 mt-1">
                      <span className={`${getRatingBgClass(r.personal_rating)} ${getRatingTextClass(r.personal_rating)} px-2 py-0.5 rounded-full text-xs font-bold flex items-center gap-1`}>
                        <svg className="w-3 h-3 fill-current" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" /></svg>
                        {formatRating(r.personal_rating)}
                      </span>
                      {r.community_rating != null ? (
                        <span className="bg-[rgb(153,255,51)] text-black px-2 py-0.5 rounded-full text-xs font-bold flex items-center gap-1">
                          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" /></svg>
                          {formatRating(r.community_rating)}
                        </span>
                      ) : (
                        <span className="bg-gray-200 text-gray-400 px-2 py-0.5 rounded-full text-xs font-bold flex items-center gap-1">
                          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" /></svg>
                          &ndash;
                        </span>
                      )}
                      <span className="bg-gray-500 text-white px-2 py-0.5 rounded-full text-xs font-bold flex items-center gap-1">
                        <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" /></svg>
                        {formatRating(r.google_rating)}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500 truncate mt-1">
                      {getNeighborhoodLabel(r.neighborhood)} · {getCuisineEmoji(r.cuisine_type)} {getCuisineLabel(r.cuisine_type)} · {getPriceLabel(r.price_range)}
                      {dist != null && ` · ${formatDistance(dist)}`}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        ) : (
          <div className="space-y-3">
            {filteredAndSorted.map((r) => {
              const dist = getDistance(r);
              return (
                <RestaurantCard
                  key={r.id}
                  restaurant={r}
                  isFavorite={favorites.has(r.id)}
                  onToggleFavorite={onToggleFavorite}
                  onClick={onSelectRestaurant}
                  distanceText={dist != null ? formatDistance(dist) : undefined}
                />
              );
            })}
          </div>
        )}
      </div>

      {/* Filter Sheet */}
      <FilterSheet
        isOpen={showFilters}
        onClose={() => setShowFilters(false)}
        filters={filters}
        onFiltersChange={setFilters}
        filteredCount={filteredAndSorted.length}
      />
    </div>
  );
}
