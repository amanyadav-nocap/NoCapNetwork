import { SignerWithAddress } from "../node_modules/@nomiclabs/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import {
  expandTo18Decimals,
  expandTo6Decimals,
} from "../test/utilities/utilities";
import { NoCapFactory, NoCapTemplateERC721, NoCapMarketplace,NoCapSecurityTokenFactory } from "../typechain-types";

function sleep(ms: any) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

async function main() {
    const factory = await ethers.getContractFactory("NoCapFactory");
    const marketplace = await ethers.getContractFactory("NoCapMarketplace");
    const template = await ethers.getContractFactory("NoCapTemplateERC721");
    const stoFactory = await ethers.getContractFactory("NoCapSecurityTokenFactory");



    const Factory = await factory.deploy();
    await sleep(2000);
    const Marketplace = await marketplace.deploy();
    await sleep(2000);
    const Template = await template.deploy();
    await sleep(2000);
    const STOFactory = await stoFactory.deploy();
    await sleep(2000);

    console.log("Factory Address- "+Factory.address);
    console.log("Marketplace Address- "+Marketplace.address);
    console.log("Template Address- "+Template.address);
    console.log("STOFactory Address- "+STOFactory.address);

}  

main()
.then(()=>process.exit(0))
.catch((error)=>{
    console.error(error);
    process.exit(1);
}) ;