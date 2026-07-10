/* solhint-disable */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import { CrowdFund } from "../../contracts/CrowdFund.sol";

contract CrowdFundTest is Test {
    CrowdFund internal crowdFund;

    address internal owner = address(0xA11CE);
    address internal alice = address(0xB0B);
    address internal bob = address(0xCAFE);
    address internal charlie = address(0xD00D);

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);

        vm.prank(owner);
        crowdFund = new CrowdFund();
    }

    function _createCampaign(uint256 goal, uint256 duration) internal returns (uint256 id) {
        vm.prank(owner);
        crowdFund.createCampaign("Campaign Title", "Campaign Description", goal, duration);
        id = crowdFund.campaignCount();
    }

    function _createBasicCampaign() internal returns (uint256 id) {
        return _createCampaign(10 ether, 7 days);
    }

    function testCreateCampaignHappyPath() public {
        vm.expectEmit(true, true, false, true);
        emit CrowdFund.CampaignCreated(1, owner, "Campaign Title", 10 ether, block.timestamp + 7 days);

        vm.prank(owner);
        crowdFund.createCampaign("Campaign Title", "Campaign Description", 10 ether, 7 days);

        assertEq(crowdFund.campaignCount(), 1);
        CrowdFund.Campaign memory campaign = crowdFund.getCampaign(1);
        assertEq(campaign.id, 1);
        assertEq(campaign.goal, 10 ether);
        assertEq(campaign.amountRaised, 0);
        assertEq(campaign.deadline, block.timestamp + 7 days);
        assertEq(campaign.owner, owner);
        assertEq(uint256(campaign.status), uint256(CrowdFund.CampaignStatus.Active));
        assertFalse(campaign.withdrawn);
        assertEq(campaign.title, "Campaign Title");
        assertEq(campaign.description, "Campaign Description");
    }

    function testCreateCampaignRevertsOnEmptyTitle() public {
        vm.prank(owner);
        vm.expectRevert(CrowdFund.EmptyTitle.selector);
        crowdFund.createCampaign("", "Campaign Description", 10 ether, 7 days);
    }

    function testCreateCampaignRevertsOnEmptyDescription() public {
        vm.prank(owner);
        vm.expectRevert(CrowdFund.EmptyDescription.selector);
        crowdFund.createCampaign("Campaign Title", "", 10 ether, 7 days);
    }

    function testCreateCampaignRevertsOnInvalidGoal() public {
        vm.prank(owner);
        vm.expectRevert(CrowdFund.InvalidGoal.selector);
        crowdFund.createCampaign("Campaign Title", "Campaign Description", 0, 7 days);
    }

    function testCreateCampaignRevertsOnInvalidDuration() public {
        vm.prank(owner);
        vm.expectRevert(CrowdFund.InvalidDuration.selector);
        crowdFund.createCampaign("Campaign Title", "Campaign Description", 10 ether, 0);
    }

    function testContributeHappyPath() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit CrowdFund.DonationReceived(id, alice, 3 ether);
        crowdFund.contribute{ value: 3 ether }(id);

        assertEq(crowdFund.getAmountRaised(id), 3 ether);
        assertEq(crowdFund.getContributorCount(id), 1);
        assertEq(crowdFund.getContribution(id, alice), 3 ether);
        assertEq(uint256(crowdFund.getCampaign(id).status), uint256(CrowdFund.CampaignStatus.Active));
    }

    function testContributeFirstContributorCountOnlyOnce() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        crowdFund.contribute{ value: 1 ether }(id);

        vm.prank(alice);
        crowdFund.contribute{ value: 1 ether }(id);

        assertEq(crowdFund.getContributorCount(id), 1);
        assertEq(crowdFund.getContribution(id, alice), 2 ether);
        assertEq(crowdFund.getAmountRaised(id), 2 ether);
    }

    function testContributeExactGoalMarksSuccessful() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);

        CrowdFund.Campaign memory campaign = crowdFund.getCampaign(id);
        assertEq(crowdFund.getAmountRaised(id), 10 ether);
        assertEq(uint256(campaign.status), uint256(CrowdFund.CampaignStatus.Successful));
    }

    function testContributeOverGoalRefundsExcess() public {
        uint256 id = _createBasicCampaign();

        uint256 aliceBefore = alice.balance;

        vm.prank(alice);
        crowdFund.contribute{ value: 12 ether }(id);

        assertEq(crowdFund.getAmountRaised(id), 10 ether);
        assertEq(crowdFund.getContribution(id, alice), 10 ether);
        assertEq(crowdFund.getContributorCount(id), 1);
        assertEq(uint256(crowdFund.getCampaign(id).status), uint256(CrowdFund.CampaignStatus.Successful));
        assertEq(alice.balance, aliceBefore - 10 ether);
    }

    function testContributeRevertsOnZeroValue() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        vm.expectRevert(CrowdFund.ZeroContribution.selector);
        crowdFund.contribute(id);
    }

    function testContributeRevertsOnInvalidCampaign() public {
        vm.prank(alice);
        vm.expectRevert(CrowdFund.CampaignNotFound.selector);
        crowdFund.contribute{ value: 1 ether }(1);
    }

    function testContributeRevertsWhenNotActive() public {
        uint256 id = _createBasicCampaign();

        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        vm.expectRevert(CrowdFund.CampaignNotActive.selector);
        crowdFund.contribute{ value: 1 ether }(id);
    }

    function testWithdrawHappyPath() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);

        uint256 ownerBefore = owner.balance;

        vm.warp(block.timestamp + 8 days);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit CrowdFund.FundsWithdrawn(id, owner, 10 ether);
        crowdFund.withdraw(id);

        CrowdFund.Campaign memory campaign = crowdFund.getCampaign(id);
        assertTrue(campaign.withdrawn);
        assertEq(uint256(campaign.status), uint256(CrowdFund.CampaignStatus.Successful));
        assertEq(owner.balance, ownerBefore + 10 ether);
    }

    function testWithdrawRevertsForNonOwner() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);
        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        vm.expectRevert(CrowdFund.NotCampaignOwner.selector);
        crowdFund.withdraw(id);
    }

    function testWithdrawRevertsBeforeSuccess() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 1 ether }(id);

        vm.warp(block.timestamp + 8 days);

        vm.prank(owner);
        vm.expectRevert(CrowdFund.CampaignNotSuccessful.selector);
        crowdFund.withdraw(id);
    }

    function testWithdrawRevertsWhenAlreadyWithdrawn() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);
        vm.warp(block.timestamp + 8 days);

        vm.prank(owner);
        crowdFund.withdraw(id);

        vm.prank(owner);
        vm.expectRevert(CrowdFund.CampaignFundsAlreadyWithdrawn.selector);
        crowdFund.withdraw(id);
    }

    function testClaimRefundHappyPath() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 3 ether }(id);

        vm.warp(block.timestamp + 8 days);

        uint256 aliceBeforeContribution = 100 ether;

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit CrowdFund.RefundClaimed(id, alice, 3 ether);
        crowdFund.claimRefund(id);

        assertEq(crowdFund.getContribution(id, alice), 0);
        assertEq(alice.balance, aliceBeforeContribution);
        assertEq(uint256(crowdFund.getCampaign(id).status), uint256(CrowdFund.CampaignStatus.Failed));
    }

    function testClaimRefundRevertsForNonContributor() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 3 ether }(id);
        vm.warp(block.timestamp + 8 days);

        vm.prank(bob);
        vm.expectRevert(CrowdFund.NoContributionToRefund.selector);
        crowdFund.claimRefund(id);
    }

    function testClaimRefundRevertsWhenCampaignSuccessful() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);
        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        vm.expectRevert(CrowdFund.CampaignWasSuccessful.selector);
        crowdFund.claimRefund(id);
    }

    function testClaimRefundRevertsWhenAlreadyRefunded() public {
        uint256 id = _createBasicCampaign();
        vm.prank(alice);
        crowdFund.contribute{ value: 3 ether }(id);
        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        crowdFund.claimRefund(id);

        vm.prank(alice);
        vm.expectRevert(CrowdFund.NoContributionToRefund.selector);
        crowdFund.claimRefund(id);
    }

    function testGetTimeRemainingReturnsZeroAfterDeadline() public {
        uint256 id = _createBasicCampaign();

        uint256 remainingBefore = crowdFund.getTimeRemaining(id);
        assertGt(remainingBefore, 0);

        vm.warp(block.timestamp + 8 days);
        assertEq(crowdFund.getTimeRemaining(id), 0);
    }

    function testUpdateCampaignStatusEarlyReturnWhenSuccessful() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);

        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        vm.expectRevert(CrowdFund.CampaignNotActive.selector);
        crowdFund.contribute{ value: 1 ether }(id);

        CrowdFund.Campaign memory campaign = crowdFund.getCampaign(id);
        assertEq(uint256(campaign.status), uint256(CrowdFund.CampaignStatus.Successful));
    }

    function testUpdateCampaignStatusFailsAfterDeadline() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        crowdFund.contribute{ value: 3 ether }(id);

        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        crowdFund.claimRefund(id);

        CrowdFund.Campaign memory campaign = crowdFund.getCampaign(id);
        assertEq(uint256(campaign.status), uint256(CrowdFund.CampaignStatus.Failed));
    }

    function testClaimRefundRevertsOnSuccessfulCampaign() public {
        uint256 id = _createBasicCampaign();

        vm.prank(alice);
        crowdFund.contribute{ value: 10 ether }(id);
        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);
        vm.expectRevert(CrowdFund.CampaignWasSuccessful.selector);
        crowdFund.claimRefund(id);
    }

    function testClaimRefundRevertsOnInvalidCampaignId() public {
        vm.prank(alice);
        vm.expectRevert(CrowdFund.CampaignNotFound.selector);
        crowdFund.claimRefund(1);
    }

    function testWithdrawRevertsOnInvalidCampaignId() public {
        vm.prank(owner);
        vm.expectRevert(CrowdFund.NotCampaignOwner.selector);
        crowdFund.withdraw(1);
    }

    function testReceiveReverts() public {
        vm.expectRevert(CrowdFund.DirectTransferNotAllowed.selector);
        payable(address(crowdFund)).transfer(1 ether);
    }

    function testFallbackReverts() public {
        (bool success, bytes memory data) = address(crowdFund).call{ value: 1 ether }(
            abi.encodeWithSignature("nope()")
        );
        assertFalse(success);
        assertEq(bytes4(data), CrowdFund.DirectTransferNotAllowed.selector);
    }
}
