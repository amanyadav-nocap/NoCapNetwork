// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

import "Interfaces/IUSDT.sol";

contract vault is ERC20Upgradeable, ERC721HolderUpgradeable, OwnableUpgradeable {
    address public admin;
    IUSDT public usdt;
    address public token721;
    uint256 public fractionPrice;
    uint256 public tokenID;
    uint256 public fractionSupply;
    uint256 private offerNumber;
    bool primaryBuyEnd;
    bool NFTSold;
    uint private finalOfferredAmount;
    uint256 [] offerrers;
    struct offer {
        address offerrer;
        uint256 offerred;
        uint256 paidAmount;
    }
    mapping(uint256 => offer) private offerredAmounts;
    

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _tokenSupply,
        address _token721,
        uint256 _tokenID,
        uint256 _fractionPrice,
        address _usdt,
        address _admin
    ) external initializer{
        __Ownable_init();
        require(_admin != address(0), "ZAA"); //Zero address for admin
        require(_token721 != address(0), "ZAT"); //Zero address for token
        __ERC721Holder_init();
        __ERC20_init_unchained(_name, _symbol);
        admin = _admin;
        token721 = _token721;
        usdt = IUSDT(_usdt);
        fractionPrice = _fractionPrice;
        tokenID = _tokenID;
        mint(address(this), _tokenSupply);
        fractionSupply = totalSupply();
        offerNumber = 1 ; 
    }

    function mint(address _to, uint256 _amount) internal {
      //  require(totalSupply()+_amount<=tokenSupply,"IA");//Invalid amount
        _mint(_to, _amount);
    }

    function buyFractions(uint256 _fractionAmount) external {
        require(!primaryBuyEnd,"AFS");//All Fractions Sold
        require(fractionSupply >=_fractionAmount,"NES");//Not Enough Supply 
        IUSDT(usdt).transfer(msg.sender, owner(), _fractionAmount*fractionPrice);
        _transfer(address(this), msg.sender, _fractionAmount);

        fractionSupply =fractionSupply - _fractionAmount;
        if(fractionSupply==0)
            primaryBuyEnd = true;
        
    }

    function transfer(address _to, uint256 _amount)
        public
        override(ERC20Upgradeable)
        onlyOwner
        returns (bool)
    {

        require(_to != address(0), "ZA"); //zero address
        _transfer(address(this), _to, _amount);
        return true;
    }
// for make offer are we taking fraction price of nft price?
// can multiple people offer same amount?
    function makeOffer(uint256 offerredPrice) external {
        require(primaryBuyEnd, "NAY"); //Not Available Yet
        require(offerredPrice > fractionPrice, "PL"); //Price too low
        uint256 priceToPay = offerredPrice * totalSupply();
        IUSDT(usdt).transfer(msg.sender,address(this), priceToPay);
       console.log("vault balance",usdt.balanceOf(address(this)));
        offerredAmounts[offerNumber] = offer(
            msg.sender,
            offerredPrice,
            priceToPay
        );
        offerrers.push(offerNumber);
        offerNumber++;
    }

      function voteOffer(uint256 _offerNumber, bool vote) external {
        require(balanceOf(msg.sender) > 0, "NF"); //No Fractions
        require(msg.sender != offerredAmounts[_offerNumber].offerrer, "ONA"); //Offerrer not allowed
        if (vote == true) {  
            IUSDT(usdt).transfer(
                address(this),
                msg.sender,
                (balanceOf(msg.sender) * offerredAmounts[_offerNumber].offerred)
            );
               _transfer(
                msg.sender,
                offerredAmounts[_offerNumber].offerrer,
                balanceOf(msg.sender)
            );
            
        }
    }

    function claim(uint256 _offerNumber) external {
        require(msg.sender == offerredAmounts[_offerNumber].offerrer, "NO"); //Not Offerrer
        require(balanceOf(msg.sender) >= (totalSupply() * 51) / 100, "NE"); //Not Eligible
        offerredAmounts[_offerNumber].paidAmount = 0;
        NFTSold = true;
        _transfer(msg.sender, address(this), balanceOf(msg.sender));
        IERC721Upgradeable(token721).safeTransferFrom(
            address(this),
            offerredAmounts[_offerNumber].offerrer,
            tokenID
        );
        finalOfferredAmount = offerredAmounts[_offerNumber].offerred;
        bulkTransfer(offerrers);
        
    }
    function claimShare() external {
        require(NFTSold == true,"NFT not sold");
        require(balanceOf(msg.sender) !=0,"AC"); //Already Claimed
        uint256 _amount = balanceOf(msg.sender)*finalOfferredAmount;
        _transfer(msg.sender, address(this), balanceOf(msg.sender));
        IUSDT(usdt).transfer(address(this), msg.sender, _amount );
    }


    function bulkTransfer(uint256 [] memory _offerrers) internal {
        
        for(uint i =0; i< _offerrers.length; i++){
        
            _transfer(address(this), offerredAmounts[_offerrers[i]].offerrer , offerredAmounts[_offerrers[i]].paidAmount);
        }
            
        }

   
}
