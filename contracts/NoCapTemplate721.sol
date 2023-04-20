//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library/Voucher.sol";
import "contracts/Interfaces/ISecurityTokenFactory.sol";
import "contracts/Interfaces/ITokenST.sol";


contract NoCapTemplateERC721 is ERC721URIStorageUpgradeable, ERC2981Upgradeable, EIP712Upgradeable, Ownable {

address public admin;
address public securityTokenFactory;
uint96 public royaltyAmount;
address public marketPlace;
uint public totalSupply;

mapping(uint=>address) public STOForTokenId;

modifier onlyAdmin{
    require(msg.sender==admin,"You are not the admin.");
    _;
}

function initialize(string memory _name, string memory _symbol, address _admin, uint96 _royaltyAmount,address _marketPlace, address _securityTokenFactory) external initializer {
    require(_admin != address(0), "ZAA"); //Zero Address for Admin
    require(_marketPlace != address(0), "ZAM");//Zero Address for Marketplace
    __ERC721_init_unchained(_name, _symbol);
    __ERC2981_init_unchained();
    __EIP712_init_unchained(_name, "1");
    royaltyAmount = _royaltyAmount;
    
    marketPlace = _marketPlace;
    securityTokenFactory = _securityTokenFactory;
}

// function hashOfferDetails(newVoucher.offer memory offer) internal view returns(bytes32){
//     return _hashTypedDataV4(keccak256(abi.encode(keccak256("offer(uint offerNumber,address offerer,uint tokenId, uint offeredPrice,address offeree,bytes signature)"),
//     offer.offerNumber,
//     offer.offerer,
//     offer.tokenId,
//     offer.offeredPrice,
//     offer.offeree,
//     offer.signature)
//     )
//   );
// }

// // function makeOffer()

// function verifyOfferDetails(newVoucher.offer memory offer) internal view returns(address) {
//     bytes32 digest = hashOfferDetails(offer);
//     return ECDSAUpgradeable.recover(digest, offer.signature);

// }

function updateTokenURI(uint tokenId, string memory _tokenURI) external onlyAdmin{
    _setTokenURI(tokenId, _tokenURI);
}

function updateRoyalty(uint _tokenId, address receiver, uint96 feeNumerator) external onlyAdmin {
    _setTokenRoyalty(_tokenId, receiver, feeNumerator);
}



function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

 function _msgData()
        internal
        pure
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

 function _msgSender()
        internal
        view
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

 function checkExist(uint _tokenId) external view returns(bool) {
    return _exists(_tokenId);
 }   

 function MintNft(address _to, uint _tokenId, string memory _tokenURI, address _royaltyKeeper,uint256 _maxFractions, uint256 _fractions, uint96 _royaltyFees) external returns(address){
     require(msg.sender== marketPlace, "Call only allowed from marketplace");
     if(STOForTokenId[_tokenId]==address(0)){
     address STO = ISecurityTokenFactory(securityTokenFactory).deployTokenForNFT("NoCap NFT STO", "NOCAPSTO", 0, _tokenId,_maxFractions);
     _safeMint(STO, _tokenId);
     _setTokenURI(_tokenId, _tokenURI);
     totalSupply++;
     if(_royaltyKeeper != address(0)){
     _setTokenRoyalty(_tokenId, _royaltyKeeper, _royaltyFees);}
     STOForTokenId[_tokenId] = STO;
     ITokenST(STO).mint(_to, _fractions);
     }
     else {
        ITokenST(STOForTokenId[_tokenId]).mint(_to, _fractions);
     }
     return STOForTokenId[_tokenId];
}

     function refund() external {
        
     }

     function getSTOForTokenId(uint256 _tokenId) external view returns(address){
        return STOForTokenId[_tokenId];
     }

     

}
