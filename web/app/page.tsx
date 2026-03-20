"use client";

import { useState, useEffect, useCallback } from "react";
import { supabase } from "@/lib/supabase";
import { getDeviceId } from "@/lib/device-id";
import { getFavorites, saveFavorites } from "@/lib/utils";
import { RestaurantWithCommunity, CommunityRating, CUISINE_TYPES, PRICE_LABELS } from "@/lib/types";
import BottomTabs, { TabId } from "@/components/BottomTabs";
import MapView from "@/components/MapView";
import RestaurantList from "@/components/RestaurantList";
import FavoritesView from "@/components/FavoritesView";
import RestaurantDetail from "@/components/RestaurantDetail";

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
  const [showMapFilter, setShowMapFilter] = useState(false);
  const [mapMinRating, setMapMinRating] = useState(0);
  const [mapCuisines, setMapCuisines] = useState<Set<string>>(new Set());
  const [mapPrices, setMapPrices] = useState<Set<string>>(new Set());

  const mapFilteredRestaurants = restaurants.filter((r) => {
    if (mapMinRating > 0 && (r.personal_rating ?? 0) < mapMinRating) return false;
    if (mapCuisines.size > 0 && !mapCuisines.has(r.cuisine_type)) return false;
    if (mapPrices.size > 0 && !mapPrices.has(r.price_range)) return false;
    return true;
  });

  const mapHasFilters = mapMinRating > 0 || mapCuisines.size > 0 || mapPrices.size > 0;

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
          <div className="flex items-center justify-center h-full">
            <div className="flex flex-col items-center gap-3">
              <div className="w-10 h-10 border-2 border-[rgb(115,51,217)] border-t-transparent rounded-full animate-spin" />
              <span className="text-gray-400 text-sm">
                Loading restaurants...
              </span>
            </div>
          </div>
        ) : (
          <>
            <div
              className={`absolute inset-0 transition-opacity duration-200 ${
                activeTab === "map"
                  ? "opacity-100 z-10 pointer-events-auto"
                  : "opacity-0 z-0 pointer-events-none"
              }`}
            >
              <MapView
                restaurants={mapFilteredRestaurants}
                favorites={favorites}
                onToggleFavorite={handleToggleFavorite}
                onSelectRestaurant={handleSelectRestaurant}
                userLocation={userLocation}
                onRequestLocation={handleRequestLocation}
              />
              {/* Map filter button */}
              <div className="absolute top-4 left-4 z-20">
                <button
                  onClick={() => setShowMapFilter((v) => !v)}
                  className={`p-3 rounded-full shadow-lg transition-colors ${mapHasFilters ? "bg-[rgb(115,51,217)] text-white" : "bg-white/90 text-gray-900 backdrop-blur-sm"}`}
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 11-3 0m3 0a1.5 1.5 0 10-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m-9.75 0h9.75" />
                  </svg>
                </button>
                {showMapFilter && (
                  <div className="absolute top-14 left-0 w-72 bg-white rounded-2xl shadow-2xl border border-black/10 p-4 space-y-4 animate-fade-in">
                    {/* Rating */}
                    <div>
                      <p className="text-xs font-semibold text-gray-500 mb-2">Minimum Rating</p>
                      <div className="flex gap-1.5">
                        {([0, 7, 8, 9] as const).map((min) => (
                          <button key={min} onClick={() => setMapMinRating(mapMinRating === min ? 0 : min)}
                            className={`flex-1 py-1.5 rounded-lg text-xs font-bold transition-colors ${mapMinRating === min && min > 0 ? "bg-[rgb(115,51,217)] text-white" : "bg-black/5 text-gray-600"}`}>
                            {min === 0 ? "All" : `★ ${min}+`}
                          </button>
                        ))}
                      </div>
                    </div>
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
                    {/* Actions */}
                    <div className="flex gap-2 pt-1">
                      {mapHasFilters && (
                        <button onClick={() => { setMapMinRating(0); setMapCuisines(new Set()); setMapPrices(new Set()); }}
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
              />
            </div>

            <div
              className={`absolute inset-0 transition-opacity duration-200 ${
                activeTab === "favorites"
                  ? "opacity-100 z-10 pointer-events-auto"
                  : "opacity-0 z-0 pointer-events-none"
              }`}
            >
              <FavoritesView
                restaurants={restaurants}
                favorites={favorites}
                onToggleFavorite={handleToggleFavorite}
                onSelectRestaurant={handleSelectRestaurant}
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
