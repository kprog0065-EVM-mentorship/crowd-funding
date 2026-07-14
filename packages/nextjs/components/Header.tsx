"use client";

import Link from "next/link";
import { ConnectButton as RainbowKitConnectButton } from "@rainbow-me/rainbowkit";

export const Header = function () {
  return (
    <section className="border-b border-white/10">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5">
        <Link href="/" className="text-xl font-bold tracking-tight">
          CrowdFund
        </Link>
        <div className="flex items-center gap-3">
          <Link
            href="/create"
            className="rounded-full bg-indigo-500 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-400"
          >
            Start a Campaign
          </Link>
          <RainbowKitConnectButton />
        </div>
      </div>
    </section>
  );
};
