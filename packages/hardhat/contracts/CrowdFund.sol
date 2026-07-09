// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title CrowdFund Contract
/// @author Kevon Jaggassar
/// @notice CrowdFund Contract
/// @dev This contract is a crowdfunding platform where users can create campaigns and contribute to them.
contract CrowdFund is ReentrancyGuard, Ownable {
    // -------------------------
    // Type Declarations
    // -------------------------

    enum CampaignStatus {
        Active,
        Successful,
        Failed
    }

    /// @notice campaign struct
    // solhint-disable-next-line
    struct Campaign {
        uint256 id;
        uint256 goal;
        uint256 amountRaised;
        uint256 deadline;
        address owner;
        CampaignStatus status;
        bool withdrawn;
        string title;
        string description;
    }

    // -------------------------
    // State Variables
    // -------------------------

    /// @notice total number of campaigns
    uint256 public campaignCount;

    /// @notice mapping of campaign id to campaign
    mapping(uint256 => Campaign) public campaigns;

    /// @notice mapping of campaign id to contributor count
    mapping(uint256 => uint256) public contributorCount;

    /// @notice mapping of campaign id to contributors
    mapping(uint256 => mapping(address => uint256)) public contributions;

    // -------------------------
    // Events
    // -------------------------

    /// @notice campaign created
    /// @param campaignId campaign id
    /// @param owner campaign owner
    /// @param title campaign title
    /// @param goal campaign goal
    /// @param deadline campaign deadline
    // solhint-disable-next-line
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed owner,
        string title,
        uint256 goal,
        uint256 deadline
    );

    /// @notice donation received
    /// @param campaignId campaign id
    /// @param contributor contributor
    /// @param amount donation amount
    // solhint-disable-next-line
    event DonationReceived(uint256 indexed campaignId, address contributor, uint256 amount);

    /// @notice funds withdrawn
    /// @param campaignId campaign id
    /// @param recipient recipient
    /// @param amount amount
    // solhint-disable-next-line
    event FundsWithdrawn(uint256 indexed campaignId, address recipient, uint256 amount);

    /// @notice refund claimed
    /// @param campaignId campaign id
    /// @param recipient recipient
    /// @param amount amount
    // solhint-disable-next-line
    event RefundClaimed(uint256 indexed campaignId, address recipient, uint256 amount);

    // -------------------------
    // Custom Errors
    // -------------------------

    error EmptyTitle();
    error EmptyDescription();
    error InvalidGoal();
    error InvalidDuration();
    error CampaignNotFound();
    error CampaignNotActive();
    error ZeroContribution();
    error DirectTransferNotAllowed();
    error NotCampaignOwner();
    error CampaignFundsAlreadyWithdrawn();
    error WithdrawalFailed();
    error GoalWasReached();
    error NoContributionToRefund();
    error RefundFailed();
    error ExcessRefundFailed();
    error GoalWouldBeExceeded();
    error CampaignAlreadySuccessful();
    error CampaignNotSuccessful();
    error CampaignWasSuccessful();

    // -------------------------
    // Constructor
    // -------------------------

    /// @notice Constructor description.
    constructor() Ownable(msg.sender) {}

    // -------------------------
    // External Functions
    // -------------------------

    /// @notice Receives direct ETH transfers; use the dedicated flow for safer, explicit deposits.
    receive() external payable {
        revert DirectTransferNotAllowed();
    }

    /// @notice Fallback function, if no call data is provided with ETH transfer
    fallback() external payable {
        revert DirectTransferNotAllowed();
    }

    /// @notice function to create a campaign
    /// @param _title campaign title
    /// @param _description campaign description
    /// @param _goal campaign goal
    /// @param _duration campaign duration
    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _goal,
        uint256 _duration
    ) external {
        _validateCampaignInputs(_title, _description, _goal, _duration);

        ++campaignCount;
        uint256 deadline = block.timestamp + _duration;

        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            owner: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            amountRaised: 0,
            deadline: deadline,
            status: CampaignStatus.Active,
            withdrawn: false
        });

        emit CampaignCreated(campaignCount, msg.sender, _title, _goal, deadline);
    }

    /// @notice function to contribute to a campaign
    /// @param _campaignId campaign id
    function contribute(uint256 _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];

        _updateCampaignStatus(campaign);
        _validateContribution(_campaignId, campaign);

        uint256 remaining = campaign.goal - campaign.amountRaised;
        if (remaining == 0) revert CampaignAlreadySuccessful();

        uint256 accepted = msg.value;
        uint256 refund = 0;

        if (msg.value > remaining) {
            accepted = remaining;
            refund = msg.value - remaining;
        }

        if (contributions[_campaignId][msg.sender] == 0 && accepted > 0) {
            ++contributorCount[_campaignId];
        }

        campaign.amountRaised += accepted;
        contributions[_campaignId][msg.sender] += accepted;

        if (campaign.amountRaised == campaign.goal) {
            campaign.status = CampaignStatus.Successful;
        }

        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{ value: refund }("");
            if (!success) revert ExcessRefundFailed();
        }

        emit DonationReceived(_campaignId, msg.sender, accepted);
    }

    /// @notice Owner withdraws funds once after deadline if goal is met, using CEI and reentrancy protection.
    /// @param _campaignId campaign id
    function withdraw(uint256 _campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[_campaignId];

        _updateCampaignStatus(campaign);
        _validateWithdrawal(_campaignId, campaign);

        uint256 amount = campaign.amountRaised;

        campaign.withdrawn = true;
        campaign.status = CampaignStatus.Successful;

        (bool success, ) = payable(campaign.owner).call{ value: amount }("");
        if (!success) revert WithdrawalFailed();

        emit FundsWithdrawn(_campaignId, campaign.owner, amount);
    }

    /// @notice Contributor claims refund after deadline if goal is unmet; updates state before transfer, once only.
    /// @param _campaignId campaign id
    function claimRefund(uint256 _campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[_campaignId];

        _validateRefund(_campaignId, campaign);

        uint256 amount = contributions[_campaignId][msg.sender];

        contributions[_campaignId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{ value: amount }("");
        if (!success) revert RefundFailed();

        emit RefundClaimed(_campaignId, msg.sender, amount);
    }

    // -------------------------
    // Internal Functions
    // -------------------------

    /// @notice internal helper to update campaign status
    /// @param campaign campaign
    function _updateCampaignStatus(Campaign storage campaign) internal {
        if (campaign.status != CampaignStatus.Active) return;

        // solhint-disable-next-line gas-strict-inequalities
        if (block.timestamp >= campaign.deadline) {
            // solhint-disable-next-line gas-strict-inequalities
            if (campaign.amountRaised >= campaign.goal) {
                campaign.status = CampaignStatus.Successful;
            } else {
                campaign.status = CampaignStatus.Failed;
            }
        }
    }

    /// @notice internal helper to validate contribution
    /// @param _campaignId campaign id
    /// @param campaign campaign
    function _validateContribution(uint256 _campaignId, Campaign storage campaign) internal view {
        if (_campaignId == 0 || _campaignId > campaignCount) revert CampaignNotFound();
        if (msg.value == 0) revert ZeroContribution();
        if (campaign.status != CampaignStatus.Active) revert CampaignNotActive();
    }

    /// @notice internal helper to validate withdrawal
    /// @param _campaignId campaign id
    /// @param campaign campaign
    function _validateWithdrawal(uint256 _campaignId, Campaign storage campaign) internal view {
        if (_campaignId == 0 || _campaignId > campaignCount) revert CampaignNotFound();
        if (msg.sender != campaign.owner) revert NotCampaignOwner();
        if (campaign.status != CampaignStatus.Successful) revert CampaignNotSuccessful();
        if (campaign.withdrawn) revert CampaignFundsAlreadyWithdrawn();
    }

    /// @notice internal helper to validate refund
    /// @param _campaignId campaign id
    /// @param campaign campaign
    function _validateRefund(uint256 _campaignId, Campaign storage campaign) internal view {
        if (_campaignId == 0 || _campaignId > campaignCount) revert CampaignNotFound();
        if (campaign.status == CampaignStatus.Successful) revert CampaignWasSuccessful();
        if (contributions[_campaignId][msg.sender] == 0) revert NoContributionToRefund();
    }

    /// @notice internal helper for non-empty title/description, nonzero goal, valid duration
    /// @param _title campaign title
    /// @param _description campaign description
    /// @param _goal campaign goal
    /// @param _duration campaign duration
    function _validateCampaignInputs(
        string calldata _title,
        string calldata _description,
        uint256 _goal,
        uint256 _duration
    ) internal pure {
        if (bytes(_title).length == 0) revert EmptyTitle();
        if (bytes(_description).length == 0) revert EmptyDescription();
        if (_goal == 0) revert InvalidGoal();
        if (_duration == 0) revert InvalidDuration();
    }
}
