const Hre = require("hardhat");

async function main() {

    // await Hre.run("verify:verify", {
    //   //Deployed contract Template1155 address
    //   address: "0xeC310568ad9732d03a7E5bbA735f4a4430169DAD",
    //   //Path of your main contract.
    //   contract: "contracts/NoCapFactory.sol:NoCapFactory",
    // });

    // await Hre.run("verify:verify", {
    //   //Deployed contract Template721 address
    //   address: "0x2FB80D65A770B2E35bA7A37F0A7C0c2254Ea81b1",
    //   //Path of your main contract.
    //   contract: "contracts/NoCapMarketplace.sol:NoCapMarketplace",
    // });

    // await Hre.run("verify:verify", {
    //   //Deployed contract Factory address
    //   address: "0x89AC09865B1D1C72D814c1a97a1d2D3cfdBA7BBe",
    //   //Path of your main contract.
    //   contract: "contracts/NoCapTemplate721.sol:NoCapTemplateERC721",
    // });

    await Hre.run("verify:verify", {
      //Deployed contract Factory address
      address: "0x158f32b6AD4f71B36A7E16106572e32aFF412eE4",
      //Path of your main contract.
      contract: "contracts/SecurityToken/periphery/SecurityTokenFactory.sol:NoCapSecurityTokenFactory",
    });

    // await Hre.run("verify:verify", {
    //   //Deployed contract Marketplace address
    //   address: "0xd50F438b0a04D29d64Eb62ADe83Aa0f5a7EAfec9",
    //   //Path of your main contract.
    //   contract: "contracts/SingleMarket.sol:SingleMarket",
    // });

    // await Hre.run("verify:verify",{
    //   //Deployed contract MarketPlace proxy
    //   address: "0x79475e917e705799184b13Fbb31DA8e886Be55F5",
    //   //Path of your main contract.
    //   contract: "contracts/OwnedUpgradeabilityProxy.sol:OwnedUpgradeabilityProxy"
    // });


    // await Hre.run("verify:verify",{
    //   //Deployed contract Factory proxy
    //   address: "0xDa9e500b5Ab914Dab5391b177798DA62Edbc1331",
    //   //Path of your main contract.
    //   contract: "contracts/OwnedUpgradeabilityProxy.sol:OwnedUpgradeabilityProxy"
    // });
}
main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});