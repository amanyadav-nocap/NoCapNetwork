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

    // await Hre.run("verify:verify", {
    //   //Deployed contract Factory address
    //   address: "0x158f32b6AD4f71B36A7E16106572e32aFF412eE4",
    //   constructorArguments: ["0x176fA33b0858BFe1aB3CbDF99CFa1D4126C01e4a","0xFff3097383b27b23fB486902c4f42247255542A7"],

    //   //Path of your main contract.
    //   contract: "contracts/SecurityToken/periphery/SecurityTokenFactory.sol:NoCapSecurityTokenFactory",
    // });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0x66D9512e6Cf45ba95586a8E7E1544Cef71521f08",
      constructorArguments: ["Yato","YTC",1000000],

      //Path of your main contract.
      contract: "contracts/token.sol:Token",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0xDeDDbF4a30C99Cb20E85806873ba603E6bA376CD",
      constructorArguments: ["Saitama","STM",1000000],

      //Path of your main contract.
      contract: "contracts/token.sol:Token",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0xF35871678B04E56a17531D92589BD62863CcF5FA",
      constructorArguments: ["Goku","GKC",1000000],

      //Path of your main contract.
      contract: "contracts/token.sol:Token",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0x06662846f8a08f74402A2d9e17A0b1aBCcE7A504",
      constructorArguments: ["Vegeta","VTC",1000000],

      //Path of your main contract.
      contract: "contracts/token.sol:Token",
    });

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