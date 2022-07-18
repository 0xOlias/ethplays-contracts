// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Registry} from "src/Registry.sol";
import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";
import {Poke} from "src/Poke.sol";
import {EthPlaysV0} from "src/EthPlaysV0.sol";

contract Deploy is Script {
    Registry registry;
    RegistryReceiverV0 registryReceiver;
    Poke poke;
    EthPlaysV0 ethPlays;

    function run() external {
        vm.startBroadcast(vm.envAddress("ACCOUNT_0"));
        registry = new Registry();
        vm.stopBroadcast();
        console.log("REGISTRY_ADDRESS", address(registry));

        vm.startBroadcast(vm.envAddress("ACCOUNT_1"));
        registryReceiver = new RegistryReceiverV0();
        vm.stopBroadcast();
        console.log("REGISTRYRECEIVERV0_ADDRESS", address(registryReceiver));

        vm.startBroadcast(vm.envAddress("ACCOUNT_2"));
        poke = new Poke();
        vm.stopBroadcast();
        console.log("POKE_ADDRESS", address(poke));

        vm.startBroadcast(vm.envAddress("ACCOUNT_3"));
        ethPlays = new EthPlaysV0(address(poke), address(registryReceiver));
        vm.stopBroadcast();
        console.log("ETHPLAYSVO_ADDRESS", address(ethPlays));
    }
}
