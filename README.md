## ethplays-contracts

- This repo uses [foundry](https://github.com/foundry-rs/foundry)
- These contracts are a work in progress, test coverage is incomplete

### Poke.sol
An ownable ERC20 token contract with minor modifications.
Poke.sol defines two public methods that can only be called by the EthPlaysGame contract:
- `mint()`: verifies that the sender is the EthPlaysGame contract, then calls `_mint()`
- `burn()`: verifies that the sender is the EthPlaysGame contract, then calls `_burn()`

Poke.sol also overrides the `allowance()` function to enable the EthPlaysAuction contract to transfer tokens while closing auctions. It also includes methods that allow the owner to update the addresses of the two privileged contracts.

### To Do...
