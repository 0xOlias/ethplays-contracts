// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";
import {Poke} from "src/Poke.sol";
import {EthPlaysV0} from "src/EthPlaysV0.sol";

contract DeployScript is Script {
    Poke poke;
    RegistryReceiverV0 registryReceiver;
    EthPlaysV0 ethPlays;

    function run() external {
        vm.startBroadcast();

        poke = new Poke();
        registryReceiver = new RegistryReceiverV0();
        ethPlays = new EthPlaysV0(address(poke), address(registryReceiver));
        poke.updateGameAddress(address(ethPlays));
        vm.stopBroadcast();

        console.log("Poke deployed to", address(poke));
        console.log(
            "RegistryReceiverV0 deployed to",
            address(registryReceiver)
        );
        console.log("EthPlaysV0 deployed to", address(ethPlays));
    }
}
