import { CUISINE_TYPES, PRICE_LABELS } from "./types";

// Rating color based on personal_rating scale (1-10)
export function getRatingColor(rating: number | null | undefined): string {
  if (rating == null) return "rgb(153, 153, 161)"; // muted gray
  if (rating >= 9) return "rgb(115, 51, 217)"; // purple (elite)
  if (rating >= 8) return "rgb(153, 255, 51)"; // lime (very good)
  if (rating >= 7) return "rgb(255, 191, 0)"; // amber (solid)
  if (rating >= 5) return "rgb(153, 153, 161)"; // muted gray
  return "rgb(217, 64, 64)"; // red
}

// Tailwind-friendly class for rating backgrounds
export function getRatingBgClass(rating: number | null | undefined): string {
  if (rating == null) return "bg-[rgb(153,153,161)]";
  if (rating >= 9) return "bg-[rgb(115,51,217)]";
  if (rating >= 8) return "bg-[rgb(153,255,51)]";
  if (rating >= 7) return "bg-[rgb(255,191,0)]";
  if (rating >= 5) return "bg-[rgb(153,153,161)]";
  return "bg-[rgb(217,64,64)]";
}

// Text color for contrast on rating backgrounds
export function getRatingTextClass(rating: number | null | undefined): string {
  if (rating == null) return "text-white";
  if (rating >= 9) return "text-white";
  if (rating >= 8) return "text-[rgb(38,38,46)]";
  if (rating >= 7) return "text-[rgb(38,38,46)]";
  if (rating >= 5) return "text-white";
  return "text-white";
}

export function getCuisineEmoji(cuisineType: string): string {
  return CUISINE_TYPES[cuisineType] || "\ud83c\udf7d\ufe0f";
}

export function getCuisineLabel(cuisineType: string): string {
  // Convert camelCase to readable format
  const label = cuisineType.replace(/([A-Z])/g, " $1").trim();
  return label.charAt(0).toUpperCase() + label.slice(1);
}

export function getPriceLabel(priceRange: string): string {
  return PRICE_LABELS[priceRange] || priceRange;
}

export function getNeighborhoodLabel(neighborhood: string): string {
  const labels: Record<string, string> = {
    altona: "Altona",
    ottensen: "Ottensen",
    stPauli: "St. Pauli",
    sternschanze: "Sternschanze",
    "eimsb\u00fcttel": "Eimsb\u00fcttel",
    neustadt: "Neustadt",
    altstadt: "Altstadt",
    winterhude: "Winterhude",
    eppendorf: "Eppendorf",
    barmbek: "Barmbek",
    stGeorg: "St. Georg",
    hafenCity: "HafenCity",
    other: "Other",
  };
  return labels[neighborhood] || neighborhood;
}

// Parse opening hours format: "Monday: 4:00-11:00 PM; Tuesday: ..."
export function parseOpeningHours(
  hours: string | null
): { day: string; hours: string }[] {
  if (!hours) return [];
  return hours.split(";").map((entry) => {
    const trimmed = entry.trim();
    const colonIndex = trimmed.indexOf(":");
    if (colonIndex === -1) return { day: trimmed, hours: "" };
    return {
      day: trimmed.slice(0, colonIndex).trim(),
      hours: trimmed.slice(colonIndex + 1).trim(),
    };
  });
}

// Calculate distance between two lat/lng points in km (Haversine)
export function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export function formatDistance(km: number): string {
  if (km < 1) return `${Math.round(km * 1000)}m`;
  return `${km.toFixed(1)}km`;
}

const FAVORITES_KEY = "mampf_favorites";

export function getFavorites(): Set<string> {
  if (typeof window === "undefined") return new Set();
  try {
    const stored = localStorage.getItem(FAVORITES_KEY);
    if (stored) return new Set(JSON.parse(stored));
  } catch {
    // ignore
  }
  return new Set();
}

export function saveFavorites(favorites: Set<string>): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(FAVORITES_KEY, JSON.stringify([...favorites]));
}
