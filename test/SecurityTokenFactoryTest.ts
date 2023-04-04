// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import { ethers } from "hardhat";
// import { ClaimTopicsRegistry, ClaimTopicsRegistry__factory, DefaultCompliance, DefaultCompliance__factory, Identity, IdentityInit__factory, IdentityRegistry, IdentityRegistryStorage, IdentityRegistryStorage__factory, IdentityRegistry__factory, Identity__factory, ImplementationAuthority, ImplementationAuthority__factory, NoCapSecurityTokenFactory, NoCapSecurityTokenFactory__factory, TokenST, TokenST__factory, TrustedIssuersRegistry, TrustedIssuersRegistry__factory } from "../typechain-types"

// describe("Security Token Factory Test Cases", ()=>{

//     let owner : SignerWithAddress;
//     let signers : SignerWithAddress[];
//     let STOFactory : NoCapSecurityTokenFactory;
//     let token : TokenST;
//     let compliance : DefaultCompliance;
//     let identityRegistry : IdentityRegistry;
//     let identityRegistryStorage : IdentityRegistryStorage;
//     let implementationAuthority : ImplementationAuthority;
//     let trustedIssuersRegistry : TrustedIssuersRegistry;
//     let claimsTopicsRegistry : ClaimTopicsRegistry;
//     let OwnerIdentity : Identity;
    
//     beforeEach(async()=>{
//         signers = await ethers.getSigners();
//         owner = signers[0];
//         STOFactory = await new NoCapSecurityTokenFactory__factory(owner).deploy();
//         token = await new TokenST__factory(owner).deploy();
//         compliance = await new DefaultCompliance__factory(owner).deploy();
//         identityRegistry = await new IdentityRegistry__factory(owner).deploy();
//         identityRegistryStorage = await new IdentityRegistryStorage__factory(owner).deploy();
//         implementationAuthority = await new ImplementationAuthority__factory(owner).deploy(token.address);
//         trustedIssuersRegistry = await new TrustedIssuersRegistry__factory(owner).deploy();
//         claimsTopicsRegistry = await new ClaimTopicsRegistry__factory(owner).deploy();
//         OwnerIdentity = await new Identity__factory(owner).deploy(owner.address,false);

//         await STOFactory.connect(owner).init(token.address,compliance.address,owner.address,identityRegistry.address,owner.address);
//         await identityRegistry.init(trustedIssuersRegistry.address,claimsTopicsRegistry.address,identityRegistryStorage.address);
//         await identityRegistryStorage.init();
//         await claimsTopicsRegistry.init();
//         await trustedIssuersRegistry.init();

//     })

//     it("Creating Token from STOFactory", async()=>{
//         let address = await STOFactory.connect(signers[1]).deployTokenForNFT("Sample","SMP",1,1,2);
       
//     })
// })