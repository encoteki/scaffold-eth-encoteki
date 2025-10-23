import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployBPImpl: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const result = await deploy("BusinessProposalImplementation", {
    from: deployer,
    contract: "BusinessProposalImplementation",
    args: [],
    log: true,
    autoMine: true,
  });

  console.log(`👋 BusinessProposalImplementation deployed at: ${result.address}`);
};

export default deployBPImpl;
// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags BusinessProposalImplementation
deployBPImpl.tags = ["BusinessProposalImplementation"];
