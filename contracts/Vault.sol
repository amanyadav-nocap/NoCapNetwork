// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";
import "Interfaces/IUSDT.sol";

contract vault is
    ERC20Upgradeable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable
{
    address public admin;
    address private taxWallet;
    address private marketFeeWallet;
    IUSDT public usdt;
    address public token721;
    uint256 public fractionPrice;
    uint256 public tokenID;
    uint256 public fractionSupply;
    uint256 private tokenAmount;
    uint256 private offerNumber;
    bool primaryBuyEnd;
    bool NFTSold;
    uint256 private finalOfferredAmount;
    uint256[] offerrers;

    struct offer {
        address offerrer;
        uint256 offerred;
        uint256 fractionAcquired;
    }
    mapping(uint256 => offer) private offerredAmounts;
    mapping(address => bool) private excludeFee;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _tokenSupply,
        address _token721,
        uint256 _tokenID,
        uint256 _fractionPrice,
        address _usdt,
        address _admin,
        address _taxWallet,
        address _marketFeeWallet
    ) external initializer {
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
        offerNumber = 1;
        taxWallet = _taxWallet;
        marketFeeWallet = _marketFeeWallet;
    }

    function mint(address _to, uint256 _amount) internal {
        //  require(totalSupply()+_amount<=tokenSupply,"IA");//Invalid amount
        _mint(_to, _amount * 10**decimals());
        // console.log("totalSupply", totalSupply());
    }

    function buyFractions(uint256 _fractionAmount) external {
        require(!primaryBuyEnd, "AFS"); //All Fractions Sold
        require(fractionSupply >= _fractionAmount, "NES"); //Not Enough Supply
        // IUSDT(usdt)._transferFrom(msg.sender, marketFeeWallet, (_fractionAmount*fractionPrice*1)/100);//Platform Fee
        uint256 amount = _fractionAmount * fractionPrice;
        IUSDT(usdt).transferFrom(
            msg.sender,
            marketFeeWallet,
            (amount * 1) / 100
        );
        IUSDT(usdt).transferFrom(
            msg.sender,
            owner(),
            (amount - ((amount * 1) / 100))
        );
        _transfer(address(this), msg.sender, _fractionAmount);
        tokenAmount = tokenAmount + balanceOf(msg.sender);
        fractionSupply = fractionSupply - _fractionAmount;
        if (fractionSupply == 0) primaryBuyEnd = true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20Upgradeable) {
        require(_to != address(0), "ZA"); //zero address
        if (excludeFee[msg.sender]) {
            super._transfer(_from, _to, _amount);
        } else {
            uint256 amountTransferred = _amount - ((_amount * 25) / 1000);
            super._transfer(_from, taxWallet, (_amount * 25) / 1000); //TAX amount
            super._transfer(_from, _to, amountTransferred);
        }
    }

    // for make offer are we taking fraction price of nft price?
    // can multiple people offer same amount?
    function makeOffer(uint256 offerredPrice) external {
        require(primaryBuyEnd, "NAY"); //Not Available Yet
        require(offerredPrice > fractionPrice, "PL"); //Price too low
        IUSDT(usdt)._transferFrom(
            msg.sender,
            address(this),
            offerredPrice * totalSupply()
        );
        console.log("vault balance", usdt.balanceOf(address(this)));
        offerredAmounts[offerNumber].offerrer = msg.sender;
        offerredAmounts[offerNumber].offerred = offerredPrice;
        // offerrers.push(offerNumber);
        offerNumber++;
    }

    function voteOffer(uint256 _offerNumber) external {
        require(balanceOf(msg.sender) != 0, "AV"); //Already Voted
        require(msg.sender != offerredAmounts[_offerNumber].offerrer, "ONA"); //Offerrer not allowed
        offerredAmounts[_offerNumber].fractionAcquired =
            offerredAmounts[_offerNumber].fractionAcquired +
            balanceOf(msg.sender);
        //      IUSDT(usdt).transfer(
        //     address(this),
        //     marketFeeWallet,
        //     (offerredAmounts[_offerNumber].paidAmount * 1) / 100
        // ); //Platform Fee
        _transfer(
            msg.sender,
            offerredAmounts[_offerNumber].offerrer,
            balanceOf(msg.sender)
        );

        IUSDT(usdt).transfer(
            address(this),
            msg.sender,
            (balanceOf(msg.sender) * offerredAmounts[_offerNumber].offerred)
        );
    }

    function claim(uint256 _offerNumber) external {
        require(msg.sender == offerredAmounts[_offerNumber].offerrer, "NO"); //Not Offerrer
        console.log("token Amount", tokenAmount);
        require(
            offerredAmounts[_offerNumber].fractionAcquired >=
                (tokenAmount * 51) / 100,
            "NE"
        ); //Not Eligible
        NFTSold = true;
        _transfer(msg.sender, address(this), balanceOf(msg.sender));
        IERC721Upgradeable(token721).safeTransferFrom(
            address(this),
            offerredAmounts[_offerNumber].offerrer,
            tokenID
        );
        finalOfferredAmount = offerredAmounts[_offerNumber].offerred;
    }

    function claimShare() external {
        require(NFTSold == true, "NFT not sold");
        
        uint256 _amount = balanceOf(msg.sender) * finalOfferredAmount;
        _transfer(msg.sender, address(this), balanceOf(msg.sender));
        IUSDT(usdt).transfer(address(this), msg.sender, _amount);
    }

    function excludeFromFee(address _account, bool _toExclude) external {
        require(_account != address(0), "ZA"); //Zero Address
        excludeFee[_account] = _toExclude;
    }

    function claimOfferAmount(uint256 _offerNumber) external {
        uint256 transferAmount = offerredAmounts[_offerNumber]
            .fractionAcquired * offerredAmounts[_offerNumber].offerred;
        IUSDT(usdt).transfer(
            address(this),
            offerredAmounts[_offerNumber].offerrer,
            transferAmount
        );
    }
}
