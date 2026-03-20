"use client";

import { useState, useEffect, useCallback } from "react";
import { RestaurantWithCommunity } from "@/lib/types";
import {
  getRatingColor,
  getRatingBgClass,
  getRatingTextClass,
  getCuisineEmoji,
  getCuisineLabel,
  getPriceLabel,
  getNeighborhoodLabel,
  parseOpeningHours,
} from "@/lib/utils";
import { supabase } from "@/lib/supabase";
import { getDeviceId } from "@/lib/device-id";
import RatingBar from "./RatingBar";

interface RestaurantDetailProps {
  restaurant: RestaurantWithCommunity;
  isFavorite: boolean;
  onToggleFavorite: (id: string) => void;
  onClose: () => void;
  onRatingSubmitted: () => void;
}

export default function RestaurantDetail({
  restaurant,
  isFavorite,
  onToggleFavorite,
  onClose,
  onRatingSubmitted,
}: RestaurantDetailProps) {
  const [userRating, setUserRating] = useState<number>(
    restaurant.user_rating ?? 5
  );
  const [hasExistingRating, setHasExistingRating] = useState(
    restaurant.user_rating != null
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const openingHours = parseOpeningHours(restaurant.opening_hours);

  const handleSubmitRating = useCallback(async () => {
    const deviceId = getDeviceId();
    if (!deviceId) return;

    setIsSubmitting(true);
    try {
      const { error } = await supabase.from("user_ratings").upsert(
        {
          restaurant_id: restaurant.id,
          device_id: deviceId,
          rating: userRating,
        },
        { onConflict: "restaurant_id,device_id" }
      );

      if (error) {
        console.error("Error submitting rating:", error);
      } else {
        setSubmitSuccess(true);
        setHasExistingRating(true);
        setTimeout(() => setSubmitSuccess(false), 2000);
        onRatingSubmitted();
      }
    } catch (err) {
      console.error("Error submitting rating:", err);
    } finally {
      setIsSubmitting(false);
    }
  }, [restaurant.id, userRating, onRatingSubmitted]);

  // Reset submit success on rating change
  useEffect(() => {
    setSubmitSuccess(false);
  }, [userRating]);

  return (
    <div className="fixed inset-0 z-[70] flex flex-col bg-white">
      {/* Hero Image */}
      <div className="relative h-72 flex-shrink-0">
        {restaurant.image_url ? (
          <img
            src={restaurant.image_url}
            alt={restaurant.name}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gray-50 flex items-center justify-center">
            <span className="text-7xl">
              {getCuisineEmoji(restaurant.cuisine_type)}
            </span>
          </div>
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent" />

        {/* Back button */}
        <button
          onClick={onClose}
          className="absolute top-12 left-4 p-2 rounded-full bg-black/40 backdrop-blur-sm text-white hover:bg-black/60 transition-colors"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2.5}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M15.75 19.5L8.25 12l7.5-7.5"
            />
          </svg>
        </button>

        {/* Favorite button */}
        <button
          onClick={() => onToggleFavorite(restaurant.id)}
          className="absolute top-12 right-4 p-2 rounded-full bg-black/40 backdrop-blur-sm hover:bg-black/60 transition-colors"
        >
          <svg
            className={`w-5 h-5 transition-all duration-300 ${
              isFavorite
                ? "text-red-500 fill-red-500"
                : "text-white fill-transparent"
            }`}
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
            />
          </svg>
        </button>

        {/* Bottom info */}
        <div className="absolute bottom-4 left-4 right-4">
          <div className="flex items-center gap-2 mb-2">
            <span
              className={`${getRatingBgClass(restaurant.personal_rating)} ${getRatingTextClass(restaurant.personal_rating)} px-3 py-1 rounded-xl text-sm font-black`}
            >
              {restaurant.personal_rating?.toFixed(1) ?? "N/A"}
            </span>
            <span className="text-white/60 text-sm">
              {getCuisineEmoji(restaurant.cuisine_type)}{" "}
              {getCuisineLabel(restaurant.cuisine_type)}
            </span>
            <span className="text-white/30">·</span>
            <span className="text-white/60 text-sm font-semibold">
              {getPriceLabel(restaurant.price_range)}
            </span>
          </div>
          <h1 className="text-2xl font-black text-white">{restaurant.name}</h1>
        </div>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto pb-24">
        <div className="px-4 py-4 space-y-4">
          {/* Rating comparison card */}
          <div className="bg-black/5 rounded-2xl p-4 space-y-3">
            <h3 className="text-sm font-bold text-gray-600 uppercase tracking-wider">
              Ratings
            </h3>
            <RatingBar
              label="MAMPF Rating"
              value={restaurant.personal_rating}
              maxValue={10}
              icon={"\ud83c\udf1f"}
              color={getRatingColor(restaurant.personal_rating)}
              suffix="/10"
            />
            <RatingBar
              label="Google Rating"
              value={restaurant.google_rating}
              maxValue={5}
              icon={"\u2b50"}
              color="rgb(255, 191, 0)"
              suffix={
                restaurant.google_review_count
                  ? ` (${restaurant.google_review_count})`
                  : "/5"
              }
            />
            <RatingBar
              label="Community Rating"
              value={restaurant.community_rating}
              maxValue={10}
              icon={"\ud83d\udc65"}
              color="rgb(115, 51, 217)"
              suffix={
                restaurant.community_rating_count
                  ? ` (${restaurant.community_rating_count})`
                  : "/10"
              }
            />
          </div>

          {/* Your Rating */}
          <div className="bg-black/5 rounded-2xl p-4">
            <h3 className="text-sm font-bold text-gray-600 uppercase tracking-wider mb-3">
              Your Rating
            </h3>
            <div className="flex items-center gap-4">
              <span
                className="text-2xl font-black min-w-[3rem] text-center"
                style={{ color: getRatingColor(userRating) }}
              >
                {userRating.toFixed(1)}
              </span>
              <input
                type="range"
                min={1}
                max={10}
                step={0.5}
                value={userRating}
                onChange={(e) => setUserRating(parseFloat(e.target.value))}
                className="flex-1 accent-[rgb(115,51,217)] h-2"
              />
            </div>
            <button
              onClick={handleSubmitRating}
              disabled={isSubmitting}
              className={`w-full mt-3 py-2.5 rounded-xl font-bold text-sm transition-all duration-200 active:scale-[0.98] ${
                submitSuccess
                  ? "bg-[rgb(153,255,51)] text-gray-900"
                  : "bg-[rgb(115,51,217)] text-white hover:bg-[rgb(130,66,232)]"
              } disabled:opacity-50`}
            >
              {isSubmitting
                ? "Submitting..."
                : submitSuccess
                  ? "Submitted!"
                  : hasExistingRating
                    ? "Update Rating"
                    : "Submit Rating"}
            </button>
          </div>

          {/* Info card */}
          <div className="bg-black/5 rounded-2xl p-4 space-y-3">
            <h3 className="text-sm font-bold text-gray-600 uppercase tracking-wider">
              Info
            </h3>

            {/* Address */}
            {restaurant.address && (
              <div className="flex items-start gap-3">
                <svg
                  className="w-5 h-5 text-gray-400 flex-shrink-0 mt-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"
                  />
                </svg>
                <span className="text-sm text-gray-700">
                  {restaurant.address}
                </span>
              </div>
            )}

            {/* Neighborhood */}
            <div className="flex items-center gap-3">
              <svg
                className="w-5 h-5 text-gray-400 flex-shrink-0"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 0h.008v.008h-.008V7.5z"
                />
              </svg>
              <span className="text-sm text-gray-700">
                {getNeighborhoodLabel(restaurant.neighborhood)}
              </span>
            </div>

            {/* Opening hours */}
            {openingHours.length > 0 && (
              <div className="flex items-start gap-3">
                <svg
                  className="w-5 h-5 text-gray-400 flex-shrink-0 mt-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <div className="text-sm text-gray-700 space-y-0.5">
                  {openingHours.map((oh, i) => (
                    <div key={i} className="flex gap-2">
                      <span className="font-medium w-24 text-gray-500">
                        {oh.day}
                      </span>
                      <span>{oh.hours || "Closed"}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Status */}
            {restaurant.is_closed && (
              <div className="flex items-center gap-3">
                <svg
                  className="w-5 h-5 text-red-400 flex-shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
                  />
                </svg>
                <span className="text-sm font-medium text-red-400">
                  Permanently Closed
                </span>
              </div>
            )}
          </div>

          {/* Google Maps button */}
          {restaurant.google_maps_url && (
            <a
              href={restaurant.google_maps_url}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2 w-full py-3 rounded-2xl bg-black/5 hover:bg-black/5 transition-colors text-gray-900 font-semibold text-sm"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"
                />
              </svg>
              Open in Google Maps
            </a>
          )}

          {/* Mini map */}
          {restaurant.latitude && restaurant.longitude && (
            <div className="rounded-2xl overflow-hidden h-40">
              <DetailMiniMap
                lat={restaurant.latitude}
                lng={restaurant.longitude}
                name={restaurant.name}
              />
            </div>
          )}

          {/* Notes */}
          {restaurant.notes && (
            <div className="bg-black/5 rounded-2xl p-4">
              <h3 className="text-sm font-bold text-gray-600 uppercase tracking-wider mb-2">
                Notes
              </h3>
              <p className="text-sm text-gray-700">{restaurant.notes}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function DetailMiniMap({
  lat,
  lng,
  name,
}: {
  lat: number;
  lng: number;
  name: string;
}) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <div className="w-full h-full bg-black/5 flex items-center justify-center">
        <span className="text-gray-400 text-sm">Loading map...</span>
      </div>
    );
  }

  return <MiniMapInner lat={lat} lng={lng} name={name} />;
}

function MiniMapInner({
  lat,
  lng,
  name,
}: {
  lat: number;
  lng: number;
  name: string;
}) {
  const mapRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;

      import("leaflet").then((L) => {
        // Clean up any existing map
        const container = node;
        if ((container as unknown as Record<string, unknown>)._leaflet_id) {
          (container as unknown as Record<string, unknown>)._leaflet_id = undefined;
        }

        const map = L.map(container, {
          zoomControl: false,
          attributionControl: false,
          dragging: false,
          scrollWheelZoom: false,
          doubleClickZoom: false,
          touchZoom: false,
        }).setView([lat, lng], 15);

        L.tileLayer("https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png", {
          attribution: "",
        }).addTo(map);

        L.circleMarker([lat, lng], {
          radius: 8,
          fillColor: "rgb(115, 51, 217)",
          color: "white",
          weight: 2,
          opacity: 1,
          fillOpacity: 1,
        })
          .addTo(map)
          .bindPopup(name);
      });
    },
    [lat, lng, name]
  );

  return <div ref={mapRef} className="w-full h-full" />;
}
