// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Poke} from "src/Poke.sol";

contract PokeTest is Test {
    Poke poke;

    address deployer = address(0);
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    function setUp() public {
        poke = new Poke();
        deployer = address(this);
    }

    function testInitialGameAddress() public {
        assertEq(poke.gameContract(), address(0));
    }

    function testUpdateGameAddressAsOwner() public {
        hoax(deployer);
        poke.updateGameAddress(address(5));
        assertEq(poke.gameContract(), address(5));
    }

    function testUpdateGameAddressAsNotOwner() public {
        hoax(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        poke.updateGameAddress(address(5));
    }

    function testMintAsGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(bob);
        poke.gameMint(alice, 1e18);
        assertEq(poke.balanceOf(alice), 1e18);
    }

    function testMintAsNotGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(alice);
        vm.expectRevert(Poke.NotAuthorized.selector);
        poke.gameMint(alice, 1e18);
    }

    function testBurnAsGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(bob);
        poke.gameMint(alice, 3e18);
        hoax(bob);
        poke.gameBurn(alice, 1e18);
        assertEq(poke.balanceOf(alice), 2e18);
    }

    function testBurnAsNotGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(alice);
        vm.expectRevert(Poke.NotAuthorized.selector);
        poke.gameBurn(alice, 1e18);
    }

    function testTransferAsGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(bob);
        poke.gameMint(alice, 3e18);
        hoax(bob);
        poke.gameTransfer(alice, charlie, 1e18);
        assertEq(poke.balanceOf(alice), 2e18);
        assertEq(poke.balanceOf(charlie), 1e18);
    }

    function testTransferAsNotGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(alice);
        vm.expectRevert(Poke.NotAuthorized.selector);
        poke.gameTransfer(alice, charlie, 1e18);
    }
}
