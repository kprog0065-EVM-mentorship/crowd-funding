"use client";

import { useReadContracts } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export type Campaign = {
  id: bigint;
  goal: bigint;
  amountRaised: bigint;
  deadline: bigint;
  owner: `0x${string}`;
  status: bigint;
  withdrawn: boolean;
  title: string;
  description: string;
};

export function useCampaigns() {
  const { data: campaignCount, isLoading: countLoading } = useScaffoldReadContract({
    contractName: "CrowdFund",
    functionName: "campaignCount",
  });

  const count = Number(campaignCount ?? 0n);
  const ids = Array.from({ length: count }, (_, i) => BigInt(i + 1));

  const { data: campaigns, isLoading: campaignsLoading } = useReadContracts({
    contracts: ids.map(id => ({
      abi: [], // not needed if you switch to Scaffold-ETH read hooks for each campaign
      address: "0x...",
      functionName: "getCampaign" as const,
      args: [id] as const,
    })),
    query: { enabled: ids.length > 0 },
  });

  const normalizedCampaigns =
    (campaigns
      ?.map((result, index) => {
        const campaign = result.result as Campaign | undefined;
        return campaign ? { ...campaign, id: ids[index] } : undefined;
      })
      .filter(Boolean) as Campaign[]) ?? [];

  return {
    campaignCount: count,
    campaigns: normalizedCampaigns,
    isLoading: countLoading || campaignsLoading,
  };
}
