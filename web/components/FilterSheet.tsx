"use client";

import { useState } from "react";
import {
  Filters,
  CUISINE_TYPES,
  NEIGHBORHOODS,
  PRICE_LABELS,
} from "@/lib/types";
import {
  getCuisineLabel,
  getNeighborhoodLabel,
} from "@/lib/utils";

interface FilterSheetProps {
  isOpen: boolean;
  onClose: () => void;
  filters: Filters;
  onApply: (filters: Filters) => void;
}

export default function FilterSheet({
  isOpen,
  onClose,
  filters,
  onApply,
}: FilterSheetProps) {
  const [localFilters, setLocalFilters] = useState<Filters>(filters);

  const toggleCuisine = (cuisine: string) => {
    setLocalFilters((prev) => ({
      ...prev,
      cuisines: prev.cuisines.includes(cuisine)
        ? prev.cuisines.filter((c) => c !== cuisine)
        : [...prev.cuisines, cuisine],
    }));
  };

  const toggleNeighborhood = (hood: string) => {
    setLocalFilters((prev) => ({
      ...prev,
      neighborhoods: prev.neighborhoods.includes(hood)
        ? prev.neighborhoods.filter((n) => n !== hood)
        : [...prev.neighborhoods, hood],
    }));
  };

  const togglePrice = (price: string) => {
    setLocalFilters((prev) => ({
      ...prev,
      priceRanges: prev.priceRanges.includes(price)
        ? prev.priceRanges.filter((p) => p !== price)
        : [...prev.priceRanges, price],
    }));
  };

  const handleApply = () => {
    onApply(localFilters);
    onClose();
  };

  const handleReset = () => {
    const resetFilters: Filters = {
      cuisines: [],
      neighborhoods: [],
      priceRanges: [],
      minRating: 0,
    };
    setLocalFilters(resetFilters);
    onApply(resetFilters);
    onClose();
  };

  const activeFilterCount =
    localFilters.cuisines.length +
    localFilters.neighborhoods.length +
    localFilters.priceRanges.length +
    (localFilters.minRating > 0 ? 1 : 0);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="relative w-full max-w-lg bg-white rounded-t-3xl max-h-[85vh] flex flex-col animate-slide-up">
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 rounded-full bg-black/10" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/10">
          <button
            onClick={handleReset}
            className="text-sm text-gray-500 hover:text-black transition-colors"
          >
            Reset
          </button>
          <h3 className="text-lg font-bold text-gray-900">Filters</h3>
          <button
            onClick={onClose}
            className="text-sm text-[rgb(115,51,217)] font-semibold hover:text-[rgb(153,255,51)] transition-colors"
          >
            Done
          </button>
        </div>

        {/* Scrollable content */}
        <div className="flex-1 overflow-y-auto px-5 py-4 space-y-6">
          {/* Minimum Rating */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Minimum MAMPF Rating
            </h4>
            <div className="flex items-center gap-3">
              <input
                type="range"
                min={0}
                max={10}
                step={0.5}
                value={localFilters.minRating}
                onChange={(e) =>
                  setLocalFilters((prev) => ({
                    ...prev,
                    minRating: parseFloat(e.target.value),
                  }))
                }
                className="flex-1 accent-[rgb(115,51,217)]"
              />
              <span className="text-gray-900 font-bold w-8 text-center text-sm">
                {localFilters.minRating > 0 ? localFilters.minRating : "Any"}
              </span>
            </div>
          </div>

          {/* Price Range */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Price Range
            </h4>
            <div className="flex gap-2">
              {Object.entries(PRICE_LABELS).map(([key, label]) => (
                <button
                  key={key}
                  onClick={() => togglePrice(key)}
                  className={`flex-1 py-2 rounded-xl text-sm font-semibold transition-all duration-200 ${
                    localFilters.priceRanges.includes(key)
                      ? "bg-[rgb(115,51,217)] text-white"
                      : "bg-black/5 text-gray-500 hover:bg-black/5"
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Cuisine Type */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Cuisine
            </h4>
            <div className="flex flex-wrap gap-2">
              {Object.entries(CUISINE_TYPES).map(([key, emoji]) => (
                <button
                  key={key}
                  onClick={() => toggleCuisine(key)}
                  className={`px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
                    localFilters.cuisines.includes(key)
                      ? "bg-[rgb(115,51,217)] text-white"
                      : "bg-black/5 text-gray-500 hover:bg-black/5"
                  }`}
                >
                  {emoji} {getCuisineLabel(key)}
                </button>
              ))}
            </div>
          </div>

          {/* Neighborhood */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Neighborhood
            </h4>
            <div className="flex flex-wrap gap-2">
              {NEIGHBORHOODS.map((hood) => (
                <button
                  key={hood}
                  onClick={() => toggleNeighborhood(hood)}
                  className={`px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
                    localFilters.neighborhoods.includes(hood)
                      ? "bg-[rgb(115,51,217)] text-white"
                      : "bg-black/5 text-gray-500 hover:bg-black/5"
                  }`}
                >
                  {getNeighborhoodLabel(hood)}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Apply button */}
        <div className="px-5 py-4 border-t border-black/10 safe-area-bottom">
          <button
            onClick={handleApply}
            className="w-full py-3 rounded-2xl bg-[rgb(115,51,217)] text-white font-bold text-base hover:bg-[rgb(130,66,232)] transition-colors active:scale-[0.98]"
          >
            Apply Filters
            {activeFilterCount > 0 && ` (${activeFilterCount})`}
          </button>
        </div>
      </div>
    </div>
  );
}
