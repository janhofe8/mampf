"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import Image from "next/image";
import { RestaurantWithCommunity } from "@/lib/types";
import {
  getRatingColor,
  getCuisineEmoji,
  getCuisineLabel,
  getPriceLabel,
  getNeighborhoodLabel,
  getRatingBgClass,
  getRatingTextClass,
  formatRating,
} from "@/lib/utils";
import HeartIcon from "./HeartIcon";
import type L from "leaflet";

const HAMBURG_CENTER: [number, number] = [53.5575, 9.962];
const DEFAULT_ZOOM = 13;

interface MapViewProps {
  restaurants: RestaurantWithCommunity[];
  favorites: Set<string>;
  onToggleFavorite: (id: string) => void;
  onSelectRestaurant: (restaurant: RestaurantWithCommunity) => void;
  userLocation: { lat: number; lng: number } | null;
}

export default function MapView({
  restaurants,
  favorites,
  onToggleFavorite,
  onSelectRestaurant,
  userLocation,
}: MapViewProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, L.CircleMarker>>(new Map());
  const userMarkerRef = useRef<L.CircleMarker | null>(null);
  const [selectedRestaurant, setSelectedRestaurant] =
    useState<RestaurantWithCommunity | null>(null);
  const [leafletLoaded, setLeafletLoaded] = useState(false);
  const leafletModuleRef = useRef<typeof L | null>(null);

  // Initialize map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    let cancelled = false;

    import("leaflet").then((LModule) => {
      if (cancelled || !mapContainerRef.current) return;
      const LLeaflet = LModule.default;
      leafletModuleRef.current = LLeaflet;

      // Clean up existing map instance if any
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }

      const map = LLeaflet.map(mapContainerRef.current, {
        zoomControl: false,
        attributionControl: false,
      }).setView(HAMBURG_CENTER, DEFAULT_ZOOM);

      LLeaflet.tileLayer(
        "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
        { attribution: "", maxZoom: 19 }
      ).addTo(map);

      // Add zoom control to bottom right
      LLeaflet.control.zoom({ position: "bottomright" }).addTo(map);

      mapRef.current = map;
      setLeafletLoaded(true);
    });

    return () => {
      cancelled = true;
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  // Add restaurant markers (diff-based: only add/remove changed markers)
  useEffect(() => {
    if (!leafletLoaded || !mapRef.current || !leafletModuleRef.current) return;
    const LLeaflet = leafletModuleRef.current;
    const map = mapRef.current;

    const createMarker = (restaurant: RestaurantWithCommunity, zoom: number) => {
      if (!restaurant.latitude || !restaurant.longitude) return null;
      const color = getRatingColor(restaurant.personal_rating);
      const showLabel = zoom >= 14;

      const marker = LLeaflet.circleMarker(
        [restaurant.latitude, restaurant.longitude],
        {
          radius: showLabel ? 14 : 8,
          fillColor: color,
          color: "rgba(0,0,0,0.3)",
          weight: 1,
          opacity: 1,
          fillOpacity: 0.9,
        }
      ).addTo(map);

      if (showLabel && restaurant.personal_rating != null) {
        marker.bindTooltip(formatRating(restaurant.personal_rating), {
          permanent: true,
          direction: "center",
          className: "rating-tooltip",
        });
      }

      marker.on("click", () => {
        setSelectedRestaurant(restaurant);
      });

      return marker;
    };

    // Diff: only add/remove changed markers
    const currentIds = new Set(restaurants.map((r) => r.id));
    const zoom = map.getZoom();

    // Remove markers no longer in the list
    for (const [id, marker] of markersRef.current) {
      if (!currentIds.has(id)) {
        marker.remove();
        markersRef.current.delete(id);
      }
    }

    // Add markers for new restaurants
    for (const restaurant of restaurants) {
      if (!markersRef.current.has(restaurant.id)) {
        const marker = createMarker(restaurant, zoom);
        if (marker) {
          markersRef.current.set(restaurant.id, marker);
        }
      }
    }

    // Rebuild all on zoom (radius/tooltip changes)
    const onZoom = () => {
      const newZoom = map.getZoom();
      for (const [, m] of markersRef.current) {
        m.remove();
      }
      markersRef.current.clear();

      for (const restaurant of restaurants) {
        const marker = createMarker(restaurant, newZoom);
        if (marker) {
          markersRef.current.set(restaurant.id, marker);
        }
      }
    };

    map.on("zoomend", onZoom);

    return () => {
      map.off("zoomend", onZoom);
    };
  }, [leafletLoaded, restaurants]);

  // Update user location marker
  useEffect(() => {
    if (!leafletLoaded || !mapRef.current || !leafletModuleRef.current) return;
    const LLeaflet = leafletModuleRef.current;

    if (userMarkerRef.current) {
      const pulse = (userMarkerRef.current as unknown as Record<string, L.CircleMarker>)._pulseMarker;
      if (pulse) pulse.remove();
      userMarkerRef.current.remove();
      userMarkerRef.current = null;
    }

    if (userLocation) {
      // Pulsing outer ring
      const pulse = LLeaflet.circleMarker(
        [userLocation.lat, userLocation.lng],
        {
          radius: 16,
          fillColor: "#007AFF",
          color: "transparent",
          weight: 0,
          fillOpacity: 0.15,
          className: "user-location-pulse",
        }
      ).addTo(mapRef.current);

      // Solid inner dot
      const marker = LLeaflet.circleMarker(
        [userLocation.lat, userLocation.lng],
        {
          radius: 6,
          fillColor: "#007AFF",
          color: "white",
          weight: 2.5,
          opacity: 1,
          fillOpacity: 1,
        }
      ).addTo(mapRef.current);

      userMarkerRef.current = marker;
      // Store pulse ref on marker for cleanup
      (marker as unknown as Record<string, L.CircleMarker>)._pulseMarker = pulse;
    }
  }, [leafletLoaded, userLocation]);

  const isFav = selectedRestaurant
    ? favorites.has(selectedRestaurant.id)
    : false;

  return (
    <div className="relative h-full w-full">
      {/* Map container */}
      <div ref={mapContainerRef} className="absolute inset-0 z-0" />

      {/* Selected restaurant card */}
      {selectedRestaurant && (
        <div className="absolute bottom-4 left-4 right-4 z-10 animate-slide-up">
          <div className="bg-white/95 backdrop-blur-xl rounded-2xl overflow-hidden shadow-2xl border border-black/10">
            <button
              onClick={() => onSelectRestaurant(selectedRestaurant)}
              className="w-full text-left"
            >
              <div className="flex gap-3 p-3">
                {/* Image */}
                <div className="w-20 h-20 rounded-xl overflow-hidden flex-shrink-0">
                  {selectedRestaurant.image_url ? (
                    <Image
                      src={selectedRestaurant.image_url}
                      alt={selectedRestaurant.name}
                      width={80}
                      height={80}
                      className="w-full h-full object-cover"
                      sizes="80px"
                    />
                  ) : (
                    <div className="w-full h-full bg-black/5 flex items-center justify-center">
                      <span className="text-2xl">
                        {getCuisineEmoji(selectedRestaurant.cuisine_type)}
                      </span>
                    </div>
                  )}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="text-base font-bold text-gray-900 truncate">
                      {selectedRestaurant.name}
                    </h3>
                    <span
                      className={`${getRatingBgClass(selectedRestaurant.personal_rating)} ${getRatingTextClass(selectedRestaurant.personal_rating)} px-2 py-0.5 rounded-lg text-xs font-black flex-shrink-0`}
                    >
                      {formatRating(selectedRestaurant.personal_rating)}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5">
                    {getCuisineEmoji(selectedRestaurant.cuisine_type)}{" "}
                    {getCuisineLabel(selectedRestaurant.cuisine_type)} ·{" "}
                    {getNeighborhoodLabel(selectedRestaurant.neighborhood)}
                  </p>
                  <p className="text-xs text-gray-400 mt-0.5">
                    {getPriceLabel(selectedRestaurant.price_range)}
                    {selectedRestaurant.google_rating != null &&
                      ` · Google ${formatRating(selectedRestaurant.google_rating)}`}
                  </p>
                </div>
              </div>
            </button>

            {/* Bottom actions */}
            <div className="flex border-t border-black/5">
              <button
                onClick={() => onToggleFavorite(selectedRestaurant.id)}
                className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-medium hover:bg-black/5 transition-colors"
              >
                <HeartIcon filled={isFav} className={`w-4 h-4 ${!isFav ? "text-gray-400 fill-transparent" : ""}`} />
                <span className={isFav ? "text-red-400" : "text-gray-400"}>
                  {isFav ? "Saved" : "Save"}
                </span>
              </button>
              <div className="w-px bg-black/5" />
              <button
                onClick={() => setSelectedRestaurant(null)}
                className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-medium text-gray-400 hover:bg-black/5 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
