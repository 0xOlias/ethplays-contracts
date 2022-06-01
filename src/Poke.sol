// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title An experiment in collaborative gaming
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract Poke is ERC20, Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Address of the current game contract
    address public gameContract;
    /// @notice Address of the current auction contract
    address public auctionContract;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event UpdateGameContract(address gameContract);
    event UpdateAuctionContract(address auctionContract);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    error NotAuthorized();

    /* -------------------------------------------------------------------------- */
    /*                                 MODIFIERS                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Requires the sender to be  the game contract
    modifier onlyGameContract() {
        if (msg.sender != gameContract) {
            revert NotAuthorized();
        }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor() ERC20("ethplays", "POKE") {}

    /* -------------------------------------------------------------------------- */
    /*                                 OVERRIDES                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Allow auction contract to spend any amount of tokens.
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        if (spender == auctionContract) return type(uint256).max;
        return super.allowance(owner, spender);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GAME                                     */
    /* -------------------------------------------------------------------------- */

    /// @notice Mint new tokens to an account. Can only be called by the game contract.
    /// @param account The account to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address account, uint256 amount) external onlyGameContract {
        _mint(account, amount);
    }

    /// @notice Burn existing tokens belonging to an account. Can only be called by the game contract.
    /// @param account The account to burn tokens for
    /// @param amount The amount of tokens to burn
    function burn(address account, uint256 amount) external onlyGameContract {
        _burn(account, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   OWNER                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Update the game contract address. Only owner.
    /// @param addr The address of the game contract
    function updateGameAddress(address addr) external onlyOwner {
        gameContract = addr;
    }

    /// @notice Update the auction contract address. Only owner.
    /// @param addr The address of the auction contract
    function updateAuctionAddress(address addr) external onlyOwner {
        auctionContract = addr;
    }
}
