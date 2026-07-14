"use client";

import Link from "next/link";
import { formatEther } from "viem";
import { useCampaigns } from "~~/hooks/useCampaigns";

export default function HomePage() {
  const { campaignCount, campaigns, isLoading } = useCampaigns();

  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <section className="mx-auto grid max-w-7xl gap-12 px-6 py-16 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
        <div>
          <p className="mb-4 inline-flex rounded-full border border-indigo-400/30 bg-indigo-400/10 px-3 py-1 text-sm text-indigo-300">
            Transparent crowdfunding on-chain
          </p>
          <h1 className="max-w-3xl text-5xl font-bold leading-tight tracking-tight sm:text-6xl">
            Fund ideas, track progress, and move money with confidence.
          </h1>
          <p className="mt-6 max-w-2xl text-lg text-slate-300">
            Create crowdfunding campaigns, contribute ETH, and follow every goal, deadline, and payout directly
            on-chain.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/create"
              className="rounded-full bg-indigo-500 px-6 py-3 text-center font-semibold text-white hover:bg-indigo-400"
            >
              Start a Campaign
            </Link>
            <a
              href="#campaigns"
              className="rounded-full border border-white/15 px-6 py-3 text-center font-semibold text-white hover:bg-white/5"
            >
              Explore Campaigns
            </a>
          </div>
        </div>

        <div className="grid gap-4 rounded-3xl border border-white/10 bg-white/5 p-6 shadow-2xl shadow-indigo-950/20">
          <StatCard label="Total Campaigns" value={campaignCount.toString()} />
          <StatCard label="Network" value="Sepolia" />
          <StatCard label="Status" value={isLoading ? "Loading..." : "Ready"} />
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-6 py-6">
        <div className="grid gap-4 md:grid-cols-3">
          <FeatureCard
            title="Create campaigns"
            text="Launch a campaign with a title, description, goal, and deadline in seconds."
          />
          <FeatureCard
            title="Contribute safely"
            text="Send ETH directly to a campaign and track your contribution per wallet."
          />
          <FeatureCard
            title="Withdraw or refund"
            text="Owners withdraw when the goal is met. Contributors can claim refunds if it fails."
          />
        </div>
      </section>

      <section id="campaigns" className="mx-auto max-w-7xl px-6 py-16">
        <div className="mb-8 flex items-end justify-between gap-4">
          <div>
            <h2 className="text-3xl font-bold">Live campaigns</h2>
            <p className="mt-2 text-slate-400">Browse active and finished campaigns on the CrowdFund contract.</p>
          </div>
        </div>

        {isLoading ? (
          <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="animate-pulse rounded-2xl border border-white/10 bg-white/5 p-6">
                <div className="h-5 w-2/3 rounded bg-white/10" />
                <div className="mt-4 h-4 w-full rounded bg-white/10" />
                <div className="mt-2 h-4 w-5/6 rounded bg-white/10" />
                <div className="mt-6 h-36 rounded bg-white/10" />
              </div>
            ))}
          </div>
        ) : campaigns.length === 0 ? (
          <EmptyState />
        ) : (
          <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
            {campaigns.map(campaign => (
              <CampaignPreview key={campaign.id.toString()} campaign={campaign} />
            ))}
          </div>
        )}
      </section>

      <section className="border-t border-white/10 bg-white/5">
        <div className="mx-auto grid max-w-7xl gap-6 px-6 py-12 lg:grid-cols-2">
          <div>
            <h3 className="text-2xl font-bold">Built for trust</h3>
            <p className="mt-3 max-w-xl text-slate-300">
              Every contribution, withdrawal, and refund is enforced by the contract itself, so the rules stay visible
              and consistent.
            </p>
          </div>
          <div className="grid gap-3 text-sm text-slate-300 sm:grid-cols-2">
            <MiniPill>On-chain goals</MiniPill>
            <MiniPill>Deadline-based funding</MiniPill>
            <MiniPill>Refund support</MiniPill>
            <MiniPill>Owner withdrawals</MiniPill>
          </div>
        </div>
      </section>
    </main>
  );
}

function CampaignPreview({ campaign }: { campaign: any }) {
  const statusMap = ["Active", "Successful", "Failed"];
  const pct = campaign.goal > 0n ? Math.min(100, Number((campaign.amountRaised * 100n) / campaign.goal)) : 0;

  return (
    <div className="rounded-2xl border border-white/10 bg-slate-900 p-6 transition hover:-translate-y-1 hover:border-indigo-400/40">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="text-xl font-semibold">{campaign.title}</h3>
          <p className="mt-2 text-sm text-slate-400 line-clamp-3">{campaign.description}</p>
        </div>
        <span className="rounded-full bg-white/10 px-3 py-1 text-xs text-slate-200">
          {statusMap[Number(campaign.status)] ?? "Unknown"}
        </span>
      </div>

      <div className="mt-5 space-y-3 text-sm text-slate-300">
        <div className="flex justify-between gap-4">
          <span>Goal</span>
          <span>{formatEther(campaign.goal)} ETH</span>
        </div>
        <div className="flex justify-between gap-4">
          <span>Raised</span>
          <span>{formatEther(campaign.amountRaised)} ETH</span>
        </div>
        <div className="flex justify-between gap-4">
          <span>Deadline</span>
          <span>{new Date(Number(campaign.deadline) * 1000).toLocaleString()}</span>
        </div>
      </div>

      <div className="mt-5">
        <div className="h-2 overflow-hidden rounded-full bg-white/10">
          <div className="h-full rounded-full bg-indigo-500" style={{ width: `${pct}%` }} />
        </div>
        <p className="mt-2 text-xs text-slate-400">{pct}% funded</p>
      </div>

      <div className="mt-6 flex items-center justify-between">
        <span className="text-xs text-slate-400">Campaign #{campaign.id.toString()}</span>
        <Link
          href={`/campaign/${campaign.id.toString()}`}
          className="text-sm font-semibold text-indigo-300 hover:text-indigo-200"
        >
          View details →
        </Link>
      </div>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-slate-900 p-5">
      <p className="text-sm text-slate-400">{label}</p>
      <p className="mt-2 text-2xl font-semibold">{value}</p>
    </div>
  );
}

function FeatureCard({ title, text }: { title: string; text: string }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-slate-900 p-6">
      <h3 className="text-lg font-semibold">{title}</h3>
      <p className="mt-2 text-sm leading-6 text-slate-400">{text}</p>
    </div>
  );
}

function MiniPill({ children }: { children: React.ReactNode }) {
  return <div className="rounded-full border border-white/10 bg-slate-900 px-4 py-3">{children}</div>;
}

function EmptyState() {
  return (
    <div className="rounded-2xl border border-dashed border-white/15 bg-white/5 p-10 text-center text-slate-300">
      No campaigns yet. Be the first to launch one.
    </div>
  );
}
