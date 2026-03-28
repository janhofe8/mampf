"use client";

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
  onFiltersChange: (filters: Filters) => void;
  filteredCount: number;
}

export default function FilterSheet({
  isOpen,
  onClose,
  filters,
  onFiltersChange,
  filteredCount,
}: FilterSheetProps) {
  const toggleCuisine = (cuisine: string) => {
    const cuisines = filters.cuisines.includes(cuisine)
      ? filters.cuisines.filter((c) => c !== cuisine)
      : [...filters.cuisines, cuisine];
    onFiltersChange({ ...filters, cuisines });
  };

  const toggleNeighborhood = (hood: string) => {
    const neighborhoods = filters.neighborhoods.includes(hood)
      ? filters.neighborhoods.filter((n) => n !== hood)
      : [...filters.neighborhoods, hood];
    onFiltersChange({ ...filters, neighborhoods });
  };

  const togglePrice = (price: string) => {
    const priceRanges = filters.priceRanges.includes(price)
      ? filters.priceRanges.filter((p) => p !== price)
      : [...filters.priceRanges, price];
    onFiltersChange({ ...filters, priceRanges });
  };

  const handleReset = () => {
    onFiltersChange({ cuisines: [], neighborhoods: [], priceRanges: [], minRating: 0 });
  };

  const hasActiveFilters =
    filters.cuisines.length > 0 ||
    filters.neighborhoods.length > 0 ||
    filters.priceRanges.length > 0;

  // Filter out "other" from display — it's only a fallback
  const cuisineEntries = Object.entries(CUISINE_TYPES).filter(([key]) => key !== "other");

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
            disabled={!hasActiveFilters}
            className="text-sm text-gray-500 hover:text-black transition-colors disabled:opacity-30"
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
          {/* Price Range */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Price Range
            </h4>
            <div className="flex gap-2">
              {Object.entries(PRICE_LABELS).map(([key, label]) => {
                const selected = filters.priceRanges.includes(key);
                return (
                  <button
                    key={key}
                    onClick={() => togglePrice(key)}
                    className={`flex-1 py-2 rounded-xl text-sm font-semibold transition-all duration-200 ${
                      selected
                        ? "bg-[rgb(115,51,217)] text-white scale-[1.02]"
                        : "bg-black/5 text-gray-500 hover:bg-black/10"
                    }`}
                  >
                    {selected && <span className="mr-1">&#10003;</span>}
                    {label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Cuisine Type */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Cuisine
            </h4>
            <div className="grid grid-cols-3 gap-2">
              {cuisineEntries.map(([key, emoji]) => {
                const selected = filters.cuisines.includes(key);
                return (
                  <button
                    key={key}
                    onClick={() => toggleCuisine(key)}
                    className={`py-1.5 rounded-lg text-sm font-medium text-center transition-all duration-200 ${
                      selected
                        ? "bg-[rgb(115,51,217)] text-white scale-[1.02]"
                        : "bg-black/5 text-gray-500 hover:bg-black/10"
                    }`}
                  >
                    {selected && <span className="mr-0.5 text-xs">&#10003;</span>}
                    {emoji} {getCuisineLabel(key)}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Neighborhood */}
          <div>
            <h4 className="text-sm font-semibold text-gray-600 uppercase tracking-wider mb-3">
              Neighborhood
            </h4>
            <div className="grid grid-cols-3 gap-2">
              {NEIGHBORHOODS.map((hood) => {
                const selected = filters.neighborhoods.includes(hood);
                return (
                  <button
                    key={hood}
                    onClick={() => toggleNeighborhood(hood)}
                    className={`py-1.5 rounded-lg text-sm font-medium text-center transition-all duration-200 ${
                      selected
                        ? "bg-[rgb(115,51,217)] text-white scale-[1.02]"
                        : "bg-black/5 text-gray-500 hover:bg-black/10"
                    }`}
                  >
                    {selected && <span className="mr-0.5 text-xs">&#10003;</span>}
                    {getNeighborhoodLabel(hood)}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Result count button */}
        <div className="px-5 py-4 border-t border-black/10 safe-area-bottom">
          <button
            onClick={onClose}
            className="w-full py-3 rounded-2xl bg-[rgb(115,51,217)] text-white font-bold text-base hover:bg-[rgb(130,66,232)] transition-colors active:scale-[0.98]"
          >
            Show {filteredCount} Food Spots
          </button>
        </div>
      </div>
    </div>
  );
}
