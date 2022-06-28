// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Registry} from "src/Registry.sol";

contract DeployRegistry is Script {
    Registry registry;

    function run() external {
        vm.startBroadcast();
        registry = new Registry();
        vm.stopBroadcast();
        console.log("REGISTRY_ADDRESS=", address(registry));
    }
}
