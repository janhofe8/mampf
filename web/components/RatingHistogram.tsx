"use client";

import { getRatingColor, formatRating } from "@/lib/utils";

interface RatingBucket {
  rating: number;
  count: number;
}

interface RatingHistogramProps {
  buckets: RatingBucket[];
  minRating: number;
  onMinRatingChange: (value: number) => void;
  filteredCount: number;
  onClose: () => void;
}

export default function RatingHistogram({
  buckets,
  minRating,
  onMinRatingChange,
  filteredCount,
  onClose,
}: RatingHistogramProps) {
  const maxCount = Math.max(...buckets.map((b) => b.count), 1);

  return (
    <div className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-2xl p-5">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <p className="text-xs font-semibold text-gray-500">Min. Rating</p>
          <p
            className="text-2xl font-black"
            style={{
              color:
                minRating > 0
                  ? getRatingColor(minRating)
                  : "rgb(38,38,46)",
            }}
          >
            {minRating > 0 ? formatRating(minRating) : "All"}
          </p>
        </div>
        <button
          onClick={onClose}
          className="p-2 rounded-full hover:bg-black/5 text-gray-400"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>

      {/* Histogram */}
      <div className="space-y-1 mb-4">
        {buckets.map((bucket) => {
          const belowMin = minRating > 0 && bucket.rating < minRating;
          const barColor = belowMin
            ? "rgb(209,213,219)"
            : getRatingColor(bucket.rating);
          const widthPct =
            bucket.count > 0
              ? Math.max((bucket.count / maxCount) * 100, 4)
              : 0;
          return (
            <div key={bucket.rating} className="flex items-center gap-2">
              <span
                className={`text-[10px] font-semibold w-7 text-right ${
                  belowMin ? "text-gray-300" : "text-gray-500"
                }`}
              >
                {bucket.rating.toFixed(1)}
              </span>
              <div className="flex-1 h-4 bg-black/5 rounded-sm overflow-hidden">
                {bucket.count > 0 && (
                  <div
                    className="h-full rounded-sm transition-all"
                    style={{
                      width: `${widthPct}%`,
                      backgroundColor: barColor,
                    }}
                  />
                )}
              </div>
              <span
                className={`text-[10px] font-medium w-4 ${
                  belowMin ? "text-gray-300" : "text-gray-500"
                }`}
              >
                {bucket.count}
              </span>
            </div>
          );
        })}
      </div>

      {/* Slider */}
      <input
        type="range"
        min={0}
        max={10}
        step={0.5}
        value={minRating}
        onChange={(e) => onMinRatingChange(parseFloat(e.target.value))}
        className="w-full h-2 rounded-lg appearance-none cursor-pointer accent-[rgb(115,51,217)] bg-black/10"
      />

      {/* Footer */}
      <div className="flex items-center justify-between mt-3">
        <span className="text-xs font-semibold text-gray-500">
          {filteredCount} Food Spot{filteredCount !== 1 ? "s" : ""}
        </span>
        {minRating > 0 && (
          <button
            onClick={() => onMinRatingChange(0)}
            className="text-xs font-medium text-gray-400 hover:text-gray-600 transition-colors"
          >
            Reset
          </button>
        )}
      </div>
    </div>
  );
}
