"use client";

import { SwitchTheme } from "~~/components/SwitchTheme";

export const Footer = function Footer() {
  return (
    <footer className="border-t border-white/10 bg-slate-950 px-6 py-6">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-4">
        <div className="text-sm text-slate-400">
          <p className="font-medium text-white/90">CrowdFund</p>
          <p>Transparent crowdfunding on-chain.</p>
        </div>

        <SwitchTheme />
      </div>
    </footer>
  );
};
