// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
// import { ethers } from "hardhat";
// import { NoCapFactory__factory, NoCapMarketplace, NoCapMarketplace__factory, NoCapTemplateERC721, NoCapTemplateERC721__factory, USDT__factory } from "../typechain-types";
// import { NoCapFactory, USDT } from "../typechain-types/contracts";
// import { expandTo15Decimals, expandTo16Decimals, expandTo17Decimals, expandTo18Decimals, expandTo6Decimals } from "./utilities/utilities";
// import NoCapVoucher from "./utilities/voucher";


// describe("Marketplace testcases", async()=>{


//     let signers : SignerWithAddress[];
//     let owner : SignerWithAddress;
//     let marketplace : NoCapMarketplace;
//     let factory : NoCapFactory;
//     let template : NoCapTemplateERC721;
//     let usdt : USDT;
    
//     beforeEach(async()=>{

//         signers = await ethers.getSigners();
//         owner = signers[0];
//         factory = await new NoCapFactory__factory(owner).deploy();
//         template = await new NoCapTemplateERC721__factory(owner).deploy();
//         marketplace = await new NoCapMarketplace__factory(owner).deploy();
//         usdt = await new USDT__factory(owner).deploy();
//         await factory.connect(owner).initialize(template.address,owner.address,marketplace.address);
//         await factory.connect(owner).deployNFTCollection("Sample","SMP",owner.address,200,usdt.address);
//         await marketplace.connect(owner).initialize(owner.address,template.address,200,usdt.address);
        
//     })

//     it("LazyMinting Test",async()=>{

//         let NFTAddress = await factory.getCollectionAddress(owner.address,1);
//         console.log("Collection address: ", NFTAddress);
        
//         const seller = await new NoCapVoucher({
//             _contract : marketplace,
//             _signer : owner,
//         });

//         const voucher = await seller.createVoucher(owner.address,NFTAddress,1,expandTo18Decimals(1),true,owner.address,200,"Sample URI");
        
//         // await marketplace.connect(signers[3]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001");

//         let addressCreated = await marketplace.connect(owner).verifyVoucher(voucher);

//         let addressFromContract = await marketplace.voucherOwner(voucher);

//         console.log("Address created :",addressCreated, "Actual address : ",owner.address, "Address from voucher: ", addressFromContract);




//     })

// })