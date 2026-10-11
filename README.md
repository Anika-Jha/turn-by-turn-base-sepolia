# Turn by Turn — ChainFour

A persistent, asynchronous Connect Four game on Base Sepolia. The contract is authoritative for turn order, placement validity, wins, draws, and timeout forfeits.

## Stack
- Solidity 0.8.24 + Foundry
- React + TypeScript + Vite
- viem for contract reads/writes
- Base Sepolia (chain ID 84532)

## Run the frontend
```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```
Set `VITE_GAME_CONTRACT` to the deployed contract address. `VITE_RPC_URL` may be set to a Base Sepolia RPC URL. No secret is required in the frontend.

## Test and deploy
Install Foundry and `forge-std`, then:
```bash
forge test
forge build
```
Create `.env` from `.env.example` for deployment. Set `PRIVATE_KEY` locally only; never commit `.env`.
```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url "$BASE_SEPOLIA_RPC_URL" --broadcast
```
The deployment script expects `PRIVATE_KEY` and `BASE_SEPOLIA_RPC_URL` in your local environment.

## Play
1. Connect a wallet configured for Base Sepolia.
2. Create a game, then share its numeric game ID.
3. The second player joins that game ID.
4. Select a column to make a move. Refreshing/reopening the page does not erase contract state.
5. If a player stalls longer than `TIMEOUT`, the other player can claim the timeout win.

## Security and limitations
- Contract functions enforce all game rules; frontend validation is only convenience.
- This starter uses wallet transactions, so players need test ETH unless a compatible sponsored smart-account flow is added.
- Testnet deployment has not been performed by this generated project. Add the actual deployed address to this README after deployment.
