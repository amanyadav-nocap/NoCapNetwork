import {
  ChronNFT,
  ChronNFT__factory,
  Usd,
  Usd__factory,
  Vault,
  VaultFactory,
  VaultFactory__factory,
  Vault__factory,
} from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { expect } from "chai";
import "solidity-coverage";

import { expandTo18Decimals } from "./utilities/utilities";

describe("chroncept", async () => {
  let NFT: ChronNFT;
  let vault: Vault;
  let factory: VaultFactory;
  let signers: SignerWithAddress[];
  let owner: SignerWithAddress;
  let USDT: Usd;

  beforeEach(async () => {
    signers = await ethers.getSigners();
    owner = signers[0];
    NFT = await new ChronNFT__factory(owner).deploy();
    USDT = await new Usd__factory(owner).deploy();
    vault = await new Vault__factory(owner).deploy();
    factory = await new VaultFactory__factory(owner).deploy();
    await vault.initialize(
      "TestName",
      "TestSymbol",
      10,
      NFT.address,
      1,
      expandTo18Decimals(100),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    await factory.initialize(vault.address);
    await NFT.initialize("TestName", "TestSymbol", factory.address);
    //await factory.connect(owner).addOperator(NFT.address,true);
  });

  it("revert initialize", async () => {
    //   await factory.initialize(vault.address)
    await expect(
      vault.initialize(
        "TestName",
        "TestSymbol",
        10,
        NFT.address,
        1,
        expandTo18Decimals(100),
        USDT.address,
        owner.address,
        owner.address,
        owner.address
      )
    ).to.be.revertedWith("Initializable: contract is already initialized");
    //   await NFT.initialize("TestName","TestSymbol",factory.address);
    await expect(
      NFT.initialize("TestName", "TestSymbol", factory.address)
    ).to.be.revertedWith("Initializable: contract is already initialized");
  });

  it("symbol", async () => {
    const symbol = await vault.symbol();
    expect("TestSymbol").to.be.eq(symbol);
  });

  it("name", async () => {
    const name = await vault.name();
    expect("TestName").to.be.eq(name);
  });

  it("NFT mint ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
  });

  it("NFT burn ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    await NFT.connect(owner).burn(1);
  });

  it("ERROR : Non Operator caller", async () => {
    await factory.connect(owner).addOperator(signers[1].address, true);
    await expect(
      NFT.connect(owner).safeMint(
        "test_name",
        "test_symbol",
        1,
        "test",
        30,
        expandTo18Decimals(10),
        USDT.address,
        owner.address,
        owner.address,
        owner.address
      )
    ).to.be.revertedWith("NO");
  });
  it("ERROR:zero address set as Operator ", async () => {
    await expect(
      factory
        .connect(owner)
        .addOperator("0x0000000000000000000000000000000000000000", true)
    ).to.be.revertedWith("ZA");
  });

  it("ERROR: Vault address updated to zero address ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    await expect(
      factory
        .connect(owner)
        .updateVault("0x0000000000000000000000000000000000000000")
    ).to.be.revertedWith("ZA");
  });

  it("Buy NFT", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(10)
    );
    await vault_instance.connect(signers[1]).buyFractions(1);
  });

  it("Buy NFT through multiple vault ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    await NFT.connect(owner).safeMint(
      "test_name2",
      "test_symbol2",
      2,
      "test",
      20,
      expandTo18Decimals(15),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );

    let v1 = await factory.connect(owner).viewVault(1);
    let v2 = await factory.connect(owner).viewVault(2);

    const vault_instance = await new Vault__factory(owner).attach(v1);
    const vault_instance2 = await new Vault__factory(owner).attach(v2);

    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(10)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance2.address,
      expandTo18Decimals(20)
    );

    await vault_instance.connect(signers[1]).buyFractions(1);
    await vault_instance2.connect(signers[1]).buyFractions(1);
  });

  it("ERROR: all fractions sold", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );

    let v1 = await factory.connect(owner).viewVault(1);

    const vault_instance = await new Vault__factory(owner).attach(v1);

    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(400)
    );

    await vault_instance.connect(signers[1]).buyFractions(30);
    await expect(
      vault_instance.connect(signers[1]).buyFractions(1)
    ).to.be.revertedWith("AFS");
  });
  it("ERROR: Not Enough Supply", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );

    let v1 = await factory.connect(owner).viewVault(1);

    const vault_instance = await new Vault__factory(owner).attach(v1);

    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(400)
    );

    await expect(
      vault_instance.connect(signers[1]).buyFractions(31)
    ).to.be.revertedWith("NES");
  });

  it("ERROR : No allowance ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(10)
    );
    await vault_instance.connect(signers[1]).buyFractions(1);
    await expect(
      vault_instance.connect(signers[2]).buyFractions(1)
    ).to.be.revertedWith("ERC20: insufficient allowance");
  });

  it("ERROR :insufficient allowance for buying fraction ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(10)
    );
    await vault_instance.connect(signers[1]).buyFractions(1);
    await expect(
      vault_instance.connect(signers[1]).buyFractions(1)
    ).to.be.revertedWith("ERC20: insufficient allowance");
  });
  it("ERROR: Offer buyout before primary buy ends ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(300)
    );
    await vault_instance.connect(signers[1]).buyFractions(29);
    await expect(
      vault_instance.connect(signers[1]).makeOffer(expandTo18Decimals(200))
    ).to.be.revertedWith("NAY");
  });

  it("ERROR: buyout price same as nft price ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(1000)
    );
    await vault_instance.connect(signers[1]).buyFractions(30);
    await expect(
      vault_instance.connect(signers[1]).makeOffer(expandTo18Decimals(10))
    ).to.be.revertedWith("PL");
  });

  it("ERROR: buyout price too low", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(1000)
    );
    await vault_instance.connect(signers[1]).buyFractions(30);
    await expect(
      vault_instance.connect(signers[1]).makeOffer(expandTo18Decimals(8))
    ).to.be.revertedWith("PL");
  });

  it("Buyout offer", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(300)
    );
    await vault_instance.connect(signers[1]).buyFractions(30);
    await USDT.connect(owner).mint(
      signers[2].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(330)
    );
    await vault_instance.connect(signers[2]).makeOffer(expandTo18Decimals(11));
  });

  it("multiple Buyout offer ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      30,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(300)
    );
    await vault_instance.connect(signers[1]).buyFractions(30);
    // 1st buyout offer
    await USDT.connect(owner).mint(
      signers[2].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(330)
    );
    await vault_instance.connect(signers[2]).makeOffer(expandTo18Decimals(11));
    // 2nd buyout offer
    await USDT.connect(owner).mint(
      signers[3].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(390)
    );
    await vault_instance.connect(signers[3]).makeOffer(expandTo18Decimals(13));
    // 3rd buyout offer
    await USDT.connect(owner).mint(
      signers[4].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[4]).approve(
      vault_instance.address,
      expandTo18Decimals(450)
    );
    await vault_instance.connect(signers[4]).makeOffer(expandTo18Decimals(15));
    // 4th buyout offer, with same price
    await USDT.connect(owner).mint(
      signers[5].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[5]).approve(
      vault_instance.address,
      expandTo18Decimals(450)
    );
    await vault_instance.connect(signers[5]).makeOffer(expandTo18Decimals(15));
  });

  // it('votes for multiple buyout ', async () => {

  //     await factory.connect(owner).addOperator(NFT.address, true);
  //     await NFT.connect(owner).safeMint("test_name", "test_symbol", 1, "test", 20, expandTo18Decimals(10), USDT.address, owner.address, owner.address, owner.address);
  //     let v1 = await factory.connect(owner).viewVault(1);
  //     const vault_instance = await new Vault__factory(owner).attach(v1)
  //     await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(1000));
  //     await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(1000));
  //     await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(1000));
  //     await USDT.connect(owner).mint(signers[4].address, expandTo18Decimals(1000));
  //     await USDT.connect(owner).mint(signers[5].address, expandTo18Decimals(1000));

  //     await USDT.connect(signers[1]).approve(vault_instance.address, expandTo18Decimals(1000));
  //     await USDT.connect(signers[2]).approve(vault_instance.address, expandTo18Decimals(110));
  //     await USDT.connect(signers[3]).approve(vault_instance.address, expandTo18Decimals(50));
  //     await USDT.connect(signers[4]).approve(vault_instance.address, expandTo18Decimals(50));
  //     await USDT.connect(signers[5]).approve(vault_instance.address, expandTo18Decimals(100));

  //     //fractional buy
  //     await vault_instance.connect(signers[1]).buyFractions(5);
  //     await vault_instance.connect(signers[2]).buyFractions(6);
  //     await vault_instance.connect(signers[3]).buyFractions(3);
  //     await vault_instance.connect(signers[4]).buyFractions(1);
  //     await vault_instance.connect(signers[5]).buyFractions(5);
  //     // 1st buyout offer
  //     await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(1000));
  //     await USDT.connect(signers[6]).approve(vault_instance.address, expandTo18Decimals(220));
  //     await(vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11)));
  //     // 2nd buyout offer
  //     await USDT.connect(owner).mint(signers[7].address, expandTo18Decimals(1000));
  //     await USDT.connect(signers[7]).approve(vault_instance.address, expandTo18Decimals(260));
  //     await(vault_instance.connect(signers[7]).makeOffer(expandTo18Decimals(13)));
  //     // 3rd buyout offer
  //     await USDT.connect(owner).mint(signers[8].address, expandTo18Decimals(1000));
  //     await USDT.connect(signers[8]).approve(vault_instance.address, expandTo18Decimals(450));
  //     await(vault_instance.connect(signers[8]).makeOffer(expandTo18Decimals(15)));
  //     console.log("spender",await(USDT.allowance(signers[1].address,vault_instance.address)));

  //     await(vault_instance.connect(signers[1]).voteOffer(0,true));

  // });

  it("ERROR: voter do not hold any fraction", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[2].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[3].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[4].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[5].address,
      expandTo18Decimals(1000)
    );

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(900)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(110)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(50)
    );
    await USDT.connect(signers[4]).approve(
      vault_instance.address,
      expandTo18Decimals(50)
    );
    await USDT.connect(signers[5]).approve(
      vault_instance.address,
      expandTo18Decimals(100)
    );
    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(5);
    await vault_instance.connect(signers[2]).buyFractions(6);
    await vault_instance.connect(signers[3]).buyFractions(3);
    await vault_instance.connect(signers[4]).buyFractions(1);
    await vault_instance.connect(signers[5]).buyFractions(5);
    // 1st buyout offer
    await USDT.connect(owner).mint(
      signers[6].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );
    await vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11));
    // 2nd buyout offer
    await USDT.connect(owner).mint(
      signers[7].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[7]).approve(
      vault_instance.address,
      expandTo18Decimals(260)
    );
    await vault_instance.connect(signers[7]).makeOffer(expandTo18Decimals(13));
    await expect(
      vault_instance.connect(signers[6]).voteOffer(1, true)
    ).to.be.revertedWith("NF");
  });

  it("ERROR: offerer not allowed to vote", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(
      signers[1].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[2].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[3].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[4].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(owner).mint(
      signers[5].address,
      expandTo18Decimals(1000)
    );

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(900)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(110)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(50)
    );
    await USDT.connect(signers[4]).approve(
      vault_instance.address,
      expandTo18Decimals(50)
    );
    await USDT.connect(signers[5]).approve(
      vault_instance.address,
      expandTo18Decimals(100)
    );

    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(5);
    await vault_instance.connect(signers[2]).buyFractions(6);
    await vault_instance.connect(signers[3]).buyFractions(3);
    await vault_instance.connect(signers[4]).buyFractions(1);
    await vault_instance.connect(signers[5]).buyFractions(5);
    // 1st buyout offered by fraction holder
    await USDT.connect(owner).mint(
      signers[5].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[5]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );
    await vault_instance.connect(signers[5]).makeOffer(expandTo18Decimals(11));
    // 2nd buyout offer
    await USDT.connect(owner).mint(
      signers[7].address,
      expandTo18Decimals(1000)
    );
    await USDT.connect(signers[7]).approve(
      vault_instance.address,
      expandTo18Decimals(260)
    );
    await vault_instance.connect(signers[7]).makeOffer(expandTo18Decimals(13));
    //offerer voting for himself
    await expect(
      vault_instance.connect(signers[5]).voteOffer(1, true)
    ).to.be.revertedWith("ONA");
  });

  it("voting for buyout successful", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    console.log("owner of NFT", await NFT.connect(owner).ownerOf(1));
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(70)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );

    console.log("signer 1", signers[1].address);
    console.log("signer 2", signers[2].address);
    console.log("signer 3", signers[3].address);
    console.log("signer 6", signers[6].address);
    console.log("vault", vault_instance.address);

    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(7);
    await vault_instance.connect(signers[2]).buyFractions(9);
    await vault_instance.connect(signers[3]).buyFractions(4);

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11));
    // vote
    // await vault_instance.connect(signers[1]).approve(signers[1].address,7);
    console.log(
      "balanceeeee",
      await vault_instance.balanceOf(signers[1].address)
    );
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    console.log("balanceeeee", await USDT.balanceOf(signers[6].address));
    expect(await USDT.balanceOf(signers[1].address)).to.be.eq(
      expandTo18Decimals(107)
    );
    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(0);

    await vault_instance.connect(signers[2]).voteOffer(1, false);
    await vault_instance.connect(signers[3]).voteOffer(1, true);
    expect(await vault_instance.balanceOf(signers[3].address)).to.be.eq(0);

    expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(11);

    await vault_instance.connect(signers[6]).claim(1);

    expect(await NFT.connect(owner).ownerOf(1)).to.be.eq(signers[6].address);
  });

  it("ERROR :voting for buyout at 50% unsuccessful", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(70)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );

    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(7);
    await vault_instance.connect(signers[2]).buyFractions(9);
    await vault_instance.connect(signers[3]).buyFractions(4);

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11));
    // vote
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    await vault_instance.connect(signers[2]).voteOffer(1, false);
    await vault_instance.connect(signers[3]).voteOffer(1, false);
    //console.log("spender",await(USDT.allowance(signers[1].address,vault_instance.address)));
    await expect(
      vault_instance.connect(signers[6]).claim(1)
    ).to.be.revertedWith("NE");
  });

  it("ERROR :NFT claimer should be an Offerer", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(70)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );

    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(7);
    await vault_instance.connect(signers[2]).buyFractions(9);
    await vault_instance.connect(signers[3]).buyFractions(4);

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11));
    // vote
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    await vault_instance.connect(signers[2]).voteOffer(1, false);
    await vault_instance.connect(signers[3]).voteOffer(1, true);
    //console.log("spender",await(USDT.allowance(signers[1].address,vault_instance.address)));
    await expect(
      vault_instance.connect(signers[4]).claim(1)
    ).to.be.revertedWith("NO");
  });

  it("Claim share after buyout succesfull", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      10,
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    console.log("owner of NFT", await NFT.connect(owner).ownerOf(1));
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(120));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(110)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );

    //fractional buy
    await vault_instance
      .connect(signers[1])
      .buyFractions(expandTo18Decimals(11));
    await vault_instance
      .connect(signers[2])
      .buyFractions(expandTo18Decimals(9));
    // await vault_instance
    //   .connect(signers[3])
    //   .buyFractions(expandTo18Decimals(4));

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(11);
    // vote
    // await vault_instance.connect(signers[1]).approve(signers[1].address,7);
    console.log(
      "balanceeeee",
      await vault_instance.balanceOf(signers[1].address)
    );
    console.log(
      "fraction balance",
      await vault_instance.balanceOf(signers[1].address)
    );
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    console.log(
      "fraction balance",
      await vault_instance.balanceOf(owner.address)
    );
    console.log("balanceeeee", await USDT.balanceOf(signers[6].address));
 //  expect(await USDT.balanceOf(signers[1].address)).to.be.eq(expandTo18Decimals(107));
    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(0);

    // await vault_instance.connect(signers[2]).voteOffer(1, false);
    // await vault_instance.connect(signers[3]).voteOffer(1, true);
    // expect(await vault_instance.balanceOf(signers[3].address)).to.be.eq(0);

   // expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(11);

    await vault_instance.connect(signers[6]).claim(1);
    expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(0);

    expect(await NFT.connect(owner).ownerOf(1)).to.be.eq(signers[6].address);

    await vault_instance.connect(signers[2]).claimShare();
    // expect(await vault_instance.balanceOf(signers[2].address)).to.be.eq(0);

    //  await expect (vault_instance.connect(signers[1]).claimShare()).to.be.revertedWith("AC");
  });

  it("ERROR: Share already claimed", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    console.log("owner of NFT", await NFT.connect(owner).ownerOf(1));
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(70)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );
    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(7);
    await vault_instance.connect(signers[2]).buyFractions(9);
    await vault_instance.connect(signers[3]).buyFractions(4);

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11));
    // vote
    // await vault_instance.connect(signers[1]).approve(signers[1].address,7);
    console.log(
      "balanceeeee",
      await vault_instance.balanceOf(signers[1].address)
    );
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    console.log("balanceeeee", await USDT.balanceOf(signers[6].address));
    expect(await USDT.balanceOf(signers[1].address)).to.be.eq(
      expandTo18Decimals(107)
    );
    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(0);

    await vault_instance.connect(signers[2]).voteOffer(1, false);
    await vault_instance.connect(signers[3]).voteOffer(1, true);
    expect(await vault_instance.balanceOf(signers[3].address)).to.be.eq(0);

    expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(11);

    await vault_instance.connect(signers[6]).claim(1);
    expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(0);
    expect(await vault_instance.balanceOf(vault_instance.address)).to.be.eq(11);

    expect(await NFT.connect(owner).ownerOf(1)).to.be.eq(signers[6].address);

    await vault_instance.connect(signers[2]).claimShare();
    expect(await vault_instance.balanceOf(signers[2].address)).to.be.eq(0);
    await expect(
      vault_instance.connect(signers[2]).claimShare()
    ).to.be.revertedWith("AC");
  });

  it("ERRROR: cannot claim share as NFT is not sold ", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    console.log("owner of NFT", await NFT.connect(owner).ownerOf(1));
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(70)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );
    //fractional buy
    await vault_instance.connect(signers[1]).buyFractions(7);
    await vault_instance.connect(signers[2]).buyFractions(9);
    await vault_instance.connect(signers[3]).buyFractions(4);

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(expandTo18Decimals(11));
    // vote
    // await vault_instance.connect(signers[1]).approve(signers[1].address,7);
    console.log(
      "balanceeeee",
      await vault_instance.balanceOf(signers[1].address)
    );
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    console.log("balanceeeee", await USDT.balanceOf(signers[6].address));
    expect(await USDT.balanceOf(signers[1].address)).to.be.eq(
      expandTo18Decimals(107)
    );
    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(0);

    await expect(
      vault_instance.connect(signers[2]).claimShare()
    ).to.be.revertedWith("NFT not sold");
  });

  it("ERROR :Vault already exists for the token ID", async () => {
    // add operator before NFT mint and vault creation
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      expandTo18Decimals(10),
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    await expect(
      NFT.connect(signers[1]).safeMint(
        "test_name1",
        "test_symbol1",
        1,
        "test",
        30,
        expandTo18Decimals(11),
        USDT.address,
        owner.address,
        owner.address,
        owner.address
      )
    ).to.be.revertedWith("VE");
  });
  // it('ERROR :Vault already exists for the token ID',async() =>{
  //     // add operator before NFT mint and vault creation
  //     await factory.connect(owner).addOperator(NFT.address, true);
  //     await NFT.connect(owner).safeMint("test_name", "test_symbol", 1, "test", 20, expandTo18Decimals(10), USDT.address, owner.address, owner.address, owner.address);
  // })

  it("flow check", async () => {
    // add operator before NFT mint and vault creation
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(signers[4]).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      10,
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );

    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    expect(
      await vault_instance.connect(owner).balanceOf(vault_instance.address)
    ).to.be.eq(expandTo18Decimals(20));
    expect(await NFT.connect(owner).ownerOf(1)).to.be.eq(
      vault_instance.address
    );

    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[3].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));
    // allowance
    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(70)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(90)
    );
    await USDT.connect(signers[3]).approve(
      vault_instance.address,
      expandTo18Decimals(40)
    );

    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(0);
    await vault_instance
      .connect(signers[1])
      .buyFractions(expandTo18Decimals(7));
    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(7);
    await vault_instance
      .connect(signers[2])
      .buyFractions(expandTo18Decimals(9));
    await vault_instance
      .connect(signers[3])
      .buyFractions(expandTo18Decimals(4));
  });


  it.only("Claim share testing", async () => {
    await factory.connect(owner).addOperator(NFT.address, true);
    await NFT.connect(owner).safeMint(
      "test_name",
      "test_symbol",
      1,
      "test",
      20,
      10,
      USDT.address,
      owner.address,
      owner.address,
      owner.address
    );
    console.log("owner of NFT", await NFT.connect(owner).ownerOf(1));
    let v1 = await factory.connect(owner).viewVault(1);
    const vault_instance = await new Vault__factory(owner).attach(v1);
    await USDT.connect(owner).mint(signers[1].address, expandTo18Decimals(120));
    await USDT.connect(owner).mint(signers[2].address, expandTo18Decimals(100));
    await USDT.connect(owner).mint(signers[6].address, expandTo18Decimals(250));

    await USDT.connect(signers[1]).approve(
      vault_instance.address,
      expandTo18Decimals(120)
    );
    await USDT.connect(signers[2]).approve(
      vault_instance.address,
      expandTo18Decimals(80)
    );
    await USDT.connect(signers[6]).approve(
      vault_instance.address,
      expandTo18Decimals(220)
    );

    //fractional buy
    await vault_instance
      .connect(signers[1])
      .buyFractions(expandTo18Decimals(12));
    await vault_instance
      .connect(signers[2])
      .buyFractions(expandTo18Decimals(8));

    // 1st buyout offer
    await vault_instance.connect(signers[6]).makeOffer(11);
    // vote
    // await vault_instance.connect(signers[1]).approve(signers[1].address,7);
    console.log(
      "balanceeeee",
      await vault_instance.balanceOf(signers[1].address)
    );
    console.log(
      "fraction balance",
      await vault_instance.balanceOf(signers[1].address)
    );
    await vault_instance.connect(signers[1]).voteOffer(1, true);
    console.log(
      "fraction balance",
      await vault_instance.balanceOf(owner.address)
    );
    console.log("balanceeeee", await USDT.balanceOf(signers[6].address));
 //  expect(await USDT.balanceOf(signers[1].address)).to.be.eq(expandTo18Decimals(107));
    expect(await vault_instance.balanceOf(signers[1].address)).to.be.eq(0);

    // expect(await vault_instance.balanceOf(signers[3].address)).to.be.eq(0);

   // expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(11);

    await vault_instance.connect(signers[6]).claim(1);
    expect(await vault_instance.balanceOf(signers[6].address)).to.be.eq(0);

    expect(await NFT.connect(owner).ownerOf(1)).to.be.eq(signers[6].address);

    await vault_instance.connect(signers[2]).claimShare();
    // expect(await vault_instance.balanceOf(signers[2].address)).to.be.eq(0);

    //  await expect (vault_instance.connect(signers[1]).claimShare()).to.be.revertedWith("AC");
  });
});
