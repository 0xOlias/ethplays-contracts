// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";

contract DeployRegistryReceiver is Script {
    RegistryReceiverV0 registryReceiver;

    function run() external {
        vm.startBroadcast();
        registryReceiver = new RegistryReceiverV0();
        vm.stopBroadcast();
        console.log("REGISTRYRECEIVERV0_ADDRESS=", address(registryReceiver));
    }
}
