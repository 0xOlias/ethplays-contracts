// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Poke} from "src/Poke.sol";
import {EthPlays} from "src/EthPlays.sol";

contract IntegrationTest is Test {
    Poke poke;
    EthPlays ethPlays;

    address deployer;
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    function setUp() public {
        poke = new Poke();
        ethPlays = new EthPlays(address(poke));
        poke.updateGameAddress(address(ethPlays));
        deployer = address(this);
    }

    function testInitialParameters() public {
        assertEq(poke.gameContract(), address(ethPlays));
        assertEq(address(ethPlays.poke()), address(poke));

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
}
