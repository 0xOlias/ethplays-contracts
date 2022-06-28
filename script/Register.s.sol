// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Registry} from "src/Registry.sol";

contract Register is Script {
    Registry registry = Registry(0x5FbDB2315678afecb367f032d93F642f64180aa3);

    function run() external {
        bytes32 ensNameHash = bytes32(0);
        address burnerAccount1 = 0x90D562D6026dd2132c696dBC83c9905978837a2c;
        address burnerAccount2 = 0x90D562D6026DD2132c696DBc83C9905978837a2D;
        address burnerAccount3 = 0x90D562d6026dd2132c696dbc83C9905978837a2e;
        address burnerAccount4 = 0x90d562D6026DD2132c696DBc83c9905978837A2F;

        vm.startBroadcast();
        registry.register(ensNameHash, burnerAccount1);
        registry.updateBurnerAccount(burnerAccount2);
        registry.updateBurnerAccount(burnerAccount3);
        registry.updateBurnerAccount(burnerAccount4);
        vm.stopBroadcast();
    }
}
