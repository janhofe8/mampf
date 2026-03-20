"use client";

import { useEffect, useState } from "react";
import { getRatingColor } from "@/lib/utils";

interface RatingBarProps {
  label: string;
  value: number | null | undefined;
  maxValue: number;
  icon?: string;
  color?: string;
  suffix?: string;
}

export default function RatingBar({
  label,
  value,
  maxValue,
  icon,
  color,
  suffix,
}: RatingBarProps) {
  const [animated, setAnimated] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setAnimated(true), 100);
    return () => clearTimeout(timer);
  }, []);

  const percentage = value != null ? (value / maxValue) * 100 : 0;
  const barColor = color || getRatingColor(value);
  const displayValue =
    value != null ? (Number.isInteger(value) ? value.toString() : value.toFixed(1)) : "N/A";

  return (
    <div className="flex items-center gap-3">
      {icon && <span className="text-lg w-6 text-center">{icon}</span>}
      <div className="flex-1">
        <div className="flex justify-between items-center mb-1">
          <span className="text-xs font-medium text-gray-600">{label}</span>
          <span className="text-sm font-bold text-gray-900">
            {displayValue}
            {suffix && value != null ? suffix : ""}
          </span>
        </div>
        <div className="h-2 bg-black/10 rounded-full overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-1000 ease-out"
            style={{
              width: animated ? `${percentage}%` : "0%",
              backgroundColor: barColor,
            }}
          />
        </div>
      </div>
    </div>
  );
}
