import { SignerWithAddress } from "../node_modules/@nomiclabs/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import {
  expandTo18Decimals,
  expandTo6Decimals,
} from "../test/utilities/utilities";
import { NoCapFactory, NoCapTemplateERC721, NoCapMarketplace,NoCapSecurityTokenFactory, USDT,Token } from "../typechain-types";

function sleep(ms: any) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

async function main() {
    const factory = await ethers.getContractFactory("NoCapFactory");
    const marketplace = await ethers.getContractFactory("NoCapMarketplace");
    const template = await ethers.getContractFactory("NoCapTemplateERC721");
    const stoFactory = await ethers.getContractFactory("NoCapSecurityTokenFactory");
    const token = await ethers.getContractFactory("Token");



    // const Factory = await factory.deploy();
    // await sleep(2000);
    // const Marketplace = await marketplace.deploy();
    // await sleep(2000);
    // const Template = await template.deploy();
    // await sleep(2000);
    // const STOFactory = await stoFactory.deploy();
    // await sleep(2000);

    const token1= await token.deploy("Yato","YTC",1000000);
    const token2= await token.deploy("Saitama","STM",1000000);
    const token3= await token.deploy("Goku","GKC",1000000);
    const token4= await token.deploy("Vegeta","VTC",1000000);


    console.log("Yato Address- "+token1.address);
    console.log("Saitama Address- "+token2.address);
    console.log("Goku Address- "+token3.address);
    console.log("Vegeta Address- "+token4.address);

}  

main()
.then(()=>process.exit(0))
.catch((error)=>{
    console.error(error);
    process.exit(1);
}) ;

// Yato Address- 0x66D9512e6Cf45ba95586a8E7E1544Cef71521f08
// Saitama Address- 0xDeDDbF4a30C99Cb20E85806873ba603E6bA376CD
// Goku Address- 0xF35871678B04E56a17531D92589BD62863CcF5FA
// Vegeta Address- 0x06662846f8a08f74402A2d9e17A0b1aBCcE7A504