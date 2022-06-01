## ethplays-contracts

- This repo uses [foundry](https://github.com/foundry-rs/foundry)
- These contracts are a work in progress, test coverage is incomplete

## Poke.sol

An ownable ERC20 token contract with minor modifications.
Poke.sol defines three public methods that can only be called by the EthPlays contract:

- `gameMint()`: verifies that the sender is the game contract, then calls `_mint()`
- `gameBurn()`: verifies that the sender is the game contract, then calls `_burn()`
- `gameTransfer()`: verifies that the sender is the game contract, then calls `_transfer()`

## EthPlays.sol

### Auction mechanics

EthPlays defines a simple auction mechanism. The auction methods are fairly self-explanatory.

Here are some of the key auction constraints:

- There must be a single method to end the previous auction and start the next auction
- There must be both an auction cooldown and an auction duration
- There must be events emitted when the auction ends (when a winner is declared)

This is how the auction start/end mechanics works (using the banner auction variable names):

- The `bannerAuctionTimestamp` variable marks the end of the previous banner auction.
- The auction "starts" (players can start submitting bids) once `block.timestamp > bannerAuctionTimestamp + bannerAuctionCooldown`
- The auction "ends" (anyone is able to end/rollover the auction) once `block.timestamp > bannerAuctionTimestamp + bannerAuctionCooldown + AuctionDuration`

Will finish docs later kek
