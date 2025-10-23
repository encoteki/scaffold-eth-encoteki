import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployTSBD: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Constructor args
  const NAME = "The Satwas Band Dev";
  const SYMBOL = "TSBD";
  const BASE_URI = "https://ipfs.io/ipfs/QmZHdPSMqhFfVmCQtGv18zUNMGVY4faZhkgoi9eTNj2i4X/";
  const NOT_REVEALED_URI = "https://ipfs.io/ipfs/QmbSLKQgzitE1aKkHvQEMrMch7xGoo7mMjoqom5qni8qKP/hidden.json";

  const result = await deploy("TheSatwasBandDev", {
    from: deployer,
    contract: "TheSatwasBandDev",
    args: [NAME, SYMBOL, BASE_URI, NOT_REVEALED_URI],
    log: true,
    autoMine: true,
  });

  console.log(`👋 TheSatwasBandDev deployed at: ${result.address}`);
};

export default deployTSBD;
// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags TheSatwasBandDev
deployTSBD.tags = ["TheSatwasBandDev"];
