# Run register script
source .env.local && forge script script/Register.s.sol --rpc-url $ETH_RPC_URL  --private-key $REGISTER_PRIVATE_KEY --broadcast