import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ClaimTopicsRegistry, ClaimTopicsRegistry__factory, DefaultCompliance, DefaultCompliance__factory, Identity, IdentityFactory, IdentityFactory__factory, IdentityRegistry, IdentityRegistryStorage, IdentityRegistryStorage__factory, IdentityRegistry__factory, Identity__factory, ImplementationAuthority, ImplementationAuthority__factory, NoCapFactory, NoCapFactory__factory, NoCapMarketplace, NoCapMarketplace__factory, NoCapSecurityTokenFactory, NoCapSecurityTokenFactory__factory, NoCapTemplateERC721, NoCapTemplateERC721__factory, TokenST, TokenST__factory, TrustedIssuersRegistry, TrustedIssuersRegistry__factory, USDT, USDT__factory } from "../typechain-types";
import { TrustedIssuerAddedEvent } from "../typechain-types/contracts/SecurityToken/interface/ITrustedIssuersRegistry";
import { expandTo18Decimals } from "./utilities/utilities";
import NoCapVoucher from "./utilities/voucher";
import { expect } from "chai";

describe("STO Marketplace", ()=>{

    let owner : SignerWithAddress;
    let signers : SignerWithAddress[];
    let marketplace : NoCapMarketplace;
    let factory : NoCapFactory;
    let template : NoCapTemplateERC721;
    let usdt : USDT;
    let identityRegistry : IdentityRegistry;
    let identityRegistryStorage : IdentityRegistryStorage;
    let compliance : DefaultCompliance;
    let token : TokenST;
    let implementationAuthority : ImplementationAuthority;
    let trustedIssuersRegistry : TrustedIssuersRegistry;
    let claimsTopicsRegistry : ClaimTopicsRegistry;
    let identityTemplate : Identity;
    let identityFactory : IdentityFactory;
    let STOFactory : NoCapSecurityTokenFactory;
    let marketplaceId : Identity;

    beforeEach(async()=>{

        //Deployment of the contracts: 

        signers = await ethers.getSigners();
        owner = signers[0];
        factory = await new NoCapFactory__factory(owner).deploy();
        STOFactory = await new NoCapSecurityTokenFactory__factory(owner).deploy();
        template = await new NoCapTemplateERC721__factory(owner).deploy();
        marketplace = await new NoCapMarketplace__factory(owner).deploy();
        usdt = await new USDT__factory(owner).deploy();
        identityRegistry = await new IdentityRegistry__factory(owner).deploy();
        identityRegistryStorage = await new IdentityRegistryStorage__factory(owner).deploy();
        compliance = await new DefaultCompliance__factory(owner).deploy();
        token = await new TokenST__factory(owner).deploy();
        implementationAuthority = await new ImplementationAuthority__factory(owner).deploy(token.address);
        trustedIssuersRegistry = await new TrustedIssuersRegistry__factory(owner).deploy();
        claimsTopicsRegistry = await new ClaimTopicsRegistry__factory(owner).deploy();
        identityTemplate = await new Identity__factory(owner).deploy();
        identityFactory = await new IdentityFactory__factory(owner).deploy();
        marketplaceId = await new Identity__factory(owner).deploy();
        await marketplaceId.connect(owner).init(marketplace.address,false);
        // Init for the contracts :
        
        
        await factory.connect(owner).initialize(template.address,owner.address,marketplace.address, STOFactory.address);
        await marketplace.connect(owner).initialize(owner.address,template.address,200,usdt.address);
        await factory.connect(owner).deployNFTCollection("NoCapSampleNFT","NCP",owner.address,200);
        await identityRegistryStorage.connect(owner).init();
        await identityRegistry.connect(owner).init(trustedIssuersRegistry.address,claimsTopicsRegistry.address,identityRegistryStorage.address);
        await claimsTopicsRegistry.connect(owner).init();
        await trustedIssuersRegistry.connect(owner).init();
        await identityFactory.connect(owner).init(identityTemplate.address,identityRegistry.address,owner.address);
        await identityRegistry.connect(owner).addAgentOnIdentityRegistryContract(owner.address);
        await identityRegistry.connect(owner).addAgent(identityFactory.address);
        await identityRegistryStorage.connect(owner).bindIdentityRegistry(identityRegistry.address);
        await identityFactory.connect(owner).createAndRegisterIdentity(1);
        await identityFactory.connect(signers[1]).createAndRegisterIdentity(1);
        await identityFactory.connect(signers[2]).createAndRegisterIdentity(2);
        await STOFactory.connect(owner).init(token.address,compliance.address,owner.address,identityRegistry.address,marketplace.address,factory.address);
        await STOFactory.connect(owner).addAuthorizedCountries([1,2]);
        await identityRegistry.connect(owner).registerIdentity(marketplace.address,marketplaceId.address,1);
    })

    it("Lazy Minting Test Initial", async()=>{
        let NFTAddress = await factory.getCollectionAddress(owner.address,1);
        console.log("Collection Address: ", NFTAddress);

        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const voucher = await seller.createVoucher(
            owner.address,
            NFTAddress,
            1,
            4,
            2,
            expandTo18Decimals(100),
            true,
            owner.address,
            200,
            "Sample URI");

        const voucher2 = await seller.createVoucher(
            owner.address,
            NFTAddress,
            1,
            4,
            2,
            expandTo18Decimals(100),
            false,
            owner.address,
            200,
            "Sample URI"
        );

        let addressCreated = await marketplace.connect(owner).verifyVoucher(voucher);
        let addressFromContract = await marketplace.voucherOwner(voucher);
        console.log("Address created :",addressCreated, "Actual address : ",owner.address, "Address from voucher: ", addressFromContract);

        console.log("Collection Exist: ",await factory.checkNoCapNFT(NFTAddress));
        await marketplace.connect(signers[1]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(204)});
        let nftCreated = await new NoCapTemplateERC721__factory(owner).attach(NFTAddress);
        console.log("Success: ", await nftCreated.balanceOf("0xf0eee3e0add7ebae22fd553377df4c1fd4cbe131"));
        console.log(await nftCreated.ownerOf(1));
        console.log("STO for token ID: ", await nftCreated.STOForTokenId(1));
        let fractionSTO = await new TokenST__factory(owner).attach("0xf0eEE3e0AdD7EBae22FD553377dF4c1Fd4CBE131");
        console.log("Fractions Received: ", await fractionSTO.balanceOf(signers[1].address));

        await marketplace.connect(signers[2]).buyNFT(voucher2,true,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(204)});
        console.log("Fractions for second Buyer : ", await fractionSTO.balanceOf(signers[2].address));

        // Checking SEcondary sale on the marketplace :

        const sellerSecondary = await new NoCapVoucher({
            _contract : marketplace,
            _signer : signers[1],
        })

        const voucherSecondary = await sellerSecondary.createVoucher(
            signers[1].address,
            NFTAddress,
            1,
            2,
            1,
            expandTo18Decimals(100),
            false,
            owner.address,
            200,
            "Sample URI"
        )

        let addressChecked = await marketplace.connect(owner).verifyVoucher(voucherSecondary);
        console.log("Original address: ", signers[1].address, "Created address :", addressChecked);

        await fractionSTO.connect(signers[1]).approve(marketplace.address,2);

        await marketplace.connect(signers[2]).buyNFT(voucherSecondary,false,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(104)});

        console.log("New fraction balance: ", await fractionSTO.balanceOf(signers[2].address));
    })

    it("NoCapFactory: Deploy NFT Collection", async()=>{
        await identityFactory.connect(signers[3]).createAndRegisterIdentity(1);
        await factory.connect(signers[3]).deployNFTCollection("MyNFTCollection","MNFT",signers[3].address,300);
        let instanceAddress = await factory.getCollectionAddress(signers[3].address,1);
        let instance = await new NoCapTemplateERC721__factory(signers[3]).attach(instanceAddress);
        console.log("NFT Details: ", await instance.name());
    })

    it("NoCapFactory: Deploy NFT Collection(Negative)", async()=>{
        await identityFactory.connect(signers[3]).createAndRegisterIdentity(1);
        await expect(factory.connect(signers[3]).deployNFTCollection("MyNFTCollection","MNFT","0x0000000000000000000000000000000000000000",300)).to.be.revertedWith("Zero address.");
    })

    it("NoCapFactory: Update Template Address", async()=>{
        await factory.connect(owner).updateTemplateAddress(signers[4].address);
        console.log("Success.");
    })

    it("NoCapFactory: Update Template Address(Negative)", async()=>{
        await expect(factory.connect(signers[3]).updateTemplateAddress(signers[5].address)).to.be.revertedWith("You are not the admin.");
        await expect(factory.connect(owner).updateTemplateAddress("0x0000000000000000000000000000000000000000")).to.be.revertedWith("Zero address.");
        console.log("Two require statements covered");
    })

    it

})