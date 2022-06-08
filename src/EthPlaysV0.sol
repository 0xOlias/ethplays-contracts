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
    /*                                   TYPES                                    */
    /* -------------------------------------------------------------------------- */

    struct BannerBid {
        address from;
        uint256 amount;
        string message;
    }

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
    /// @notice [State] Timestamp of latest alignment vote by account address
    mapping(address => uint256) private alignmentVoteTimestamps;
    /// @notice [State] The current alignment value
    int256 public alignment;

    /// @notice [Parameter] Number of seconds in the order vote period
    uint256 public orderDuration;
    /// @notice [State] Count of order votes for each button index, by input index
    uint256[8] private orderVotes;

    /// @notice [State] Total number of inputs an account has made
    mapping(address => uint256) private inputNonces;
    /// @notice [State] Most recent block in which an account submitted an input
    mapping(address => uint256) private inputBlocks;

    /// @notice [Parameter] The number of inputs in each reward tier
    uint256 public rewardTierSize;
    /// @notice [Parameter] The current reward (in POKE) for chaos inputs
    uint256 public chaosReward;
    /// @notice [Parameter] The current reward (in POKE) for order input votes
    uint256 public orderReward;
    /// @notice [Parameter] The current cost (in POKE) to submit a chat message
    uint256 public chatCost;
    /// @notice [Parameter] The current cost (in POKE) to buy a rare candy
    uint256 public rareCandyCost;

    /// @notice [Parameter] The number of seconds between banner auctions
    uint256 public bannerAuctionCooldown;
    /// @notice [Parameter] The number of seconds that the banner auction lasts
    uint256 public bannerAuctionDuration;
    /// @notice [State] The best bid for the current banner auction
    BannerBid private bestBannerBid;
    /// @notice [State] The block timestamp of the start of the current banner auction
    uint256 private bannerAuctionTimestamp;

    /// @notice [Parameter] The number of seconds between control auctions
    uint256 public controlAuctionCooldown;
    /// @notice [Parameter] The number of seconds that the control auction lasts
    uint256 public controlAuctionDuration;
    /// @notice [Parameter] The number of seconds that control lasts
    uint256 public controlDuration;
    /// @notice [State] The best bid for the current control auction
    ControlBid private bestControlBid;
    /// @notice [State] The block timestamp of the start of the current control auction
    uint256 private controlAuctionTimestamp;
    /// @notice [State] The account that has (or most recently had) control
    address private controlAddress;

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
    event NewBannerBid(address from, uint256 amount, string message);
    event Banner(address from, string message);
    event NewControlBid(address from, uint256 amount);
    event Control(address from);

    // Parameter update events
    event SetIsActive(bool isActive);
    event SetAlignmentDecayRate(uint256 alignmentDecayRate);
    event SetOrderDuration(uint256 orderDuration);
    event SetRewardTierSize(uint256 rewardTierSize);
    event SetChaosReward(uint256 chaosReward);
    event SetOrderReward(uint256 orderReward);
    event SetChatCost(uint256 chatCost);
    event SetRareCandyCost(uint256 rareCandyCost);
    event SetBannerAuctionCooldown(uint256 bannerAuctionCooldown);
    event SetBannerAuctionDuration(uint256 bannerAuctionDuration);
    event SetControlAuctionCooldown(uint256 controlAuctionCooldown);
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
    error AlignmentVoteCooldown();

    // Redeem errors
    error InsufficientBalanceForRedeem();

    // Auction errors
    error InsufficientBalanceForBid();
    error InsufficientBidAmount();
    error AuctionInProgress();
    error AuctionNotActive();
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

        rewardTierSize = 100;
        orderReward = 10e18;
        chaosReward = 20e18;
        chatCost = 10e18;
        rareCandyCost = 200e18;

        bannerAuctionCooldown = 120;
        bannerAuctionDuration = 60;
        bestBannerBid = BannerBid(address(0), 0, "");

        controlAuctionCooldown = 300;
        controlAuctionDuration = 60;
        bestControlBid = ControlBid(address(0), 0);

        orderDuration = 20;
        controlDuration = 30;
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
            // Individual control.
            if (msg.sender != controlAddress) {
                revert OtherPlayerHasControl();
            }

            inputTimestamp = block.timestamp;
            emit ButtonInput(inputIndex, msg.sender, buttonIndex);
            inputIndex++;
        } else if (alignment > 0) {
            // Order.
            orderVotes[buttonIndex]++;

            uint256 reward = calculateReward(orderReward);
            if (reward > 0) {
                poke.gameMint(msg.sender, reward);
            }

            emit InputVote(inputIndex, msg.sender, buttonIndex);

            if (block.timestamp >= inputTimestamp + orderDuration) {
                // If orderDuration seconds have passed since the previous input, execute.
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
            }
        } else {
            // Chaos.
            uint256 reward = calculateReward(chaosReward);
            if (reward > 0) {
                poke.gameMint(msg.sender, reward);
            }

            inputTimestamp = block.timestamp;
            emit ButtonInput(inputIndex, msg.sender, buttonIndex);
            inputIndex++;
        }

        inputNonces[msg.sender]++;
        inputBlocks[msg.sender] = block.number;
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

    /// @notice Submit a bid in the active banner auction.
    /// @param amount The bid amount in POKE
    /// @param message The requested banner message text
    function submitBannerBid(uint256 amount, string memory message)
        external
        onlyActive
        onlyRegistered
    {
        if (block.timestamp < bannerAuctionTimestamp + bannerAuctionCooldown) {
            revert AuctionNotActive();
        }

        if (poke.balanceOf(msg.sender) < amount) {
            revert InsufficientBalanceForBid();
        }

        if (amount <= bestBannerBid.amount) {
            revert InsufficientBidAmount();
        }

        if (bestBannerBid.from != address(0)) {
            poke.gameTransfer(
                address(this),
                bestBannerBid.from,
                bestBannerBid.amount
            );
        }
        poke.gameTransfer(msg.sender, address(this), amount);
        bestBannerBid = BannerBid(msg.sender, amount, message);
        emit NewBannerBid(msg.sender, amount, message);
    }

    /// @notice End the current banner auction and start the cooldown for the next one.
    function rolloverBannerAuction() external onlyActive {
        if (
            block.timestamp <
            bannerAuctionTimestamp +
                bannerAuctionCooldown +
                bannerAuctionDuration
        ) {
            revert AuctionInProgress();
        }

        if (bestBannerBid.from == address(0)) {
            revert AuctionHasNoBids();
        }

        emit Banner(bestBannerBid.from, bestBannerBid.message);
        bannerAuctionTimestamp = block.timestamp;
        bestBannerBid = BannerBid(address(0), 0, "");
    }

    /// @notice Submit a bid in the active control auction.
    /// @param amount The bid amount in POKE
    function submitControlBid(uint256 amount)
        external
        onlyActive
        onlyRegistered
    {
        if (
            block.timestamp < controlAuctionTimestamp + controlAuctionCooldown
        ) {
            revert AuctionNotActive();
        }

        if (poke.balanceOf(msg.sender) < amount) {
            revert InsufficientBalanceForBid();
        }

        if (amount <= bestControlBid.amount) {
            revert InsufficientBidAmount();
        }

        if (bestControlBid.from != address(0)) {
            poke.gameTransfer(
                address(this),
                bestControlBid.from,
                bestControlBid.amount
            );
        }
        poke.gameTransfer(msg.sender, address(this), amount);
        bestControlBid = ControlBid(msg.sender, amount);
        emit NewControlBid(msg.sender, amount);
    }

    /// @notice End the current control auction and start the cooldown for the next one.
    function rolloverControlAuction() external onlyActive {
        if (
            block.timestamp < controlAuctionTimestamp + controlAuctionDuration
        ) {
            revert AuctionInProgress();
        }

        if (bestControlBid.from == address(0)) {
            revert AuctionHasNoBids();
        }

        emit Control(bestControlBid.from);
        bannerAuctionTimestamp = block.timestamp;
        bestControlBid = ControlBid(address(0), 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  HELPERS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculates the reward modifier for this button input.
    /// @param baseReward The base reward to be adjusted
    /// @return reward The final reward, adjusted for playtime
    function calculateReward(uint256 baseReward)
        internal
        view
        returns (uint256)
    {
        // If this is not the first reward for this player in this block, return zero.
        if (inputBlocks[msg.sender] >= block.number) {
            return 0;
        }

        uint256 rewardTier = inputNonces[msg.sender] / rewardTierSize;
        // If the player is beyond rewardTier 9, set to rewardTier 9.
        rewardTier = rewardTier > 9 ? 9 : rewardTier;
        return (baseReward * (10 - rewardTier)) / 10;
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

    function setRewardTierSize(uint256 _rewardTierSize) external onlyOwner {
        rewardTierSize = _rewardTierSize;
        emit SetRewardTierSize(_rewardTierSize);
    }

    function setChaosReward(uint256 _chaosReward) external onlyOwner {
        chaosReward = _chaosReward;
        emit SetChaosReward(_chaosReward);
    }

    function setOrderReward(uint256 _orderReward) external onlyOwner {
        orderReward = _orderReward;
        emit SetOrderReward(_orderReward);
    }

    function setChatCost(uint256 _chatCost) external onlyOwner {
        chatCost = _chatCost;
        emit SetChatCost(_chatCost);
    }

    function setRareCandyCost(uint256 _rareCandyCost) external onlyOwner {
        rareCandyCost = _rareCandyCost;
        emit SetRareCandyCost(_rareCandyCost);
    }

    function setBannerAuctionCooldown(uint256 _bannerAuctionCooldown)
        external
        onlyOwner
    {
        bannerAuctionCooldown = _bannerAuctionCooldown;
        emit SetBannerAuctionCooldown(_bannerAuctionCooldown);
    }

    function setBannerAuctionDuration(uint256 _bannerAuctionDuration)
        external
        onlyOwner
    {
        bannerAuctionDuration = _bannerAuctionDuration;
        emit SetBannerAuctionDuration(_bannerAuctionDuration);
    }

    function setControlAuctionCooldown(uint256 _controlAuctionCooldown)
        external
        onlyOwner
    {
        controlAuctionCooldown = _controlAuctionCooldown;
        emit SetControlAuctionCooldown(_controlAuctionCooldown);
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
