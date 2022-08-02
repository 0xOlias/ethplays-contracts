// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Registry} from "src/Registry.sol";

contract RegistryTest is Test {
    Registry registry;

    address deployer;
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    event NewRegistration(address account, address burnerAccount);
    event UpdatedRegistration(address account, address burnerAccount);

    function setUp() public {
        deployer = address(this);
        registry = new Registry();

        vm.deal(deployer, 1 ether);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(charlie, 1 ether);
    }

    function testRegister() public {
        // it reverts if registration is not active
        vm.startPrank(deployer);
        registry.setIsActive(false);
        vm.expectRevert(Registry.RegistrationNotActive.selector);
        registry.register(address(10));
        registry.setIsActive(true);

        // it reverts if the fee is incorrect
        vm.stopPrank();
        vm.startPrank(alice);
        vm.expectRevert(Registry.IncorrectRegistrationFee.selector);
        registry.register(address(10));

        // it emits the event and sets the accounts in storage if successful
        vm.expectEmit(false, false, false, true, address(registry));
        emit NewRegistration(alice, address(11));
        registry.register{value: 0.1 ether}(address(11));
        assertEq(registry.accounts(address(11)), alice);
        assertEq(registry.burnerAccounts(alice), address(11));

        // it reverts if the sender is already registered
        vm.expectRevert(Registry.AccountAlreadyRegistered.selector);
        registry.register{value: 0.1 ether}(address(12));

        // it reverts if the burner account is already taken
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(Registry.BurnerAccountAlreadyRegistered.selector);
        registry.register{value: 0.1 ether}(address(11));
    }

    function testUpdateBurnerAccount() public {
        // it reverts if registration is not active
        vm.startPrank(deployer);
        registry.setIsActive(false);
        vm.expectRevert(Registry.RegistrationNotActive.selector);
        registry.updateBurnerAccount(address(10));
        registry.setIsActive(true);

        // it reverts if the sender is not already registered
        vm.stopPrank();
        vm.startPrank(alice);
        vm.expectRevert(Registry.AccountNotRegistered.selector);
        registry.updateBurnerAccount(address(12));

        // it emits the event and sets the accounts in storage if successful
        registry.register{value: 0.1 ether}(address(10));
        vm.expectEmit(false, false, false, true, address(registry));
        emit UpdatedRegistration(alice, address(11));
        registry.updateBurnerAccount(address(11));
        assertEq(registry.accounts(address(11)), alice);
        assertEq(registry.burnerAccounts(alice), address(11));

        // it reverts if the burner account is already taken
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(Registry.BurnerAccountAlreadyRegistered.selector);
        registry.updateBurnerAccount(address(11));
    }

    function testSetIsActive() public {
        // it reverts if the sender is not the owner
        hoax(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.setIsActive(false);

        // it sets the game as inactive if successful
        hoax(deployer);
        registry.setIsActive(false);
        assertEq(registry.isActive(), false);
    }

    function testSetRegistrationFee() public {
        // it reverts if the sender is not the owner
        hoax(charlie);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.setIsActive(false);

        hoax(deployer);
        registry.setRegistrationFee(0.05 ether);
        assertEq(registry.registrationFee(), 0.05 ether);

        hoax(alice);
        vm.expectEmit(false, false, false, true, address(registry));
        emit NewRegistration(alice, address(10));
        registry.register{value: 0.05 ether}(address(10));
    }
}
