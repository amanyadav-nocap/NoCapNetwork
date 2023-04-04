// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { NoCapFactory, NoCapFactory__factory, NoCapTemplateERC721, NoCapTemplateERC721__factory } from "../typechain-types";
// import { noCapTemplate721Sol } from "../typechain-types/contracts";
// import { TemplateERC721__factory } from "../typechain-types/factories/contracts/Template721.sol";

// describe("NoCap Network Factory Testing",async()=>{


//     let owner    :   SignerWithAddress;
//     let signers  :   SignerWithAddress[];
//     let factory  :   NoCapFactory;
//     let template :   NoCapTemplateERC721;
    
//     beforeEach(async()=>{
//         signers = await ethers.getSigners();
//         owner = signers[0];
//         factory = await new NoCapFactory__factory(owner).deploy();
//         template = await new NoCapTemplateERC721__factory(owner).deploy();
//         await factory.connect(owner).initialize(template.address,owner.address,signers[1].address);

//     })

//     it("Deploying NFTs from factory", async()=>{
       
//         await factory.connect(owner).deployNFTCollection("Sample","SMP",owner.address,200,signers[3].address);
//         console.log("Total collections : ",await factory.collections(owner.address));
//         console.log("Collection address : ", await factory.getCollectionAddress(owner.address,1));

//         let collectionInstance = await new TemplateERC721__factory(owner).attach(await factory.getCollectionAddress(owner.address,1));

//         console.log("Proof of contract : ",await collectionInstance.royaltyAmount());

//     })

//     it("Negative Test cases for deploying NFT",async()=>{
        
//         console.log("Zero address check done for creator",await expect(factory.connect(owner).deployNFTCollection("Sample","SMP","0x0000000000000000000000000000000000000000",200,signers[3].address)).to.be.revertedWith("Zero address."));
//         console.log("Zero address check for the token address",await expect(factory.connect(owner).deployNFTCollection("Sample","SMP",owner.address,200,"0x0000000000000000000000000000000000000000")).to.be.revertedWith("Zero address."));   
//     })

//     it("Negative test case for the remaining functions",async()=>{

        
//     })

// })