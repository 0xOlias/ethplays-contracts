// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Poke} from "src/Poke.sol";

contract PokeTest is Test {
    Poke poke;

    address deployer = address(0);
    address constant bob = address(1);
    address constant alice = address(2);

    function setUp() public {
        poke = new Poke();

        deployer = address(this);
    }

    // Game contract behavior //

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
        poke.mint(alice, 1e18);
        assertEq(poke.balanceOf(alice), 1e18);
    }

    function testMintAsNotGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(alice);
        vm.expectRevert(Poke.NotAuthorized.selector);
        poke.mint(alice, 1e18);
    }

    function testBurnAsGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(bob);
        poke.mint(alice, 3e18);
        hoax(bob);
        poke.burn(alice, 1e18);
        assertEq(poke.balanceOf(alice), 2e18);
    }

    function testBurnAsNotGameContract() public {
        hoax(deployer);
        poke.updateGameAddress(bob);

        hoax(alice);
        vm.expectRevert(Poke.NotAuthorized.selector);
        poke.burn(alice, 1e18);
    }

    // Auction contract behavior //

    function testInitialAuctionAddress() public {
        assertEq(poke.auctionContract(), address(0));
    }

    function testUpdateAuctionAddressAsOwner() public {
        hoax(deployer);
        poke.updateAuctionAddress(address(5));
        assertEq(poke.auctionContract(), address(5));
    }

    function testUpdateAuctionAddressAsNotOwner() public {
        hoax(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        poke.updateAuctionAddress(address(5));
    }

    function testAllowanceAsAuctionAddress() public {
        hoax(deployer);
        poke.updateAuctionAddress(address(5));
        assertEq(poke.allowance(alice, address(5)), type(uint256).max);
    }

    function testAllowanceAsNotAuctionAddress() public {
        hoax(deployer);
        assertEq(poke.allowance(alice, address(5)), 0);
    }
}
