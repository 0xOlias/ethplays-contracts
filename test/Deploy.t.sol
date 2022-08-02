// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Registry} from "src/Registry.sol";
import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";
import {Poke} from "src/Poke.sol";
import {EthPlaysV0} from "src/EthPlaysV0.sol";

contract Deploy is Test {
    Registry registry;
    RegistryReceiverV0 registryReceiver;
    Poke poke;
    EthPlaysV0 ethPlays;

    function testDeploy() external {
        registry = new Registry();
        assertEq(registry.isActive(), true);
        assertEq(registry.registrationFee(), 0.1 ether);

        registryReceiver = new RegistryReceiverV0();

        poke = new Poke();

        ethPlays = new EthPlaysV0(poke, registryReceiver);
        assertEq(ethPlays.isActive(), true);
        assertEq(address(ethPlays.poke()), address(poke));
        assertEq(
            address(ethPlays.registryReceiver()),
            address(registryReceiver)
        );

        poke.setGameAddress(address(ethPlays));
        assertEq(poke.gameAddress(), address(ethPlays));
    }
}
