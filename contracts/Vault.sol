// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";
import "./Interfaces/IUSDT.sol";

contract vault is ERC20Upgradeable, ERC721HolderUpgradeable {
    address public admin;
    address public taxWallet;
    address public marketFeeWallet;
    IUSDT public usdt;
    address public token721;
    uint256 public fractionPrice;
    uint256 public tokenID;
    uint256 public fractionSupply;
    uint256 private tokenAmount;
    uint256 public offerNumber;
    uint256 public finalOfferredAmount;
    bool primaryBuyEnd;
    bool NFTSold;

    struct offer {
        address offerrer;
        uint256 offerred;
        uint256 fractionAcquired;
    }
    mapping(uint256 => offer) private offerredAmounts;
    mapping(address => bool) private excludeFee;
    modifier onlyAdmin() {
        require(msg.sender == admin, "NA"); //Not Admin
        _;
    }

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
        // __Ownable_init();
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
    }

    function buyFractions(uint256 _fractionAmount) external {
        require(!primaryBuyEnd, "AFS"); //All Fractions Sold
        require(fractionSupply >= _fractionAmount, "NES"); //Not Enough Supply
        uint256 amount = _fractionAmount * fractionPrice;
        IUSDT(usdt).transferFrom(
            msg.sender,
            marketFeeWallet,
            (amount * 1) / 100
        );
        IUSDT(usdt).transferFrom(
            msg.sender,
            admin,
            (amount - ((amount * 1) / 100))
        );
        _transfer(address(this), msg.sender, _fractionAmount);
        tokenAmount = tokenAmount + balanceOf(msg.sender);
        fractionSupply = fractionSupply - _fractionAmount;
        if (fractionSupply == 0) primaryBuyEnd = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        require(to != address(0), "ZA"); //zero address
        if (excludeFee[from] || excludeFee[to]) {
            super._transfer(from, to, amount);
        } else {
            uint256 amountTransferred = amount - ((amount * 25) / 1000);
            super._transfer(from, taxWallet, (amount * 25) / 1000); //TAX amount
            super._transfer(from, to, amountTransferred);
        }
    }

    // for make offer are we taking fraction price of nft price?
    // can multiple people offer same amount?
    function makeOffer(uint256 offerredPrice) external {
        require(primaryBuyEnd, "NAY"); //Not Available Yet
        require(offerredPrice > fractionPrice, "PL"); //Price too low
        require(!NFTSold, "BO"); //Buyout Over
        IUSDT(usdt).transferFrom(
            msg.sender,
            address(this),
            offerredPrice * totalSupply()
        );
        offerredAmounts[offerNumber].offerrer = msg.sender;
        offerredAmounts[offerNumber].offerred = offerredPrice;
        offerNumber++;
    }

    function sellFraction(uint256 _offerNumber, uint256 _amount) external {
        require(!NFTSold, "NAS"); //NFT already sold
        require(balanceOf(msg.sender) != 0, "AV"); //Already Voted
        require(msg.sender != offerredAmounts[_offerNumber].offerrer, "ONA"); //Offerrer not allowed

        offerredAmounts[_offerNumber].fractionAcquired += _amount;

        uint256 payOut = _amount * offerredAmounts[_offerNumber].offerred;
        IUSDT(usdt).transfer(
            address(this),
            marketFeeWallet,
            (payOut * 1) / 100
        ); //Platform Fee
        _transfer(msg.sender, offerredAmounts[_offerNumber].offerrer, _amount);
        IUSDT(usdt).transfer(
            address(this),
            msg.sender,
            (payOut - ((payOut * 1) / 100))
        );
    }

    function claim(uint256 _offerNumber) external {
        require(msg.sender == offerredAmounts[_offerNumber].offerrer, "NO"); //Not Offerrer
        console.log("token Amount", tokenAmount);
        console.log(
            "votes received",
            offerredAmounts[_offerNumber].fractionAcquired
        );
        console.log("margin", (tokenAmount * 51) / 100);

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
        require(NFTSold, "BNO"); //Buyout Not Over
        uint256 _amount = balanceOf(msg.sender) * finalOfferredAmount;
        _transfer(msg.sender, address(this), balanceOf(msg.sender));
        IUSDT(usdt).transfer(address(this), msg.sender, _amount);
    }

    function excludeFromFee(address _account, bool _toExclude)
        external
        onlyAdmin
    {
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
