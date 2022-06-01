// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {Poke} from "src/Poke.sol";
import {EthPlays} from "src/EthPlays.sol";

contract DeployScript is Script {
    Poke poke;
    EthPlays ethPlays;

    function run() external {
        vm.startBroadcast();

        poke = new Poke();
        ethPlays = new EthPlays(address(poke));
        poke.updateGameAddress(address(ethPlays));
        vm.stopBroadcast();

        console.log("Poke deployed to", address(poke));
        console.log("EthPlays deployed to", address(ethPlays));
    }
}
