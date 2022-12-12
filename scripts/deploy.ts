import { ethers } from "hardhat";
async function main() {

    const Wolf = await ethers.getContractFactory("TheUnchainedWolfs");
    const wolf = await Wolf.deploy();
  
    await wolf.deployed();
  
    console.log("POS deployed to:", wolf.address);
  }
  

  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  