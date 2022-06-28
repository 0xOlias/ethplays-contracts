# Run deploy scripts
source .env.local && forge script script/DeployRegistry.s.sol --rpc-url $ETH_RPC_URL  --private-key $REGISTRY_DEPLOYER_PRIVATE_KEY --broadcast
source .env.local && forge script script/DeployPoke.s.sol --rpc-url $ETH_RPC_URL  --private-key $POKE_DEPLOYER_PRIVATE_KEY --broadcast
source .env.local && forge script script/DeployRegistryReceiver.s.sol --rpc-url $ETH_RPC_URL  --private-key $REGISTRY_RECEIVER_DEPLOYER_PRIVATE_KEY --broadcast
source .env.local && forge script script/DeployEthPlays.s.sol --rpc-url $ETH_RPC_URL  --private-key $ETH_PLAYS_DEPLOYER_PRIVATE_KEY --broadcast
