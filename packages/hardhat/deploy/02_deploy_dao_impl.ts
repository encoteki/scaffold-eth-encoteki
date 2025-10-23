import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployDAOImpl: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const result = await deploy("DAOImplementation", {
    from: deployer,
    contract: "DAOImplementation",
    args: [],
    log: true,
    autoMine: true,
  });

  console.log(`👋 DAOImplementation deployed at: ${result.address}`);
};

export default deployDAOImpl;
// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags DAOImplementation
deployDAOImpl.tags = ["DAOImplementation"];
