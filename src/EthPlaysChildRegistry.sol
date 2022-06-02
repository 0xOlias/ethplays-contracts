// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Child registry for EthPlays
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract EthPlaysChildRegistry is Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice [State] Registered account addresses by burner account address
    mapping(address => address) public accounts;
    /// @notice [State] Burner account addresses by registered account address
    mapping(address => address) public burnerAccounts;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event Registration(address account, address burnerAccount);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor() {}

    /* -------------------------------------------------------------------------- */
    /*                                REGISTRATION                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Registers a new account to burner account mapping. Owner only.
    /// @param account The address of the players main account
    /// @param burnerAccount The address of the players burner account
    function submitRegistration(address account, address burnerAccount)
        external
        onlyOwner
    {
        address previousBurnerAccount = burnerAccounts[account];
        if (previousBurnerAccount != address(0)) {
            // This is a re-registration. Must unregister the old burner account.
            accounts[previousBurnerAccount] = address(0);
        }

        accounts[burnerAccount] = account;
        burnerAccounts[account] = burnerAccount;

        emit Registration(account, burnerAccount);
    }
}
