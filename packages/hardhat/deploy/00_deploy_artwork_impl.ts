import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployArtworkImpl: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const result = await deploy("ArtworkImpl", {
    from: deployer,
    contract: "ArtworkImpl",
    args: [],
    log: true,
    autoMine: true,
  });

  console.log(`👋 ArtworkImpl deployed at: ${result.address}`);
};

export default deployArtworkImpl;
// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags DAOImplementation
deployArtworkImpl.tags = ["ArtworkImpl"];
