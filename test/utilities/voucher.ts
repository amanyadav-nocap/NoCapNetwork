const SIGNING_DOMAIN_NAME = "NoCap_MarketItem";
const SIGNING_DOMAIN_VERSION = "1";


/**
 *
 * LazyMinting is a helper class that creates NFTVoucher objects and signs them, to be redeemed later by the LazyNFT contract.
 */

class NoCapVoucher {
   public contract : any;
   public signer : any;
   public _domain : any;
   public voucherCount : any;
   public signer2 : any;

   constructor(data:any){
    const {_contract, _signer} = data;
    this.contract = _contract;
    this.signer = _signer;
   }

   async _signingDomain() {
    if(this._domain != null){
        return this._domain;
    }
    const chainId = 31337;
    this._domain = {
        name : SIGNING_DOMAIN_NAME,
        version : SIGNING_DOMAIN_VERSION,
        verifyingContract : this.contract.address,
        chainId,
    };
    return this._domain;
   }

   async createVoucher(
    seller : any,
    NFTAddress : any,
    tokenId : any,
    maxFractions : any,
    fractions : any,
    pricePerFraction : any,
    toMint : any,
    royaltyKeeper : any,
    royaltyFees : any,
    tokenURI : any
   ) {
    const voucher = {
       seller,
       NFTAddress,
       tokenId,
       maxFractions,
       fractions,
       pricePerFraction,
       toMint,
       royaltyKeeper,
       royaltyFees,
       tokenURI
    };
    const domain = await this._signingDomain();
    const types = {
        NFTVoucher: [
            {name: "seller", type: "address"},
            {name: "NFTAddress", type: "address"},
            {name: "tokenId", type: "uint256"},
            {name: "maxFractions", type: "uint256"},
            {name: "fractions", type: "uint256"},
            {name: "pricePerFraction", type: "uint256"},
            {name: "toMint", type: "bool"},
            {name: "royaltyKeeper", type: "address"},
            {name: "royaltyFees", type: "uint96"},
            {name: "tokenURI", type: "string"},
        ],
    };
    const signature = await this.signer._signTypedData(domain, types, voucher);
    return{
        ...voucher,
        signature,
    };
   }

}

export default NoCapVoucher;