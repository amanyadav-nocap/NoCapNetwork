import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ClaimTopicsRegistry, ClaimTopicsRegistry__factory, DefaultCompliance, DefaultCompliance__factory, Identity, IdentityFactory, 
IdentityFactory__factory, IdentityRegistry, IdentityRegistryStorage, IdentityRegistryStorage__factory, IdentityRegistry__factory, Identity__factory, 
ImplementationAuthority, ImplementationAuthority__factory, NoCapFactory, NoCapFactory__factory, NoCapMarketplace, NoCapMarketplace__factory, 
NoCapSecurityTokenFactory, NoCapSecurityTokenFactory__factory, NoCapTemplateERC721, NoCapTemplateERC721__factory, TokenST, TokenST__factory, 
TrustedIssuersRegistry, TrustedIssuersRegistry__factory, USDT, USDT__factory } from "../typechain-types";
import { TrustedIssuerAddedEvent } from "../typechain-types/contracts/SecurityToken/interface/ITrustedIssuersRegistry";
import { expandTo18Decimals, expandTo6Decimals } from "./utilities/utilities";
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
        await factory.deployNFTCollection("New Collection","NCL",owner.address,200);
        
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
        });

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
        );

        let addressChecked = await marketplace.connect(owner).verifyVoucher(voucherSecondary);
        console.log("Original address: ", signers[1].address, "Created address :", addressChecked);

        await fractionSTO.connect(signers[1]).approve(marketplace.address,2);

        await (marketplace.connect(signers[2]).buyNFT(voucherSecondary,false,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(104)}));

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
        await expect(factory.connect(signers[3]).deployNFTCollection("MyNFTCollection","MNFT","0x0000000000000000000000000000000000000000",300))
        .to.be.revertedWith("Zero address.");
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

    it("NoCapFactory: Update Admin Address", async()=>{
        await factory.connect(owner).updateAdmin(signers[1].address);
        console.log("Success");
    })

    it("NoCapFactory: Update Admin Address(Negative)", async()=>{
        await expect(factory.connect(signers[1]).updateAdmin(owner.address)).to.be.revertedWith("You are not the admin.");
        console.log("Only admin modifier covered.");
    })

    it("NoCapMarketplace: HashVoucher Verfied", async()=>{
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
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
            "Latest Collection");

        let addressCreated = await marketplace.verifyVoucher(voucher);
        expect(addressCreated).to.be.eq(owner.address);
        console.log("Address match expect passed. Owner Address: ", owner.address,"Address Created: ", addressCreated);
    })

    it("NoCapMarketplace: Buy NFT(Primary Sale)",async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
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
            "Latest Collection");

        await marketplace.connect(signers[2]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
        let nftContract = await new NoCapTemplateERC721__factory(owner).attach(NFTAddress);
        let stoAddress = await nftContract.STOForTokenId(1);
        console.log("TokenID STO: ", stoAddress);
        let STO = await new TokenST__factory(owner).attach(stoAddress);
        console.log("Proof of ownership: ", await STO.balanceOf(signers[2].address));
    })

    it("NoCapMarketplace: Buy NFT(Negative: Invalid Seller)", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        console.log("Collection Address: ", NFTAddress);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const voucher = await seller.createVoucher(
            signers[1].address,
            NFTAddress,
            1,
            4,
            2,
            expandTo18Decimals(100),
            true,
            owner.address,
            200,
            "Latest Collection");

        await expect(marketplace.connect(signers[2]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)}))
        .to.be.revertedWith("Invalid seller.");
        console.log("Seller address not matching signature address.");
    })

    it("NoCapMarketplace: Buy NFT(Negative: Invalid amount.)", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
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
            "Latest Collection");

        await expect(marketplace.connect(signers[2]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(203)}))
        .to.be.revertedWith("Invalid amount.");
        console.log("Amount transferred by the user to buy the NFT is invalid.");
    })

    it("NoCapMarketplace: Buy NFT(Negative: Currency not allowed.)", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
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
            "Latest Collection");

        await expect(marketplace.connect(signers[2]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000002",{value:expandTo18Decimals(204)}))
        .to.be.revertedWith("Currency not allowed.");
        console.log("Currency used by the user to buy the NFT is invalid.");
    })

    it("NoCapMarketplace: View Sale Receipt", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
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
            "Latest Collection");

        await marketplace.connect(signers[2]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
        console.log("Sale Receipt: ",await marketplace.viewSaleReceipt(signers[2].address,1));
    })

    it("NoCapMarketplace: View Seller amounts", async() =>{
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
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
            "Latest Collection");

        await marketplace.connect(signers[2]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
        console.log("Sellers amount from the purchase: ", await marketplace.viewSellerAmounts(owner.address,NFTAddress,1));
    })

    it("NoCapMarketplace: Buy NFT(Secondary Sale)", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        console.log("Collection Address: ", NFTAddress);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        let nftCollection = await new NoCapTemplateERC721__factory(owner).attach(NFTAddress);
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
            "Latest Collection");
        
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
            "Latest Collection"
        );

        await marketplace.connect(signers[1]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
        await marketplace.connect(signers[2]).buyNFT(voucher2,true,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(204)});

        let stoAddress =  await nftCollection.STOForTokenId(1);
        let STO = await new TokenST__factory(owner).attach(stoAddress);
        console.log("STO Address: ", stoAddress);
        
        const secondarySeller = await new NoCapVoucher({
            _contract: marketplace,
            _signer: signers[1],
        })

        const secondaryVoucher = await secondarySeller.createVoucher(
            signers[1].address,
            NFTAddress,
            1,
            2,
            1,
            expandTo18Decimals(100),
            false,
            owner.address,
            100,
            "Latest Collection"
        );
        console.log("fractions: ", await marketplace.fractionsNFT(NFTAddress,1));
        console.log(await ethers.provider.getBalance(signers[3].address));
        await STO.connect(signers[1]).approve(marketplace.address,2);
  
        await (marketplace.connect(signers[2]).buyNFT(secondaryVoucher,false,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(104)}));  
        console.log("Proof of sale: New Balance of Signers[2] - ", await STO.balanceOf(signers[2].address));

    })

    it("NoCapMarketplace: Buy NFT(Secondary Sale)(Negative)", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const secondarySeller = await new NoCapVoucher({
            _contract: marketplace,
            _signer: signers[1],
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
            "Latest Collection");

        const secondaryVoucherInvalid = await secondarySeller.createVoucher(
            signers[1].address,
            NFTAddress,
            2,
            2,
            1,
            expandTo18Decimals(100),
            false,
            owner.address,
            100,
            "Latest Collection"
        );

        const secondaryVoucherValid = await secondarySeller.createVoucher(
            signers[1].address,
            NFTAddress,
            1,
            2,
            1,
            expandTo18Decimals(100),
            false,
            owner.address,
            100,
            "Latest Collection"
        );


        await marketplace.connect(signers[1]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
        await expect(marketplace.connect(signers[2]).buyNFT(secondaryVoucherInvalid,false,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(104)}))
        .to.be.revertedWith("NFT does not exist.");
        console.log("Require to check existence of tokenId covered.");
        await expect(marketplace.connect(signers[2]).buyNFT(secondaryVoucherValid,false,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(104)}))
        .to.be.revertedWith("Sale not allowed until all fractions are issued.");
        console.log("Require to check secondary sale after ending of primary sale covered.");
    })

    it("NoCapMarketplace: Enable refund & get refund",async() =>{
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const secondarySeller = await new NoCapVoucher({
            _contract: marketplace,
            _signer: signers[1],
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
            "Latest Collection");

            await marketplace.connect(signers[1]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
            console.log("Sale Receipt: ",await marketplace.viewSaleReceipt(signers[1].address,1));
            await marketplace.connect(owner).enableRefundForSale(NFTAddress,1);
            console.log("Balance before refund: ", await ethers.provider.getBalance(signers[1].address));
            console.log("Seller amount before refund: ", await marketplace.viewSellerAmounts(owner.address,NFTAddress,1));
            await marketplace.connect(signers[1]).getRefund(1);
            console.log("Balance after refund: ", await ethers.provider.getBalance(signers[1].address));
            console.log("Seller amount after refund: ", await marketplace.viewSellerAmounts(owner.address,NFTAddress,1));
    })

    it("NoCapMarketplace: Get refund(Negative)", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const secondarySeller = await new NoCapVoucher({
            _contract: marketplace,
            _signer: signers[1],
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
            "Latest Collection");

            await marketplace.connect(signers[1]).buyNFT(voucher,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
            console.log("Sale Receipt: ",await marketplace.viewSaleReceipt(signers[1].address,1));

            await expect(marketplace.connect(signers[1]).getRefund(1)).to.be.revertedWith("Refund is not enable on this sale.");

            await marketplace.connect(owner).enableRefundForSale(NFTAddress,1);
            await marketplace.connect(signers[1]).getRefund(1);
            await expect(marketplace.connect(signers[1]).getRefund(1)).to.be.revertedWith("Refund already issued for this transaction.");

            console.log("Requires for 'refund not enabled' & 'refund already issued' covered.");
    })

    it("NoCapMarketplace: Buy NFT with USDT", async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const secondarySeller = await new NoCapVoucher({
            _contract: marketplace,
            _signer: signers[1],
        })

        const voucher = await seller.createVoucher(
            owner.address,
            NFTAddress,
            1,
            4,
            2,
            expandTo6Decimals(100) ,
            true,
            owner.address,
            200,
            "Latest Collection");

        await usdt.connect(owner).transfer(signers[1].address,expandTo6Decimals(300));
        await usdt.connect(signers[1]).approve(marketplace.address,expandTo6Decimals(300));
        await marketplace.connect(signers[1]).buyNFT(voucher,true,usdt.address);
        console.log("balance marketplace: ", await usdt.balanceOf(marketplace.address));
        console.log("Sale receipt: ", await marketplace.viewSaleReceipt(signers[1].address,1));     
    }) 

    it("", async() => {

    })

})