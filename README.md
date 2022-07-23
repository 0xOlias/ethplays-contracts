## ethplays-contracts

- This repo uses [foundry](https://github.com/foundry-rs/foundry)
- This is a WIP, test coverage is incomplete

### Poke.sol

An ownable ERC20 token contract with minor modifications. `Poke` defines three external methods that can only be called by the `EthPlays` contract:

- `gameMint(address,uint256)`: verifies that the sender is the game contract, then calls `_mint()`
- `gameBurn(address,uint256)`: verifies that the sender is the game contract, then calls `_burn()`
- `gameTransfer(address,address,uint256)`: verifies that the sender is the game contract, then calls `_transfer()`

### EthPlays.sol

An ownable contract that defines the game logic. This includes button presses, order & chaos mode, the control auction, and rare candies. `EthPlays` calls both `Poke` and `RegistryReceiver` to mint/burn/transfer tokens and check registration eligibility.

#### Token mechanics

The following actions mint/burn the POKE token:
- Submit a button press (mints 20 POKE to the sender, minting is rate-limited to once per 30 seconds)
- Submit an alignment vote for chaos (mints 20 POKE to the sender, players can only vote for alignment once per minute)
- Submit a message to the chat (burns 20 POKE)
- Purchase rare candies (burns 200 POKE per rare candy)
- Submit a control bid (burns the bid amount of POKE, mints the previous best bid amount to the previous best bid sender)

#### Auction mechanics

EthPlays defines a simple auction mechanism using the POKE token. Players can submit bids (in POKE) to take control of the game for 30 seconds. The auction lasts 90 seconds, and once ended, the next auction begins immeidately. If a player submits a bid that beats the previous bid, the POKE amount from the previous bid is minted back to the the sender of that bid. The POKE amount of the winning bid gets burned.

Auction state:
- controlAuctionStartTimestamp
- controlAuctionEndTimestamp
- bestControlBid
- controlAddress

Auction parameters:
- controlAuctionDuration
- controlDuration

How to derive auction status from contract state:
- if (controlEndTimestamp > controlStartTimestamp) -> the auction is ready, submit a bid to start it
- if (timestamp < controlAuctionStartTimestamp + controlAuctionDuration) -> auction is in progress
- if (timestamp > controlAuctionStartTimestamp + controlAuctionDuration) -> auction is over, waiting to be ended
- if (timestamp < controlAuctionEndTimestamp + controlDuration) -> control is active

### Registry.sol

An ownable contract _on mainnet_ that players interact with to register for the game. This contract holds registration fees which can be withdrawn by the owner. The `RegistryReceiver` contract mirrors the registration data stored on this contract.

### RegistryReceiver.sol

An ownable contract storing registration data. `EthPlays` calls the public `isRegistered(address)` method to determine if an account is allowed to play. This contract is upgradable, so it could be updated with new registration rules (e.g. an allowlist).

### Offchain relayer/faucet

There is an offchain web service that responds to `Register` events emitted by the `Registry` contract on mainnet and does two things:
* Calls the `submitRegistration(address,address)` method on `RegistryReceiver` with the account/burner account from the `Register` event.
* Sends faucet funds to the burner account specified in the `Register` event.
