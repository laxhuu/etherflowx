const hre = require("hardhat");

async function main() {
  const EtherFlowX = await hre.ethers.getContractFactory("EtherFlowX");
  const etherFlowX = await EtherFlowX.deploy();

  await etherFlowX.waitForDeployment();
  console.log("✅ EtherFlowX deployed to:", await etherFlowX.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
