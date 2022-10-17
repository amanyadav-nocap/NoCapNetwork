// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IVault.sol";

contract vault is ERC20Upgradeable,ERC721HolderUpgradeable,Ownable,IVault{
    address public admin;
    address public usdt;
    address public token721;
    uint256 public fractionPrice;
    uint256 public tokenID;
    uint256 public tokenSupply;
    uint256 private offerNumber=1;
    struct offer{
        address offerrer;
        uint256 offerred;
        uint256 paidAmount;
    }
    mapping(uint256=>offer) private offerredAmounts; 

    function initialize(string memory _name, string memory _symbol,uint256 _tokenSupply,address _token721,uint256 _tokenID,uint256 _fractionPrice,address _usdt,address _admin)external virtual initializer{
        require(_admin!=address(0),"ZAA");//Zero address for admin
        require(_token721!=address(0),"ZAT");//Zero address for token
        __ERC721Holder_init();
        __ERC20_init(_name,_symbol);
        admin = _admin;
        token721 = _token721;
        usdt = _usdt;
        fractionPrice = _fractionPrice;
        tokenID = _tokenID;
        IERC721Upgradeable(token721).safeTransferFrom(admin,address(this),tokenID);
        mint(address(this),_tokenSupply);

    }

    function mint(address _to, uint256 _amount) internal virtual onlyOwner {

        require(totalSupply()+_amount<=tokenSupply,"IA");//Invalid amount
        _mint(_to,_amount);

    }

    function transfer(address _to, uint256 _amount) public virtual override(ERC20Upgradeable) returns (bool){
        require(_to!=address(0),"ZA");//zero address
        _transfer(address(this),_to,_amount);
        return true;
    }
    function makeOffer(uint256 offerredPrice) external virtual {
        require(balanceOf(address(this))==0,"NAY");//Not Available Yet
        require(offerredPrice > fractionPrice,"PL");//Price too low
        uint256 priceToPay = offerredPrice*tokenSupply;
        IERC20Upgradeable(usdt).transfer(address(this), priceToPay);
        offerredAmounts[offerNumber] = offer(msg.sender,offerredPrice,priceToPay);
        offerNumber++;
    }

    function voteOffer(uint256 _offerNumber, bool vote) external virtual {
        require(balanceOf(msg.sender) > 0 ,"NF"); //No Fractions
        require(msg.sender != offerredAmounts[_offerNumber].offerrer,"ONA");//Offerrer not allowed
        if(vote == true){
            IERC20Upgradeable(usdt).transferFrom(address(this), msg.sender, (balanceOf(msg.sender)*offerredAmounts[_offerNumber].offerred));
            transferFrom(msg.sender,offerredAmounts[_offerNumber].offerrer,balanceOf(msg.sender));
        } 
    }


    function claim(uint256 _offerNumber) external virtual{
        require(msg.sender == offerredAmounts[_offerNumber].offerrer,"NO" );//Not Offerrer
        require(balanceOf(msg.sender) >= (totalSupply()*51)/100 ,"NE");//Not Eligible
        IERC721Upgradeable(token721).safeTransferFrom(address(this),msg.sender,tokenID);
    }

    function _msgSender() internal view virtual override(ContextUpgradeable,Context) returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual override(ContextUpgradeable,Context) returns (bytes calldata) {
        return msg.data;
    }
}