// import { ethers ,waffle} from "hardhat";

const SIGNING_DOMAIN_NAME = "Chroncept_MarketItem"; // encode krne ke liye salt lgti hai  ex:-  adding formula  values alg dono ki 2 persons
const SIGNING_DOMAIN_VERSION = "1";

/**
 *
 * LazyMinting is a helper class that creates NFTVoucher objects and signs them, to be redeemed later by the LazyNFT contract.
 */
class fractionSellerVoucher {
  public contract: any;
  public signer: any;
  public _domain: any;
  public voucherCount: number = 0;
  public signer2: any;

  constructor(data: any) {
    const { _contract, _signer } = data;
    this.contract = _contract;
    this.signer = _signer;
    console.log("contract and address",_signer.address,_contract.address);
  }

  async createVoucher(
    seller: any,
    fractionVault: any,
    fractionSellAmount: any,
    fractionPrice: any,
    counter: any
  ) {
    const voucher = {
      seller,
      fractionVault,
      fractionSellAmount,
      fractionPrice,
      counter,
    };
    const domain = await this._signingDomain();
    const types = {
      fractionSeller: [
        { name: "seller", type: "address" },
        { name: "fractionVault", type: "address" },
        { name: "fractionSellAmount", type: "uint256" },
        { name: "fractionPrice", type: "uint256" },
        { name: "counter", type: "uint256" },
      ],
    };

    const signature = await this.signer._signTypedData(domain, types, voucher);
    return {
      ...voucher,
      signature,
    };
  }

  async _signingDomain() {
    if (this._domain != null) {
      return this._domain;
    }
    const chainId = 31337;
    this._domain = {
      name: SIGNING_DOMAIN_NAME,
      version: SIGNING_DOMAIN_VERSION,
      verifyingContract: this.contract.address,
      chainId,
    };
    return this._domain;
  }
}

export default fractionSellerVoucher;
