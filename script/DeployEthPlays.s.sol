// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {EthPlaysV0} from "src/EthPlaysV0.sol";

contract DeployEthPlays is Script {
    EthPlaysV0 ethPlays;

    address pokeAddress = 0x8464135c8F25Da09e49BC8782676a84730C318bC;
    address registryReceiverAddress =
        0x663F3ad617193148711d28f5334eE4Ed07016602;

    function run() external {
        vm.startBroadcast();
        ethPlays = new EthPlaysV0(pokeAddress, registryReceiverAddress);
        vm.stopBroadcast();
        console.log("REGISTRYRECEIVERV0_ADDRESS=", address(ethPlays));
    }
}
