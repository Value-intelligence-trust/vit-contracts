const { ethers, run, network } = require("hardhat");
const fs = require("fs"), path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  const treasury = process.env.TREASURY_ADDRESS || deployer.address;

  console.log("\n=== VIT Network Deploy ===");
  console.log("Network :", network.name, "| Chain:", network.config.chainId);
  console.log("Deployer:", deployer.address);
  console.log("Treasury:", treasury);
  console.log("Balance :", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  console.log("1/3 VITToken...");
  const vit = await (await ethers.getContractFactory("VITToken")).deploy(treasury, deployer.address);
  await vit.waitForDeployment();
  const vitAddr = await vit.getAddress();
  console.log("  =>", vitAddr);

  console.log("2/3 UniversalOracle...");
  const oracle = await (await ethers.getContractFactory("UniversalOracle")).deploy(deployer.address);
  await oracle.waitForDeployment();
  const oracleAddr = await oracle.getAddress();
  console.log("  =>", oracleAddr);

  console.log("3/3 ShopManager...");
  const shop = await (await ethers.getContractFactory("ShopManager")).deploy(vitAddr, treasury, deployer.address);
  await shop.waitForDeployment();
  const shopAddr = await shop.getAddress();
  console.log("  =>", shopAddr);

  const out = { network: network.name, chainId: network.config.chainId, deployer: deployer.address, treasury,
    contracts: { VITToken: vitAddr, UniversalOracle: oracleAddr, ShopManager: shopAddr },
    deployedAt: new Date().toISOString() };

  const outPath = path.join(__dirname, "..", "deployments", network.name + ".json");
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2));

  if (network.name !== "hardhat" && process.env.BASESCAN_API_KEY) {
    await run("verify:verify", { address: vitAddr,    constructorArguments: [treasury, deployer.address] }).catch(console.warn);
    await run("verify:verify", { address: oracleAddr, constructorArguments: [deployer.address] }).catch(console.warn);
    await run("verify:verify", { address: shopAddr,   constructorArguments: [vitAddr, treasury, deployer.address] }).catch(console.warn);
  }

  console.log("\nDone. Add to vit backend .env:");
  console.log("VIT_TOKEN_ADDRESS=" + vitAddr);
  console.log("UNIVERSAL_ORACLE_ADDRESS=" + oracleAddr);
  console.log("SHOP_MANAGER_ADDRESS=" + shopAddr);
}

main().catch(e => { console.error(e); process.exit(1); });
