interface HeartIconProps {
  filled: boolean;
  className?: string;
}

export default function HeartIcon({ filled, className = "w-5 h-5" }: HeartIconProps) {
  return (
    <svg
      className={`${className} transition-all duration-300 ${
        filled
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
  );
}
