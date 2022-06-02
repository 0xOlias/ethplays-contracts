// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
// import "forge-std/console.sol";

import {Poke} from "src/Poke.sol";
import {EthPlaysChildRegistry} from "src/EthPlaysChildRegistry.sol";
import {EthPlays} from "src/EthPlays.sol";

contract IntegrationTest is Test {
    // Test storage
    Poke poke;
    EthPlaysChildRegistry registry;
    EthPlays ethPlays;

    address deployer;
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    // EthPlays parameters
    uint256 orderReward;
    uint256 chaosReward;

    // Poke events
    event Transfer(address indexed from, address indexed to, uint256 value);

    // EthPlays events
    event AlignmentVote(address from, bool vote, int256 alignment);
    event ButtonInput(uint256 inputIndex, address from, uint256 buttonIndex);

    function setUp() public {
        deployer = address(this);
        poke = new Poke();
        registry = new EthPlaysChildRegistry();
        ethPlays = new EthPlays(address(poke), address(registry));
        poke.updateGameAddress(address(ethPlays));
        vm.roll(1);
        vm.warp(1000);

        // Bind EthPlays parameters.
        orderReward = ethPlays.orderReward();
        chaosReward = ethPlays.chaosReward();
    }

    function registerAccounts() public {
        registry.submitRegistration(address(10), alice);
        registry.submitRegistration(address(20), bob);
        registry.submitRegistration(address(30), charlie);
    }

    function mine() public {
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 2);
    }

    function testInitialParameters() public {
        assertEq(poke.gameContract(), address(ethPlays));
        assertEq(address(ethPlays.poke()), address(poke));
        assertEq(address(ethPlays.registry()), address(registry));

        assertEq(ethPlays.isActive(), true);
        assertEq(ethPlays.alignmentDecayRate(), 985);
        assertEq(ethPlays.orderDuration(), 20);

        assertEq(ethPlays.rewardTierSize(), 100);
        assertEq(ethPlays.orderReward(), 10e18);
        assertEq(ethPlays.chaosReward(), 20e18);
        assertEq(ethPlays.chatCost(), 10e18);
        assertEq(ethPlays.rareCandyCost(), 200e18);

        assertEq(ethPlays.bannerAuctionCooldown(), 120);
        assertEq(ethPlays.bannerAuctionDuration(), 60);

        assertEq(ethPlays.controlAuctionCooldown(), 300);
        assertEq(ethPlays.controlAuctionDuration(), 60);
        assertEq(ethPlays.controlDuration(), 30);
    }

    function testSubmitAlignmentVoteNotRegistered() public {
        hoax(alice);
        vm.expectRevert(EthPlays.AccountNotRegistered.selector);
        ethPlays.submitAlignmentVote(true);
    }

    function testSubmitAlignmentVote() public {
        registerAccounts();
        startHoax(alice);

        // It updates the alignment value.
        ethPlays.submitAlignmentVote(true);
        assertEq(ethPlays.alignment(), 1000);

        // It reverts if the alignment cooldown has not passed.
        vm.expectRevert(EthPlays.AlignmentVoteCooldown.selector);
        ethPlays.submitAlignmentVote(true);

        // It emits the AlignmentVote event and updates the alignment value with decay.
        vm.warp(block.timestamp + 60);
        vm.expectEmit(false, false, false, true, address(ethPlays));
        emit AlignmentVote(alice, true, 1985);
        ethPlays.submitAlignmentVote(true);
        assertEq(ethPlays.alignment(), 1985);
    }

    function testSubmitButtonInputNotRegistered() public {
        hoax(alice);
        vm.expectRevert(EthPlays.AccountNotRegistered.selector);
        ethPlays.submitButtonInput(0);
    }

    function testSubmitButtonInputChaos() public {
        registerAccounts();
        startHoax(alice);

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
        emit Transfer(address(0), alice, chaosReward);
        ethPlays.submitButtonInput(6);
        assertEq(poke.balanceOf(alice), chaosReward * 3);

        // It doesn't mint reward tokens if second input from this account in this block.
        ethPlays.submitButtonInput(6);
        assertEq(poke.balanceOf(alice), chaosReward * 3);
    }

    // TODO: testSubmitButtonInputOrder()
    // TODO: testSubmitButtonInputControl()

    // TODO: testSubmitChat()
    // TODO: testSubmitRareCandies()

    // TODO: testSubmitBannerBid()
    // TODO: testRolloverBannerAuction()

    // TODO: testSubmitControlBid()
    // TODO: testRolloverControlAuction()

    // TODO: testSetIsActive()
}
