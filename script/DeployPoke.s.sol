// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Poke} from "src/Poke.sol";

contract DeployPoke is Script {
    Poke poke;

    function run() external {
        vm.startBroadcast();
        poke = new Poke();
        vm.stopBroadcast();
        console.log("POKE_ADDRESS=", address(poke));
    }
}
