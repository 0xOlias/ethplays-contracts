// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Poke} from "src/Poke.sol";
import {EthPlays} from "src/EthPlays.sol";

contract PokeTest is Test {
    Poke poke;
    EthPlays ethPlays;

    address deployer;
    address constant bob = address(1);
    address constant alice = address(2);

    function setUp() public {
        poke = new Poke();

        ethPlays = new EthPlays(address(poke));

        deployer = address(this);
    }

    // Game contract behavior //

    function testInitialParameters() public {
        assertEq(poke.gameContract(), address(0));
    }
}
