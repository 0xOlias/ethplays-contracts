// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";

contract RegistryReceiverV0Test is Test {
    RegistryReceiverV0 registry;

    address deployer;
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    event NewRegistration(address account, address burnerAccount);
    event UpdatedRegistration(
        address account,
        address burnerAccount,
        address previousBurnerAccount
    );

    function setUp() public {
        deployer = address(this);
        registry = new RegistryReceiverV0();
    }

    function testSubmitRegistration() public {
        hoax(deployer);
        registry.submitRegistration(address(10), alice);
        assertEq(registry.accounts(alice), address(10));
        assertEq(registry.burnerAccounts(address(10)), alice);

        hoax(deployer);
        vm.expectEmit(false, false, false, true, address(registry));
        emit NewRegistration(address(20), bob);
        registry.submitRegistration(address(20), bob);

        hoax(deployer);
        vm.expectEmit(false, false, false, true, address(registry));
        emit UpdatedRegistration(address(20), charlie, bob);
        registry.submitRegistration(address(20), charlie);
    }

    function testSubmitRegistrationAsNotOwner() public {
        hoax(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.submitRegistration(address(10), alice);
    }
}
