"use client";

import { useState, useEffect, useCallback } from "react";
import { supabase } from "@/lib/supabase";
import { getDeviceId } from "@/lib/device-id";
import { getFavorites, saveFavorites } from "@/lib/utils";
import { RestaurantWithCommunity, CommunityRating } from "@/lib/types";
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
                restaurants={restaurants}
                favorites={favorites}
                onToggleFavorite={handleToggleFavorite}
                onSelectRestaurant={handleSelectRestaurant}
                userLocation={userLocation}
                onRequestLocation={handleRequestLocation}
              />
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
