import { createClient } from "@supabase/supabase-js";

const supabaseUrl = "https://nuriruulwjjpycdszdrn.supabase.co";
const supabaseAnonKey = "sb_publishable_N-y1AAu_Ni-j6WLC3ygreg_TocDrIw2";

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
