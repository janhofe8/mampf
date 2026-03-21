"use client";

export type TabId = "map" | "list";

interface BottomTabsProps {
  activeTab: TabId;
  onTabChange: (tab: TabId) => void;
}

export default function BottomTabs({ activeTab, onTabChange }: BottomTabsProps) {
  const tabs: { id: TabId; label: string; icon: React.ReactNode }[] = [
    {
      id: "map",
      label: "Map",
      icon: (
        <svg
          className="w-6 h-6"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M9 6.75V15m6-6v8.25m.503 3.498l4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 00-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0z"
          />
        </svg>
      ),
    },
    {
      id: "list",
      label: "Food Spots",
      icon: (
        <svg
          className="w-6 h-6"
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={1.5}
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M15.75 2.25v6m0-6l2.25 6m-2.25-6l-2.25 6m-6-1.5V21m0 0h4.5m-4.5 0H3m9.75-9.75h.008v.008H12.75v-.008zM9.75 9v.008H9.742V9h.008zm0 2.25v.008H9.742v-.008h.008zM7.5 9v.008H7.492V9H7.5zm0 2.25v.008H7.492v-.008H7.5zm0 2.25v.008H7.492v-.008H7.5z"
          />
        </svg>
      ),
    },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-black/10 bg-white/95 backdrop-blur-xl safe-area-bottom">
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto px-2">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`flex flex-col items-center justify-center gap-0.5 flex-1 h-full transition-colors duration-200 ${
                isActive
                  ? "text-[rgb(115,51,217)]"
                  : "text-[rgb(153,153,161)] hover:text-black"
              }`}
            >
              {tab.icon}
              <span className="text-[10px] font-medium">{tab.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
