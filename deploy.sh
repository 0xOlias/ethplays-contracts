# Run deploy scripts
source .env.local && forge script script/Deploy.s.sol \
  --rpc-url $ETH_RPC_URL \
  --private-keys \
    $ACCOUNT_0_PRIVATE_KEY \
    $ACCOUNT_1_PRIVATE_KEY \
    $ACCOUNT_2_PRIVATE_KEY \
    $ACCOUNT_3_PRIVATE_KEY \
  --broadcast

# source .env.local && forge script script/DeployPoke.s.sol --rpc-url $ETH_RPC_URL  --private-key $POKE_DEPLOYER_PRIVATE_KEY --broadcast
# source .env.local && forge script script/DeployRegistryReceiver.s.sol --rpc-url $ETH_RPC_URL  --private-key $REGISTRY_RECEIVER_DEPLOYER_PRIVATE_KEY --broadcast
# source .env.local && forge script script/DeployEthPlays.s.sol --rpc-url $ETH_RPC_URL  --private-key $ETH_PLAYS_DEPLOYER_PRIVATE_KEY --broadcast


# source .env.local && forge script script/Deploy.s.sol --rpc-url $ETH_RPC_URL --private-keys $REGISTRY_DEPLOYER_PRIVATE_KEY $POKE_DEPLOYER_PRIVATE_KEY $REGISTRY_RECEIVER_DEPLOYER_PRIVATE_KEY $ETH_PLAYS_DEPLOYER_PRIVATE_KEY  --broadcast

source .env.local && forge script script/Deploy.s.sol --rpc-url $ETH_RPC_URL --private-keys $_ACCOUNT_0_PRIVATE_KEY $_ACCOUNT_1_PRIVATE_KEY --broadcast