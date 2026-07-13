/* solhint-disable */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { CrowdFund } from "../../contracts/CrowdFund.sol";

contract CrowdFundEchidna is CrowdFund {
    uint256 internal constant DEFAULT_GOAL = 10 ether;
    uint256 internal constant DEFAULT_DURATION = 7 days;

    uint256[] internal campaignIds;
    bool internal initialized;

    constructor() {}

    function setup() external {
        if (initialized) return;

        this.createCampaign("seed", "seed campaign", DEFAULT_GOAL, DEFAULT_DURATION);
        campaignIds.push(campaignCount);
        initialized = true;
    }

    // -------------------------
    // Handler-style wrappers
    // -------------------------

    function handleCreateCampaign(
        string calldata title,
        string calldata description,
        uint256 goal,
        uint256 duration
    ) external {
        if (!initialized) return;
        if (bytes(title).length == 0) return;
        if (bytes(description).length == 0) return;
        if (goal == 0) return;
        if (duration == 0) return;

        this.createCampaign(title, description, goal, duration);
        campaignIds.push(campaignCount);
    }

    function handleContribute(uint256 campaignId) external payable {
        if (!initialized) return;
        if (campaignId == 0 || campaignId > campaignCount) return;
        if (msg.value == 0) return;

        try this.contribute{ value: msg.value }(campaignId) {} catch {}
    }

    function handleWithdraw(uint256 campaignId) external {
        if (!initialized) return;
        if (campaignId == 0 || campaignId > campaignCount) return;

        try this.withdraw(campaignId) {} catch {}
    }

    function handleClaimRefund(uint256 campaignId) external {
        if (!initialized) return;
        if (campaignId == 0 || campaignId > campaignCount) return;

        try this.claimRefund(campaignId) {} catch {}
    }

    // -------------------------
    // Invariants
    // -------------------------

    function echidna_amountRaised_never_exceeds_goal() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (campaign.amountRaised > campaign.goal) {
                return false;
            }
        }
        return true;
    }

    function echidna_withdrawn_campaign_must_be_successful() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (campaign.withdrawn && campaign.status != CampaignStatus.Successful) {
                return false;
            }
        }
        return true;
    }

    function echidna_failed_campaign_cannot_be_withdrawn() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (campaign.status == CampaignStatus.Failed && campaign.withdrawn) {
                return false;
            }
        }
        return true;
    }

    function echidna_stored_successful_implies_goal_met() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (campaign.status == CampaignStatus.Successful && campaign.amountRaised != campaign.goal) {
                return false;
            }
        }
        return true;
    }

    function echidna_stored_failed_implies_goal_not_met() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (campaign.status == CampaignStatus.Failed && campaign.amountRaised == campaign.goal) {
                return false;
            }
        }
        return true;
    }

    function echidna_time_remaining_zero_for_finalized_campaigns() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (
                (campaign.status == CampaignStatus.Successful || campaign.status == CampaignStatus.Failed) &&
                this.getTimeRemaining(i) != 0
            ) {
                return false;
            }
        }
        return true;
    }

    function echidna_derived_status_matches_stored_when_finalized() external view returns (bool) {
        if (!initialized) return true;

        for (uint256 i = 1; i <= campaignCount; i++) {
            Campaign memory campaign = campaigns[i];
            if (
                campaign.status != CampaignStatus.Active &&
                uint256(this.getCampaignStatus(i)) != uint256(campaign.status)
            ) {
                return false;
            }
        }
        return true;
    }
}
