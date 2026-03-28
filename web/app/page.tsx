"use client";

import { useState, useEffect, useCallback, useMemo, useDeferredValue } from "react";
import { supabase } from "@/lib/supabase";
import { getDeviceId } from "@/lib/device-id";
import { getFavorites, saveFavorites, getNeighborhoodLabel, filterRestaurants } from "@/lib/utils";
import { RestaurantWithCommunity, CommunityRating, CUISINE_TYPES, PRICE_LABELS, NEIGHBORHOODS } from "@/lib/types";
import BottomTabs, { TabId } from "@/components/BottomTabs";
import MapView from "@/components/MapView";
import RestaurantList from "@/components/RestaurantList";
import RestaurantDetail from "@/components/RestaurantDetail";
import RatingHistogram from "@/components/RatingHistogram";

export default function Home() {
  const [activeTab, setActiveTab] = useState<TabId>("map");
  const [restaurants, setRestaurants] = useState<RestaurantWithCommunity[]>([]);
  const [loading, setLoading] = useState(true);
  const [favorites, setFavorites] = useState<Set<string>>(new Set());
  const [selectedRestaurant, setSelectedRestaurant] =
    useState<RestaurantWithCommunity | null>(null);
  const [userLocation, setUserLocation] = useState<{
    lat: number;
    lng: number;
  } | null>(null);
  const [showFavoritesOnly, setShowFavoritesOnly] = useState(false);
  const [showMapFilter, setShowMapFilter] = useState(false);
  const [mapMinRating, setMapMinRating] = useState(0);
  const [mapCuisines, setMapCuisines] = useState<Set<string>>(new Set());
  const [mapPrices, setMapPrices] = useState<Set<string>>(new Set());
  const [mapNeighborhoods, setMapNeighborhoods] = useState<Set<string>>(new Set());
  const [mapSearch, setMapSearch] = useState("");
  const deferredMapSearch = useDeferredValue(mapSearch);
  const [showMapSearch, setShowMapSearch] = useState(false);
  const [showRatingHistogram, setShowRatingHistogram] = useState(false);

  const mapFilteredRestaurants = useMemo(() => filterRestaurants(restaurants, {
    search: deferredMapSearch,
    cuisines: mapCuisines,
    priceRanges: mapPrices,
    neighborhoods: mapNeighborhoods,
    minRating: mapMinRating,
  }), [restaurants, mapMinRating, mapCuisines, mapPrices, mapNeighborhoods, deferredMapSearch]);

  const mapHasFilters = mapMinRating > 0 || mapCuisines.size > 0 || mapPrices.size > 0 || mapNeighborhoods.size > 0;

  // Build histogram buckets for rating filter
  const ratingBuckets = useMemo(() => {
    // Find the lowest rating (floored to nearest 0.5)
    const ratings = restaurants
      .map((r) => r.personal_rating)
      .filter((r): r is number => r != null);
    if (ratings.length === 0) return [];
    const minRating = Math.floor(Math.min(...ratings) * 2) / 2;
    const buckets: { rating: number; count: number }[] = [];
    for (let r = minRating; r <= 10; r += 0.5) {
      const rounded = Math.round(r * 10) / 10;
      const count = restaurants.filter((rest) => {
        const pr = rest.personal_rating;
        if (pr == null) return false;
        return pr >= rounded && pr < rounded + 0.5;
      }).length;
      buckets.push({ rating: rounded, count });
    }
    return buckets;
  }, [restaurants]);

  // Load favorites from localStorage
  useEffect(() => {
    setFavorites(getFavorites());
  }, []);

  // Fetch restaurants and community ratings
  const fetchData = useCallback(async () => {
    try {
      const [restaurantsRes, communityRes, userRatingsRes] = await Promise.all([
        supabase
          .from("restaurants")
          .select("*")
          .order("personal_rating", { ascending: false }),
        supabase.from("restaurant_community_ratings").select("*"),
        (() => {
          const deviceId = getDeviceId();
          if (!deviceId) return Promise.resolve({ data: [], error: null });
          return supabase
            .from("user_ratings")
            .select("*")
            .eq("device_id", deviceId);
        })(),
      ]);

      if (restaurantsRes.error) {
        console.error("Error fetching restaurants:", restaurantsRes.error);
        return;
      }

      const communityMap = new Map<string, CommunityRating>();
      if (communityRes.data) {
        communityRes.data.forEach((cr: CommunityRating) => {
          communityMap.set(cr.restaurant_id, cr);
        });
      }

      const userRatingMap = new Map<string, number>();
      if (userRatingsRes.data) {
        (userRatingsRes.data as { restaurant_id: string; rating: number }[]).forEach((ur) => {
          userRatingMap.set(ur.restaurant_id, ur.rating);
        });
      }

      const merged: RestaurantWithCommunity[] = (restaurantsRes.data || []).map(
        (r) => ({
          ...r,
          community_rating: communityMap.get(r.id)?.community_rating ?? null,
          community_rating_count:
            communityMap.get(r.id)?.community_rating_count ?? null,
          user_rating: userRatingMap.get(r.id) ?? null,
        })
      );

      setRestaurants(merged);
    } catch (err) {
      console.error("Error fetching data:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Toggle favorite
  const handleToggleFavorite = useCallback(
    (restaurantId: string) => {
      setFavorites((prev) => {
        const next = new Set(prev);
        if (next.has(restaurantId)) {
          next.delete(restaurantId);
        } else {
          next.add(restaurantId);
        }
        saveFavorites(next);
        return next;
      });
    },
    []
  );

  // Select restaurant
  const handleSelectRestaurant = useCallback(
    (restaurant: RestaurantWithCommunity) => {
      setSelectedRestaurant(restaurant);
    },
    []
  );

  // Request user location
  const handleRequestLocation = useCallback(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setUserLocation({
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          });
        },
        (err) => {
          console.warn("Geolocation error:", err);
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    }
  }, []);

  // Try to get location on mount
  useEffect(() => {
    handleRequestLocation();
  }, [handleRequestLocation]);

  // Refresh data after rating submitted
  const handleRatingSubmitted = useCallback(() => {
    fetchData();
  }, [fetchData]);

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <header className="flex-shrink-0 bg-white border-b border-black/10 safe-area-top z-30">
        <div className="flex items-center justify-between px-4 h-12">
          <h1 className="text-lg font-black tracking-tight">
            <span className="text-[rgb(115,51,217)]">MAMPF</span>
          </h1>
          <span className="text-xs text-black/30 font-medium">Hamburg</span>
        </div>
      </header>

      {/* Main content */}
      <main className="flex-1 relative overflow-hidden">
        {loading ? (
          <div className="p-4 space-y-4 overflow-hidden">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="relative rounded-2xl overflow-hidden bg-black/5 aspect-[16/9] shimmer">
                <div className="absolute bottom-4 left-4 right-4 space-y-2">
                  <div className="h-5 w-48 rounded bg-black/10" />
                  <div className="h-4 w-64 rounded bg-black/10" />
                </div>
                <div className="absolute top-3 left-3 flex gap-2">
                  <div className="h-7 w-14 rounded-xl bg-black/10" />
                  <div className="h-7 w-14 rounded-xl bg-black/10" />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <>
            <div
              className={`absolute inset-0 transition-opacity duration-200 ${
                activeTab === "map"
                  ? "opacity-100 z-10 pointer-events-auto"
                  : "opacity-0 z-0 pointer-events-none"
              }`}
              onClick={(e) => {
                // Tap to close overlays when clicking on the map area (not on buttons/overlays)
                if (e.target === e.currentTarget) {
                  setShowMapSearch(false);
                  setShowRatingHistogram(false);
                  setShowMapFilter(false);
                }
              }}
            >
              <MapView
                restaurants={mapFilteredRestaurants}
                favorites={favorites}
                onToggleFavorite={handleToggleFavorite}
                onSelectRestaurant={handleSelectRestaurant}
                userLocation={userLocation}
              />

              {/* Search overlay at top of map */}
              {showMapSearch && (
                <div className="absolute top-4 left-4 right-16 z-20 animate-fade-in">
                  <div className="bg-white/90 backdrop-blur-md rounded-2xl shadow-lg flex items-center px-3 py-2 gap-2">
                    <svg className="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                    </svg>
                    <input
                      type="text"
                      value={mapSearch}
                      onChange={(e) => setMapSearch(e.target.value)}
                      placeholder="Search restaurants..."
                      autoFocus
                      className="flex-1 bg-transparent text-sm text-gray-900 placeholder-gray-400 outline-none"
                    />
                    {mapSearch && (
                      <button onClick={() => setMapSearch("")} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    )}
                  </div>
                </div>
              )}

              {/* Map filter button — top left (cuisine/price only) */}
              <div className="absolute top-4 left-4 z-20" style={showMapSearch ? { visibility: "hidden" } : undefined}>
                <button
                  onClick={() => { setShowMapFilter((v) => !v); setShowRatingHistogram(false); setShowMapSearch(false); }}
                  className={`p-3 rounded-full shadow-lg transition-colors ${mapCuisines.size > 0 || mapPrices.size > 0 || mapNeighborhoods.size > 0 ? "bg-[rgb(115,51,217)] text-white" : "bg-white/90 text-gray-900 backdrop-blur-sm"}`}
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75" />
                  </svg>
                </button>
                {showMapFilter && (
                  <div className="absolute top-14 left-0 w-72 bg-white rounded-2xl shadow-2xl border border-black/10 p-4 space-y-4 animate-fade-in">
                    {/* Cuisine */}
                    <div>
                      <p className="text-xs font-semibold text-gray-500 mb-2">Cuisine</p>
                      <div className="flex flex-wrap gap-1.5">
                        {Object.entries(CUISINE_TYPES).map(([key, emoji]) => {
                          const active = mapCuisines.has(key);
                          return (
                            <button key={key} onClick={() => { const n = new Set(mapCuisines); active ? n.delete(key) : n.add(key); setMapCuisines(n); }}
                              className={`px-2 py-1 rounded-lg text-[10px] font-bold transition-colors ${active ? "bg-[rgb(115,51,217)] text-white" : "bg-black/5 text-gray-600"}`}>
                              {emoji} {key.charAt(0).toUpperCase() + key.slice(1)}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                    {/* Price */}
                    <div>
                      <p className="text-xs font-semibold text-gray-500 mb-2">Price Range</p>
                      <div className="flex gap-1.5">
                        {Object.entries(PRICE_LABELS).map(([key, label]) => {
                          const active = mapPrices.has(key);
                          return (
                            <button key={key} onClick={() => { const n = new Set(mapPrices); active ? n.delete(key) : n.add(key); setMapPrices(n); }}
                              className={`flex-1 py-1.5 rounded-lg text-xs font-bold transition-colors ${active ? "bg-[rgb(115,51,217)] text-white" : "bg-black/5 text-gray-600"}`}>
                              {label}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                    {/* Neighborhood */}
                    <div>
                      <p className="text-xs font-semibold text-gray-500 mb-2">Neighborhood</p>
                      <div className="flex flex-wrap gap-1.5">
                        {NEIGHBORHOODS.map((key) => {
                          const active = mapNeighborhoods.has(key);
                          return (
                            <button key={key} onClick={() => { const n = new Set(mapNeighborhoods); active ? n.delete(key) : n.add(key); setMapNeighborhoods(n); }}
                              className={`px-2 py-1 rounded-lg text-[10px] font-bold transition-colors ${active ? "bg-[rgb(115,51,217)] text-white" : "bg-black/5 text-gray-600"}`}>
                              {getNeighborhoodLabel(key)}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                    {/* Actions */}
                    <div className="flex gap-2 pt-1">
                      {(mapCuisines.size > 0 || mapPrices.size > 0 || mapNeighborhoods.size > 0) && (
                        <button onClick={() => { setMapCuisines(new Set()); setMapPrices(new Set()); setMapNeighborhoods(new Set()); }}
                          className="flex-1 py-2 rounded-lg text-xs font-medium text-gray-500 bg-black/5">
                          Reset
                        </button>
                      )}
                      <button onClick={() => setShowMapFilter(false)}
                        className="flex-1 py-2 rounded-lg text-xs font-bold text-white bg-[rgb(115,51,217)]">
                        Done
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {/* Right side buttons — search + star + locate */}
              <div className="absolute top-4 right-4 z-20 flex flex-col gap-2">
                {/* Search button */}
                <button
                  onClick={() => { setShowMapSearch((v) => !v); setShowRatingHistogram(false); setShowMapFilter(false); }}
                  className={`p-3 rounded-full shadow-lg transition-colors ${showMapSearch || mapSearch ? "bg-[rgb(115,51,217)] text-white" : "bg-white/90 text-gray-900 backdrop-blur-sm"}`}
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                  </svg>
                </button>
                {/* Rating histogram button */}
                <button
                  onClick={() => { setShowRatingHistogram((v) => !v); setShowMapSearch(false); setShowMapFilter(false); }}
                  className={`p-3 rounded-full shadow-lg transition-colors ${showRatingHistogram || mapMinRating > 0 ? "bg-[rgb(115,51,217)] text-white" : "bg-white/90 text-gray-900 backdrop-blur-sm"}`}
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                  </svg>
                </button>
                {/* Locate me button */}
                <button
                  onClick={handleRequestLocation}
                  className="p-3 rounded-full shadow-lg bg-white/90 text-gray-900 backdrop-blur-sm hover:bg-gray-100 transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                  </svg>
                </button>
              </div>

              {/* Rating histogram overlay at bottom of map */}
              {showRatingHistogram && (
                <div className="absolute bottom-4 left-4 right-4 z-20 animate-slide-up">
                  <RatingHistogram
                    buckets={ratingBuckets}
                    minRating={mapMinRating}
                    onMinRatingChange={setMapMinRating}
                    filteredCount={mapFilteredRestaurants.length}
                    onClose={() => setShowRatingHistogram(false)}
                  />
                </div>
              )}
            </div>

            <div
              className={`absolute inset-0 transition-opacity duration-200 ${
                activeTab === "list"
                  ? "opacity-100 z-10 pointer-events-auto"
                  : "opacity-0 z-0 pointer-events-none"
              }`}
            >
              <RestaurantList
                restaurants={restaurants}
                favorites={favorites}
                onToggleFavorite={handleToggleFavorite}
                onSelectRestaurant={handleSelectRestaurant}
                userLocation={userLocation}
                showFavoritesOnly={showFavoritesOnly}
                onToggleFavoritesOnly={() => setShowFavoritesOnly((v) => !v)}
              />
            </div>

          </>
        )}
      </main>

      {/* Bottom tabs */}
      <BottomTabs activeTab={activeTab} onTabChange={setActiveTab} />

      {/* Restaurant detail overlay */}
      {selectedRestaurant && (
        <RestaurantDetail
          restaurant={selectedRestaurant}
          isFavorite={favorites.has(selectedRestaurant.id)}
          onToggleFavorite={handleToggleFavorite}
          onClose={() => setSelectedRestaurant(null)}
          onRatingSubmitted={handleRatingSubmitted}
        />
      )}
    </div>
  );
}
