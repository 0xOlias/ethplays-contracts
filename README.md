## ethplays-contracts

- This repo uses [foundry](https://github.com/foundry-rs/foundry)
- This is a WIP, test coverage is incomplete

### Poke.sol

An ownable ERC20 token contract with minor modifications. Poke.sol defines three public methods that can only be called by the EthPlays contract:

- `gameMint(address,uint256)`: verifies that the sender is the game contract, then calls `_mint()`
- `gameBurn(address,uint256)`: verifies that the sender is the game contract, then calls `_burn()`
- `gameTransfer(address,address,uint256)`: verifies that the sender is the game contract, then calls `_transfer()`

### EthPlays.sol

An ownable contract that defines the game logic. This includes button presses, order & chaos mode, the banner & control auction. EthPlays calls both Poke.sol and RegistryReceiver.sol to mint/burn/transfer tokens and check registration eligibility.

#### Auction mechanics

EthPlays defines a simple auction mechanism. Each auction has a cooldown stage and a voting stage. During the voting stage, any player may submit a bid denominated in $POKE that beats the current best bid by calling `submitControlBid(uint256)`. When a player successfully submits a bid, the new bid quantity is transferred from the sender to the EthPlays contract and the previous best bid quantity is transferred back to its owner. Once the voting duration is over, any account can call the `rolloverAuction()` method, which emits the `Control` event, resets the best bid, and updates the auction timestamp. More explicitly:

- The `controlAuctionTimestamp` variable marks the end of the previous auction.
- The auction "starts" (players can start submitting bids) once `block.timestamp > controlAuctionTimestamp + controlAuctionCooldown`
- The auction "ends" (anyone is able to end/rollover the auction) once `block.timestamp > controlAuctionTimestamp + controlAuctionCooldown + controlAuctionDuration`

### RegistryReceiver.sol

An ownable contract storing registration data. EthPlays.sol calls the public `isRegistered(address)` method to determine if an account is allowed to play. This contract is upgradable, so it could be updated with new registration rules (e.g. an allowlist).

### Offchain relayer/faucet

There is an offchain web service that responds to `Register` events emitted by Registry.sol and does two things:
* Calls the `submitRegistration(address,address)` method on RegistryReceiver.sol with the account/burner account from the `Register` event.
* Sends faucet funds to the burner account specified in the `Register` event.

Will finish docs later kek
