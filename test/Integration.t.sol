// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Poke} from "src/Poke.sol";
import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";
import {EthPlaysV0} from "src/EthPlaysV0.sol";

contract IntegrationTest is Test {
    // Test storage
    Poke poke;
    RegistryReceiverV0 registry;
    EthPlaysV0 ethPlays;

    address deployer;
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    // EthPlays parameters
    uint256 alignmentVoteCooldown;
    uint256 chaosVoteReward;
    uint256 orderDuration;
    uint256 orderInputReward;
    uint256 chaosInputReward;
    uint256 controlCooldownDuration;
    uint256 controlAuctionDuration;

    // Poke events
    event Transfer(address indexed from, address indexed to, uint256 value);

    // EthPlays events
    event AlignmentVote(address from, bool vote, int256 alignment);
    event InputVote(uint256 inputIndex, address from, uint256 buttonIndex);
    event ButtonInput(uint256 inputIndex, address from, uint256 buttonIndex);
    event NewControlBid(address from, uint256 amount);
    event Control(address from);

    function setUp() public {
        deployer = address(this);
        poke = new Poke();
        registry = new RegistryReceiverV0();
        ethPlays = new EthPlaysV0(address(poke), address(registry));
        poke.updateGameAddress(address(ethPlays));
        vm.roll(1);
        skip(1000);

        // Bind EthPlays parameters.
        alignmentVoteCooldown = ethPlays.alignmentVoteCooldown();
        chaosVoteReward = ethPlays.chaosVoteReward();
        orderDuration = ethPlays.orderDuration();
        orderInputReward = ethPlays.orderInputReward();
        chaosInputReward = ethPlays.chaosInputReward();
        controlCooldownDuration = ethPlays.controlCooldownDuration();
        controlAuctionDuration = ethPlays.controlAuctionDuration();
    }

    function registerAccounts() public {
        registry.submitRegistration(address(10), alice);
        registry.submitRegistration(address(20), bob);
        registry.submitRegistration(address(30), charlie);
    }

    function mine() public {
        vm.roll(block.number + 1);
        skip(2);
    }

    function dealPoke(address account, uint256 amount) public {
        vm.startPrank(address(ethPlays));
        poke.gameMint(account, amount);
        vm.stopPrank();
    }

    function testInitialParameters() public {
        assertEq(poke.gameContract(), address(ethPlays));
        assertEq(address(ethPlays.poke()), address(poke));
        assertEq(address(ethPlays.registry()), address(registry));

        assertEq(ethPlays.isActive(), true);
        assertEq(ethPlays.alignmentVoteCooldown(), 30);
        assertEq(ethPlays.alignmentDecayRate(), 985);
        assertEq(ethPlays.chaosVoteReward(), 50e18);

        assertEq(ethPlays.orderDuration(), 20);

        assertEq(ethPlays.orderInputReward(), 10e18);
        assertEq(ethPlays.chaosInputReward(), 10e18);
        assertEq(ethPlays.chatCost(), 20e18);
        assertEq(ethPlays.rareCandyCost(), 200e18);

        assertEq(ethPlays.controlCooldownDuration(), 300);
        assertEq(ethPlays.controlAuctionDuration(), 60);
        assertEq(ethPlays.controlDuration(), 30);
    }

    function testSubmitAlignmentVoteNotRegistered() public {
        vm.startPrank(alice);
        vm.expectRevert(EthPlaysV0.AccountNotRegistered.selector);
        ethPlays.submitAlignmentVote(true);
    }

    function testSubmitAlignmentVote() public {
        registerAccounts();
        vm.startPrank(alice);

        // It updates the alignment value.
        ethPlays.submitAlignmentVote(true);
        assertEq(ethPlays.alignment(), 1000);

        // It reverts if the alignment cooldown has not passed.
        vm.expectRevert(EthPlaysV0.AlignmentVoteCooldown.selector);
        ethPlays.submitAlignmentVote(true);

        // It emits the AlignmentVote event and updates the alignment value with decay.
        vm.warp(block.timestamp + 60);
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit AlignmentVote(alice, true, 1985);
        ethPlays.submitAlignmentVote(true);
        assertEq(ethPlays.alignment(), 1985);

        // It mints chaosVoteReward POKE to the sender if voting for Chaos.
        skip(alignmentVoteCooldown + 1);
        ethPlays.submitAlignmentVote(false);
        assertEq(poke.balanceOf(alice), chaosVoteReward);
    }

    function testSubmitButtonInputNotRegistered() public {
        vm.startPrank(alice);
        vm.expectRevert(EthPlaysV0.AccountNotRegistered.selector);
        ethPlays.submitButtonInput(0);
    }

    function testSubmitButtonInputChaos() public {
        registerAccounts();
        vm.startPrank(alice);

        // It increments the inputIndex.
        assertEq(ethPlays.inputIndex(), 0);
        ethPlays.submitButtonInput(2);
        assertEq(ethPlays.inputIndex(), 1);

        // It emits the ButtonInput event.
        mine();
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit ButtonInput(1, alice, 5);
        ethPlays.submitButtonInput(5);

        // It mints reward tokens if first input from this account in this block.
        mine();
        vm.expectEmit(false, false, false, true, address(poke));
        emit Transfer(address(0), alice, chaosInputReward);
        ethPlays.submitButtonInput(6);
        assertEq(poke.balanceOf(alice), chaosInputReward * 3);

        // It doesn't mint reward tokens if second input from this account in this block.
        ethPlays.submitButtonInput(6);
        assertEq(poke.balanceOf(alice), chaosInputReward * 3);
    }

    function testSubmitButtonInputOrder() public {
        registerAccounts();
        vm.startPrank(alice);
        ethPlays.submitAlignmentVote(true);

        assertEq(ethPlays.inputIndex(), 0);

        // It executes the order ButtonInput
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit ButtonInput(0, alice, 2);
        ethPlays.submitButtonInput(2);
        assertEq(ethPlays.inputIndex(), 1);

        // It emits the InputVote event and mints orderInputReward to the sender
        mine();
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit InputVote(1, alice, 3);
        ethPlays.submitButtonInput(3);
        assertEq(poke.balanceOf(alice), orderInputReward);

        // It reverts if submitting for the 2nd time for the same inputIndex
        vm.expectRevert(EthPlaysV0.AlreadyVotedForThisInput.selector);
        ethPlays.submitButtonInput(4);
    }

    function testControlAuction() public {
        registerAccounts();
        dealPoke(alice, 100e18);
        vm.startPrank(alice);

        // It burns bid balance.
        ethPlays.submitControlBid(1e18);
        assertEq(poke.balanceOf(alice), 99e18);

        vm.stopPrank();
        dealPoke(bob, 100e18);
        vm.startPrank(bob);

        // It mints bid balance to the previous bidder when a new best bid is submitted.
        ethPlays.submitControlBid(3e18);
        assertEq(poke.balanceOf(alice), 100e18);
        assertEq(poke.balanceOf(bob), 97e18);

        vm.stopPrank();
        vm.startPrank(alice);

        // It emits the NewControlBid event.
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit NewControlBid(alice, 10e18);
        ethPlays.submitControlBid(10e18);

        vm.stopPrank();
        vm.startPrank(bob);

        // It reverts if the bid does not beat the current best bid.
        vm.expectRevert(EthPlaysV0.InsufficientBidAmount.selector);
        ethPlays.submitControlBid(5e18);

        // It reverts if the auction duration has passed.
        skip(controlAuctionDuration + 1);
        vm.expectRevert(EthPlaysV0.AuctionIsOver.selector);
        ethPlays.submitControlBid(12e18);

        // When submitting endControlAuction...
        // It succeeds and emits the event.
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit Control(alice);
        ethPlays.endControlAuction();

        // It reverts if the auction has no bids.
        vm.expectRevert(EthPlaysV0.AuctionHasNoBids.selector);
        ethPlays.endControlAuction();

        // It reverts if the auction has a bid but is still in progress.
        skip(controlCooldownDuration + 1);
        ethPlays.submitControlBid(1e18);
        vm.expectRevert(EthPlaysV0.AuctionInProgress.selector);
        ethPlays.endControlAuction();

        // It succeeds if the auction has a bid and auctionDuration has passed.
        skip(controlAuctionDuration + 1);
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit Control(bob);
        ethPlays.endControlAuction();
    }

    // TODO: testSubmitButtonInputOrder()
    // TODO: testSubmitButtonInputControl()

    // TODO: testSubmitChat()
    // TODO: testSubmitRareCandies()

    // TODO: testSetIsActive()
}
