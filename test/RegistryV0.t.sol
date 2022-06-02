// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {RegistryV0} from "src/RegistryV0.sol";

contract RegistryV0Test is Test {
    RegistryV0 registry;

    address deployer;
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    event Registration(address account, address burnerAccount);

    function setUp() public {
        deployer = address(this);
        registry = new RegistryV0();
    }

    function testSubmitRegistration() public {
        hoax(deployer);
        registry.submitRegistration(address(10), alice);
        assertEq(registry.accounts(alice), address(10));
        assertEq(registry.burnerAccounts(address(10)), alice);

        hoax(deployer);
        vm.expectEmit(false, false, false, true, address(registry));
        emit Registration(address(20), bob);
        registry.submitRegistration(address(20), bob);
    }

    function testSubmitRegistrationAsNotOwner() public {
        hoax(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.submitRegistration(address(10), alice);
    }
}
