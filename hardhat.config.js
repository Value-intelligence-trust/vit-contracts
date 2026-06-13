require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PK = process.env.DEPLOYER_PRIVATE_KEY || "0x" + "0".repeat(64);

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    base: {
      url: process.env.BASE_RPC_URL || "https://mainnet.base.org",
      chainId: 8453,
      accounts: [PK],
    },
    base_sepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org",
      chainId: 84532,
      accounts: [PK],
    },
    hardhat: { chainId: 31337 },
  },
  etherscan: {
    apiKey: {
      base:         process.env.BASESCAN_API_KEY || "",
      base_sepolia: process.env.BASESCAN_API_KEY || "",
    },
    customChains: [
      { network: "base",         chainId: 8453,  urls: { apiURL: "https://api.basescan.org/api",        browserURL: "https://basescan.org" }},
      { network: "base_sepolia", chainId: 84532, urls: { apiURL: "https://api-sepolia.basescan.org/api", browserURL: "https://sepolia.basescan.org" }},
    ],
  },
};
