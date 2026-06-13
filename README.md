# vit-contracts — VIT Network Smart Contracts (Base L2)

| Contract | Description |
|----------|-------------|
| VITToken | ERC-20, 1B cap, mintable, burnable, 1% transfer fee |
| UniversalOracle | Price + match-outcome feeds, quorum voting |
| ShopManager | Merchant registry, VIT payment processor (2.5% protocol fee) |

## Setup

```bash
npm install
cp .env.example .env   # fill DEPLOYER_PRIVATE_KEY, TREASURY_ADDRESS, RPC URLs
```

## Compile & Test

```bash
npm run compile
npm test
```

## Deploy

```bash
npm run deploy          # Base Sepolia (testnet)
npm run deploy:mainnet  # Base Mainnet
```

## After Deploy

Copy addresses from `deployments/base.json` into the vit backend .env:

```
VIT_TOKEN_ADDRESS=0x...
UNIVERSAL_ORACLE_ADDRESS=0x...
SHOP_MANAGER_ADDRESS=0x...
```

## Architecture

```
VITToken  <──  ShopManager (pays in VIT, deducts platform fee to treasury)
                     |
              UniversalOracle (settles match outcomes on-chain via quorum)
```
