"use client";

import { memo } from "react";
import Image from "next/image";
import { RestaurantWithCommunity } from "@/lib/types";
import {
  getRatingBgClass,
  getRatingTextClass,
  getCuisineEmoji,
  getCuisineLabel,
  getPriceLabel,
  getNeighborhoodLabel,
  formatRating,
} from "@/lib/utils";
import HeartIcon from "./HeartIcon";

interface RestaurantCardProps {
  restaurant: RestaurantWithCommunity;
  compact?: boolean;
  isFavorite: boolean;
  onToggleFavorite: (id: string) => void;
  onClick: (restaurant: RestaurantWithCommunity) => void;
  distanceText?: string;
}

const RestaurantCard = memo(function RestaurantCard(props: RestaurantCardProps) {
  if (props.compact) {
    return <CompactCard {...props} />;
  }
  return <LargeCard {...props} />;
});

export default RestaurantCard;

// --- Compact card (grid view) ---

function CompactCard({
  restaurant,
  isFavorite,
  onToggleFavorite,
  onClick,
}: RestaurantCardProps) {
  const ratingBg = getRatingBgClass(restaurant.personal_rating);
  const ratingText = getRatingTextClass(restaurant.personal_rating);

  return (
    <button
      onClick={() => onClick(restaurant)}
      className="relative rounded-2xl overflow-hidden bg-black/5 hover:bg-black/5 transition-all duration-200 group active:scale-[0.97] text-left"
    >
      <div className="relative aspect-[4/3] overflow-hidden">
        <CardImage
          url={restaurant.image_url}
          alt={restaurant.name}
          emoji={getCuisineEmoji(restaurant.cuisine_type)}
          sizes="(max-width: 768px) 50vw, 200px"
          emojiSize="text-3xl"
        />
        {/* Rating pills */}
        <div className="absolute top-2 left-2 flex flex-row gap-1">
          <div
            className={`${ratingBg} ${ratingText} min-w-[44px] text-center px-1.5 py-0.5 rounded-lg text-[10px] font-bold`}
          >
            ★ {formatRating(restaurant.personal_rating)}
          </div>
          {restaurant.community_rating != null && (
            <div className="bg-black/40 text-white min-w-[44px] text-center px-1.5 py-0.5 rounded-lg text-[10px] font-bold">
              👥 {formatRating(restaurant.community_rating)}
            </div>
          )}
          {restaurant.google_rating != null && (
            <div className="bg-black/40 text-white min-w-[44px] text-center px-1.5 py-0.5 rounded-lg text-[10px] font-bold">
              🌐 {formatRating(restaurant.google_rating)}
            </div>
          )}
        </div>
        <button
          onClick={(e) => {
            e.stopPropagation();
            onToggleFavorite(restaurant.id);
          }}
          className="absolute top-2 right-2 p-1"
        >
          <HeartIcon
            filled={isFavorite}
            className={`w-5 h-5 ${!isFavorite ? "text-white/80 fill-transparent" : ""}`}
          />
        </button>
      </div>
      <div className="p-2">
        <div className="flex items-center gap-1.5">
          <h3 className="text-sm font-bold text-gray-900 truncate">
            {restaurant.name}
          </h3>
          {restaurant.is_closed && (
            <span className="bg-red-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full flex-shrink-0">
              Closed
            </span>
          )}
        </div>
        <p className="text-xs text-gray-500 truncate">
          {getCuisineEmoji(restaurant.cuisine_type)}{" "}
          {getCuisineLabel(restaurant.cuisine_type)} ·{" "}
          {getPriceLabel(restaurant.price_range)}
        </p>
      </div>
    </button>
  );
}

// --- Large card (cards view) ---

function LargeCard(props: RestaurantCardProps) {
  const { restaurant, isFavorite, onToggleFavorite, onClick } = props;
  const ratingBg = getRatingBgClass(restaurant.personal_rating);
  const ratingText = getRatingTextClass(restaurant.personal_rating);

  return (
    <button
      onClick={() => onClick(restaurant)}
      className="relative rounded-2xl overflow-hidden bg-black/5 hover:bg-black/5 transition-all duration-200 group active:scale-[0.98] text-left w-full"
    >
      <div className="relative aspect-[16/9] overflow-hidden">
        <CardImage
          url={restaurant.image_url}
          alt={restaurant.name}
          emoji={getCuisineEmoji(restaurant.cuisine_type)}
          sizes="(max-width: 768px) 100vw, 600px"
          emojiSize="text-5xl"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

        {/* Rating pills */}
        <div className="absolute top-3 left-3 flex gap-2">
          <div
            className={`${ratingBg} ${ratingText} px-3 py-1 rounded-xl text-sm font-black`}
          >
            {formatRating(restaurant.personal_rating)}
          </div>
          {restaurant.community_rating != null && (
            <div className="bg-white/90 text-gray-900 px-2 py-1 rounded-xl text-xs font-bold flex items-center gap-1">
              <svg
                className="w-3 h-3 text-[rgb(115,51,217)]"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                />
              </svg>
              {formatRating(restaurant.community_rating)}
            </div>
          )}
          {restaurant.google_rating != null && (
            <div className="bg-white/90 text-gray-900 px-2 py-1 rounded-xl text-xs font-bold flex items-center gap-1">
              <svg
                className="w-3 h-3 text-amber-500 fill-amber-500"
                viewBox="0 0 20 20"
              >
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
              {formatRating(restaurant.google_rating)}
            </div>
          )}
        </div>

        <button
          onClick={(e) => {
            e.stopPropagation();
            onToggleFavorite(restaurant.id);
          }}
          className="absolute top-3 right-3 p-1.5 rounded-full bg-black/30 backdrop-blur-sm hover:bg-black/50 transition-colors"
        >
          <HeartIcon
            filled={isFavorite}
            className={`w-5 h-5 ${isFavorite ? "scale-110" : ""}`}
          />
        </button>

        <div className="absolute bottom-0 left-0 right-0 p-4">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-lg font-black text-white">
              {restaurant.name}
            </h3>
            {restaurant.is_closed && (
              <span className="bg-red-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full flex-shrink-0">
                Closed
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 text-sm text-white/80">
            <span>
              {getCuisineEmoji(restaurant.cuisine_type)}{" "}
              {getCuisineLabel(restaurant.cuisine_type)}
            </span>
            <span className="text-white/40">·</span>
            <span>{getNeighborhoodLabel(restaurant.neighborhood)}</span>
            <span className="text-white/40">·</span>
            <span className="font-semibold">
              {getPriceLabel(restaurant.price_range)}
            </span>
            {props.distanceText && (
              <>
                <span className="text-white/40">·</span>
                <span>{props.distanceText}</span>
              </>
            )}
          </div>
        </div>
      </div>
    </button>
  );
}

// --- Shared image component ---

function CardImage({
  url,
  alt,
  emoji,
  sizes,
  emojiSize,
}: {
  url: string | null;
  alt: string;
  emoji: string;
  sizes: string;
  emojiSize: string;
}) {
  if (url) {
    return (
      <Image
        src={url}
        alt={alt}
        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
        fill
        sizes={sizes}
      />
    );
  }
  return (
    <div className="w-full h-full bg-black/5 flex items-center justify-center">
      <span className={emojiSize}>{emoji}</span>
    </div>
  );
}
