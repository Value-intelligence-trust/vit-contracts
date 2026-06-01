# VIT Contracts

**Smart contracts for the VIT Network** — deployed on Base L2 (chain ID 8453).

[![Solidity](https://img.shields.io/badge/Solidity-0.8-363636?style=flat-square&logo=solidity)](https://soliditylang.org)
[![Base L2](https://img.shields.io/badge/Network-Base_L2-0052ff?style=flat-square)](https://base.org)
[![Foundry](https://img.shields.io/badge/Framework-Foundry-orange?style=flat-square)](https://getfoundry.sh)

## Contracts

| Contract | Description |
|----------|-------------|
| `UniversalOracle.sol` | On-chain result verification for sports and elections |
| `VITCoin.sol` | ERC-20 utility token with gasless transfers via Biconomy |
| `DIDRegistry.sol` | W3C-compliant decentralised identity registry |
| `SignalStaking.sol` | Staking and slashing for signal marketplace participants |
| `LoyaltyVault.sol` | Automated yield distribution for ecosystem participants |

## Setup

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge install
forge build
forge test
```

## Deploy

```bash
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify
```
