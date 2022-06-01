# Run deploy script against Anvil node.
source .env.local && forge script ./script/Deploy.sol --sig "run()" -vvv --fork-url $FOUNDRY_ETH_RPC_URL