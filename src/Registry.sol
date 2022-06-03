// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public view virtual returns (address);
}

/// @title Mainnet registration contract for EthPlays
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract Registry is Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    ENS public constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Indicates if an ENS name is currently required for registration
    bool public ensRequired;
    /// @notice Registered account addresses by burner account address
    mapping(address => address) public accounts;
    /// @notice Burner account addresses by registered account address
    mapping(address => address) public burnerAccounts;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Register(address account, address burnerAccount);
    event UpdateBurnerAccount(address account, address burnerAccount);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    error BurnerAccountTaken();
    error AlreadyRegistered();
    error NotYetRegistered();
    error InvalidEnsNameHash();

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor() {
        ensRequired = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                                REGISTRATION                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Register for EthPlays.
    /// @param ensNameHash An ENS namehash that must resolve to the sender's address.
    /// @param burnerAccount The address of the burner account to be registered.
    function register(bytes32 ensNameHash, address burnerAccount) external {
        if (accounts[burnerAccount] != address(0)) {
            revert BurnerAccountTaken();
        }

        if (burnerAccounts[msg.sender] != address(0)) {
            revert AlreadyRegistered();
        }

        if (ensRequired && msg.sender != resolve(ensNameHash)) {
            revert InvalidEnsNameHash();
        }

        accounts[burnerAccount] = msg.sender;
        burnerAccounts[msg.sender] = burnerAccount;

        emit Register(msg.sender, burnerAccount);
    }

    /// @notice Update registered burner account address.
    /// @param burnerAccount The address of the new burner account to be registered.
    function updateBurnerAccount(address burnerAccount) external {
        if (accounts[burnerAccount] != address(0)) {
            revert BurnerAccountTaken();
        }

        if (burnerAccounts[msg.sender] == address(0)) {
            revert NotYetRegistered();
        }

        accounts[burnerAccount] = msg.sender;
        burnerAccounts[msg.sender] = burnerAccount;

        emit UpdateBurnerAccount(msg.sender, burnerAccount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  HELPERS                                   */
    /* -------------------------------------------------------------------------- */

    function resolve(bytes32 node) internal view returns (address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ADMIN                                    */
    /* -------------------------------------------------------------------------- */

    function setEnsRequired(bool _ensRequired) external onlyOwner {
        ensRequired = _ensRequired;
    }
}
