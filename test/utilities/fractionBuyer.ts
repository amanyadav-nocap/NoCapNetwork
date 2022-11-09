// import { ethers ,waffle} from "hardhat";

const SIGNING_DOMAIN_NAME = "Chroncept_MarketItem"; // encode krne ke liye salt lgti hai  ex:-  adding formula  values alg dono ki 2 persons
const SIGNING_DOMAIN_VERSION = "1";

/**
 *
 * LazyMinting is a helper class that creates NFTVoucher objects and signs them, to be redeemed later by the LazyNFT contract.
 */
class fractionBuyerVoucher {
  public contract: any;
  public signer: any;
  public _domain: any;
  public voucherCount: number = 0;
  public signer2: any;

  constructor(data: any) {
    const { _contract, _signer } = data;
    this.contract = _contract;
    this.signer = _signer;
    // console.log(_signer.address,_contract.address,"contract and address");
  }

  async createVoucher(
    buyer: any,
    fractionVault: any,
    fractionBuyAmount: any,
    pricePaid: any
  ) {
    const voucher = {
      buyer,
      fractionVault,
      fractionBuyAmount,
      pricePaid,
    };
    const domain = await this._signingDomain();
    const types = {
      fractionBuyer: [
        { name: "buyer", type: "address" },
        { name: "fractionVault", type: "address" },
        { name: "fractionBuyAmount", type: "uint256" },
        { name: "pricePaid", type: "uint256" },
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
    const chainId = await this.contract.getChainID();
    this._domain = {
      name: SIGNING_DOMAIN_NAME,
      version: SIGNING_DOMAIN_VERSION,
      verifyingContract: this.contract.address,
      chainId,
    };
    return this._domain;
  }
}

export default fractionBuyerVoucher;
