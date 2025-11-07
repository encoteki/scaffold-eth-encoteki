import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployMockUSDC: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const name = "Mock USDC";
  const symbol = "mUSDC";
  const initialSupply = 1000000; // 1,000,000 mUSDC

  const result = await deploy("MockUSDC", {
    from: deployer,
    contract: "MockUSDC",
    args: [name, symbol, initialSupply],
    log: true,
    autoMine: true,
  });

  console.log(`👋 MockUSDC deployed at: ${result.address}`);
};

export default deployMockUSDC;
// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags MockUSDC
deployMockUSDC.tags = ["MockUSDC"];
