// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {Poke} from "src/Poke.sol";
import {RegistryReceiverV0} from "src/RegistryReceiverV0.sol";

/// @title An experiment in collaborative gaming
/// @author olias.eth
/// @notice This is experimental software, use at your own risk.
contract EthPlaysV0 is Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   STRUCTS                                  */
    /* -------------------------------------------------------------------------- */

    struct ControlBid {
        address from;
        uint256 amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice [Contract] The POKE token contract
    Poke public poke;
    /// @notice [Contract] The EthPlays registry contract
    RegistryReceiverV0 public registry;

    /// @notice [Parameter] Indicates if the game is currently active
    bool public isActive;

    /// @notice [State] The index of the last executed input
    uint256 public inputIndex;
    /// @notice [State] The block timestamp of the previous input
    uint256 private inputTimestamp;

    /// @notice [Parameter] The fraction of alignment to persist upon decay, out of 1000
    uint256 public alignmentDecayRate;
    /// @notice [Parameter] Number of seconds between alignment votes for each account
    uint256 public alignmentVoteCooldown;
    /// @notice [Parameter] The current reward (in POKE) for voting for chaos
    uint256 public chaosVoteReward;
    /// @notice [State] Timestamp of latest alignment vote by account address
    mapping(address => uint256) private alignmentVoteTimestamps;
    /// @notice [State] The current alignment value
    int256 public alignment;

    /// @notice [Parameter] Number of seconds in the order vote period
    uint256 public orderDuration;
    /// @notice [State] Count of order votes for each button index, by input index
    uint256[8] private orderVotes;

    /// @notice [State] Most recent inputIndex at which an account submitted an input
    mapping(address => uint256) private inputIndices;
    /// @notice [State] Most recent block in which an account submitted an input
    mapping(address => uint256) private inputBlocks;

    /// @notice [Parameter] The current reward (in POKE) for chaos inputs
    uint256 public chaosInputReward;
    /// @notice [Parameter] The current reward (in POKE) for order input votes
    uint256 public orderInputReward;
    /// @notice [Parameter] The current cost (in POKE) to submit a chat message
    uint256 public chatCost;
    /// @notice [Parameter] The current cost (in POKE) to buy a rare candy
    uint256 public rareCandyCost;

    /// @notice [Parameter] The number of seconds that the control auction lasts
    uint256 public controlAuctionDuration;
    /// @notice [Parameter] The number of seconds that control lasts
    uint256 public controlDuration;
    /// @notice [State] The best bid for the current control auction
    ControlBid private bestControlBid;
    /// @notice [State] The block timestamp of the start of the current control auction
    uint256 public controlAuctionTimestamp;
    /// @notice [State] The account that has (or most recently had) control
    address public controlAddress;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    // Gameplay events
    event AlignmentVote(address from, bool vote, int256 alignment);
    event InputVote(uint256 inputIndex, address from, uint256 buttonIndex);
    event ButtonInput(uint256 inputIndex, address from, uint256 buttonIndex);
    event Chat(address from, string message);
    event RareCandy(address from, uint256 count);

    // Auction events
    event NewControlBid(address from, uint256 amount);
    event Control(address from);

    // Parameter update events
    event SetIsActive(bool isActive);
    event SetAlignmentDecayRate(uint256 alignmentDecayRate);
    event SetChaosVoteReward(uint256 chaosVoteReward);
    event SetOrderDuration(uint256 orderDuration);
    event SetChaosInputReward(uint256 chaosInputReward);
    event SetOrderInputReward(uint256 orderInputReward);
    event SetChatCost(uint256 chatCost);
    event SetRareCandyCost(uint256 rareCandyCost);
    event SetControlCooldownDuration(uint256 controlCooldownDuration);
    event SetControlAuctionDuration(uint256 controlAuctionDuration);
    event SetControlDuration(uint256 controlDuration);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    // Gameplay errors
    error GameNotActive();
    error AccountNotRegistered();
    error InvalidButtonIndex();
    error OtherPlayerHasControl();
    error AlreadyVotedForThisInput();
    error AlignmentVoteCooldown();

    // Redeem errors
    error InsufficientBalanceForRedeem();

    // Auction errors
    error InsufficientBalanceForBid();
    error InsufficientBidAmount();
    error AuctionInProgress();
    error AuctionIsOver();
    error AuctionHasNoBids();

    /* -------------------------------------------------------------------------- */
    /*                                 MODIFIERS                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Requires the game to be active.
    modifier onlyActive() {
        if (!isActive) {
            revert GameNotActive();
        }
        _;
    }

    /// @notice Requires the sender to be a registered account.
    modifier onlyRegistered() {
        if (!registry.isRegistered(msg.sender)) {
            revert AccountNotRegistered();
        }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor(address pokeAddress, address registryAddress) {
        poke = Poke(pokeAddress);
        registry = RegistryReceiverV0(registryAddress);

        isActive = true;

        alignmentVoteCooldown = 30;
        alignmentDecayRate = 985;
        chaosVoteReward = 50e18;

        orderDuration = 20;

        chaosInputReward = 10e18;
        orderInputReward = 10e18;
        chatCost = 20e18;
        rareCandyCost = 200e18;

        controlAuctionDuration = 300;
        controlDuration = 30;
        bestControlBid = ControlBid(address(0), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  GAMEPLAY                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Submit an alignment vote.
    /// @param _alignmentVote The alignment vote. True corresponds to order, false to chaos.
    function submitAlignmentVote(bool _alignmentVote)
        external
        onlyActive
        onlyRegistered
    {
        if (
            block.timestamp <
            alignmentVoteTimestamps[msg.sender] + alignmentVoteCooldown
        ) {
            revert AlignmentVoteCooldown();
        }

        // Mint tokens to the sender if the vote is for Chaos.
        if (!_alignmentVote) {
            poke.gameMint(msg.sender, chaosVoteReward);
        }

        // Apply alignment decay.
        alignment *= int256(alignmentDecayRate);
        alignment /= int256(1000);

        // Apply sender alignment update.
        alignment += _alignmentVote ? int256(1000) : -1000;

        alignmentVoteTimestamps[msg.sender] = block.timestamp;
        emit AlignmentVote(msg.sender, _alignmentVote, alignment);
    }

    /// @notice Submit a button input.
    /// @param buttonIndex The index of the button input. Must be between 0 and 7.
    function submitButtonInput(uint256 buttonIndex)
        external
        onlyActive
        onlyRegistered
    {
        if (buttonIndex > 7) {
            revert InvalidButtonIndex();
        }

        if (block.timestamp <= controlAuctionTimestamp + controlDuration) {
            // Control
            if (msg.sender != controlAddress) {
                revert OtherPlayerHasControl();
            }

            inputTimestamp = block.timestamp;
            emit ButtonInput(inputIndex, msg.sender, buttonIndex);
            inputIndex++;
        } else if (alignment > 0) {
            // Order

            orderVotes[buttonIndex]++;

            // If orderDuration seconds have passed since the previous input, execute.
            if (block.timestamp >= inputTimestamp + orderDuration) {
                uint256 bestButtonIndex = 0;
                uint256 bestButtonIndexVoteCount = 0;

                for (uint256 i = 0; i < 8; i++) {
                    if (orderVotes[i] > bestButtonIndexVoteCount) {
                        bestButtonIndex = i;
                        bestButtonIndexVoteCount = orderVotes[i];
                    }
                    orderVotes[i] = 0;
                }

                inputTimestamp = block.timestamp;
                emit ButtonInput(inputIndex, msg.sender, bestButtonIndex);
                inputIndex++;
            } else {
                if (inputIndex == inputIndices[msg.sender]) {
                    revert AlreadyVotedForThisInput();
                }
                inputIndices[msg.sender] = inputIndex;

                poke.gameMint(msg.sender, orderInputReward);
                emit InputVote(inputIndex, msg.sender, buttonIndex);
            }
        } else {
            // Chaos
            if (block.number > inputBlocks[msg.sender]) {
                poke.gameMint(msg.sender, chaosInputReward);
            }
            inputBlocks[msg.sender] = block.number;

            inputTimestamp = block.timestamp;
            emit ButtonInput(inputIndex, msg.sender, buttonIndex);
            inputIndex++;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  REDEEMS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Submit an message to the chat.
    /// @param message The chat message.
    function submitChat(string memory message)
        external
        onlyActive
        onlyRegistered
    {
        if (poke.balanceOf(msg.sender) < chatCost) {
            revert InsufficientBalanceForRedeem();
        }

        poke.gameBurn(msg.sender, chatCost);
        emit Chat(msg.sender, message);
    }

    /// @notice Submit a request to purchase rare candies.
    /// @param count The number of rare candies to be purchased.
    function submitRareCandies(uint256 count)
        external
        onlyActive
        onlyRegistered
    {
        uint256 totalCost = rareCandyCost * count;

        if (poke.balanceOf(msg.sender) < totalCost) {
            revert InsufficientBalanceForRedeem();
        }

        poke.gameBurn(msg.sender, totalCost);
        emit RareCandy(msg.sender, count);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  AUCTIONS                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Submit a bid in the active control auction.
    /// @param amount The bid amount in POKE
    function submitControlBid(uint256 amount)
        external
        onlyActive
        onlyRegistered
    {
        // This is the first bid in the auction, so set controlAuctionStartTimestamp.
        if (bestControlBid.from == address(0)) {
            controlAuctionTimestamp = block.timestamp;
        }

        // The auction is over (it must be ended).
        if (
            block.timestamp > controlAuctionTimestamp + controlAuctionDuration
        ) {
            revert AuctionIsOver();
        }

        if (poke.balanceOf(msg.sender) < amount) {
            revert InsufficientBalanceForBid();
        }

        if (amount <= bestControlBid.amount) {
            revert InsufficientBidAmount();
        }

        // If there was a previous best bid, return the bid amount to the account that submitted it.
        if (bestControlBid.from != address(0)) {
            poke.gameMint(bestControlBid.from, bestControlBid.amount);
        }
        poke.gameBurn(msg.sender, amount);
        bestControlBid = ControlBid(msg.sender, amount);
        emit NewControlBid(msg.sender, amount);
    }

    /// @notice End the current control auction and start the cooldown for the next one.
    function endControlAuction() external onlyActive {
        if (
            block.timestamp < controlAuctionTimestamp + controlAuctionDuration
        ) {
            revert AuctionInProgress();
        }

        if (bestControlBid.from == address(0)) {
            revert AuctionHasNoBids();
        }

        emit Control(bestControlBid.from);
        controlAddress = bestControlBid.from;
        bestControlBid = ControlBid(address(0), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ADMIN                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Set the isActive parameter. Owner only.
    /// @param _isActive New value for the isActive parameter
    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
        emit SetIsActive(_isActive);
    }

    function setAlignmentDecayRate(uint256 _alignmentDecayRate)
        external
        onlyOwner
    {
        alignmentDecayRate = _alignmentDecayRate;
        emit SetAlignmentDecayRate(_alignmentDecayRate);
    }

    function setOrderDuration(uint256 _orderDuration) external onlyOwner {
        orderDuration = _orderDuration;
        emit SetOrderDuration(_orderDuration);
    }

    function setChaosVoteReward(uint256 _chaosVoteReward) external onlyOwner {
        chaosVoteReward = _chaosVoteReward;
        emit SetChaosVoteReward(_chaosVoteReward);
    }

    function setChaosInputReward(uint256 _chaosInputReward) external onlyOwner {
        chaosInputReward = _chaosInputReward;
        emit SetChaosInputReward(_chaosInputReward);
    }

    function setOrderInputReward(uint256 _orderInputReward) external onlyOwner {
        orderInputReward = _orderInputReward;
        emit SetOrderInputReward(_orderInputReward);
    }

    function setChatCost(uint256 _chatCost) external onlyOwner {
        chatCost = _chatCost;
        emit SetChatCost(_chatCost);
    }

    function setRareCandyCost(uint256 _rareCandyCost) external onlyOwner {
        rareCandyCost = _rareCandyCost;
        emit SetRareCandyCost(_rareCandyCost);
    }

    function setControlAuctionDuration(uint256 _controlAuctionDuration)
        external
        onlyOwner
    {
        controlAuctionDuration = _controlAuctionDuration;
        emit SetControlAuctionDuration(_controlAuctionDuration);
    }

    function setControlDuration(uint256 _controlDuration) external onlyOwner {
        controlDuration = _controlDuration;
        emit SetControlDuration(_controlDuration);
    }
}
