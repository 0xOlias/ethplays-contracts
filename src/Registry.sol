// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title Mainnet registration contract for EthPlays
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract Registry is Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Registered account addresses by burner account address
    mapping(address => address) public accounts;
    /// @notice Burner account addresses by registered account address
    mapping(address => address) public burnerAccounts;

    /// @notice Registration fee amount in ether
    uint256 public registrationFeeAmount;

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
    error InsufficientRegistrationFee();

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor() {
        registrationFeeAmount = 0.01 ether;
    }

    /* -------------------------------------------------------------------------- */
    /*                                REGISTRATION                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Register for EthPlays.
    /// @param burnerAccount The address of the burner account to be registered.
    function register(address burnerAccount) external payable {
        if (accounts[burnerAccount] != address(0)) {
            revert BurnerAccountTaken();
        }

        if (burnerAccounts[msg.sender] != address(0)) {
            revert AlreadyRegistered();
        }

        if (msg.value < registrationFeeAmount) {
            revert InsufficientRegistrationFee();
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
    /*                                   ADMIN                                    */
    /* -------------------------------------------------------------------------- */

    function setRegistrationFeeAmount(uint256 _registrationFeeAmount) external onlyOwner {
        registrationFeeAmount = _registrationFeeAmount;
    }

    // ???
    // function withdrawEther(address withdrawToAccount) external onlyOwner {
    //     _account.call{value: this.value}()
    // }

    // function withdrawERC20(address withdrawToAccount, address token) external onlyOwner {
    //     _account.call{value: this.value}()
    // }

    // function withdrawERC721(address withdrawToAccount, address token) external onlyOwner {
    //     _account.call{value: this.value}()
    // }
}
