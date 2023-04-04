// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/INoCapTemplate.sol";
import "./Library/Voucher.sol";


contract NoCapMarketplace is Ownable, Initializable, EIP712Upgradeable {

    
    address public admin;

    uint96 public platformFeePercent; // in BP 10000.

    address NFTContract;

    address tether;

    struct FractionsLeft{
        uint256 totalFractions;
        uint256 fractionsLeft;
    }

    mapping(address => mapping (uint256 => bool) ) public nftMinted;

    mapping(address => mapping(uint256 => FractionsLeft)) public fractionsNFT;

    mapping(address => bool) public allowedCurrencies;

    modifier onlyAdmin() {
        require(msg.sender == admin,"You are not the admin.");
        _;
    }

    function initialize(address _admin, address _NFT, uint96 _platformFeePercent, address _tether) external initializer {
        require(_admin!=address(0),"Zero address.");
        require(_NFT!=address(0),"Zero address");
        require(_tether!=address(0),"Zero address");
        __EIP712_init_unchained("NoCap_MarketItem", "1");
        admin = _admin;
        NFTContract = _NFT;
        platformFeePercent = _platformFeePercent;
        tether = _tether;
        allowedCurrencies[tether] = true;
    }

    function hashVoucher(Voucher.NFTVoucher memory voucher) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("NFTVoucher(address seller,address NFTAddress,uint256 tokenId,uint256 maxFractions,uint256 fractions,uint256 pricePerFraction,bool toMint,address royaltyKeeper,uint96 royaltyFees,string tokenURI)"),
        voucher.seller,
        voucher.NFTAddress,
        voucher.tokenId,
        voucher.maxFractions,
        voucher.fractions,
        voucher.pricePerFraction,
        voucher.toMint,
        voucher.royaltyKeeper,
        voucher.royaltyFees,
        keccak256(bytes(voucher.tokenURI))
        )));
    }

    function verifyVoucher(Voucher.NFTVoucher memory voucher) public view returns(address) {
        bytes32 digest = hashVoucher(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function voucherOwner(Voucher.NFTVoucher memory voucher) public pure returns(address){
        return voucher.seller;
    }

    function buyNFT(Voucher.NFTVoucher memory voucher,
        bool isPrimary,
        address currency) external payable {
        
        address sellerAddress = verifyVoucher(voucher);

        require(sellerAddress==voucher.seller,"Invalid Seller");
        if(isPrimary) {
            require(sellerAddress==admin,"Not admin.");
            uint platformAmount = (platformFeePercent*voucher.pricePerFraction*voucher.fractions)/10000;
            uint totalAmount = platformAmount+(voucher.pricePerFraction)*voucher.fractions;
            
            if(currency==address(1)){
                require(msg.value == totalAmount,"Invalid amount.");
                (bool sentAmount,) = payable(voucher.seller).call{value:(voucher.pricePerFraction)*voucher.fractions}("");
                require(sentAmount,"Amount transfer failed.");
            } else{
                require(allowedCurrencies[currency],"Currency not allowed.");
                IERC20(currency).transferFrom(msg.sender, address(this), platformAmount);
                IERC20(currency).transferFrom(msg.sender, voucher.seller, (voucher.pricePerFraction)*voucher.fractions);
            }
            INoCapTemplate(voucher.NFTAddress).MintNft(msg.sender, voucher.tokenId, voucher.tokenURI,voucher.seller,voucher.maxFractions, voucher.fractions, voucher.royaltyFees);
            fractionsNFT[voucher.NFTAddress][voucher.tokenId].totalFractions = voucher.maxFractions;
            fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft = voucher.maxFractions - voucher.fractions;
                        //emit event for nft creation
        }
        else{
            require(INoCapTemplate(voucher.NFTAddress).checkExist(voucher.tokenId),"NFT does not exist.");
            uint platformAmount = (platformFeePercent*voucher.pricePerFraction)/10000;
            (address receiver, uint royaltyAmount) = INoCapTemplate(voucher.NFTAddress).royaltyInfo(voucher.tokenId, voucher.pricePerFraction);
            uint totalAmount = platformAmount+voucher.pricePerFraction+royaltyAmount;
            if(currency==address(1)) {
                require(msg.value == totalAmount,"Invalid amount.");
                (bool sentToSeller,) = payable(voucher.seller).call{value: voucher.pricePerFraction}("");
                (bool sentToAdmin,) = payable(admin).call{value: platformAmount}("");
                (bool royaltySent,) = payable(receiver).call{value: royaltyAmount}("");
                require(sentToSeller && sentToAdmin && royaltySent,"Ether transfer failed.");
            } else {
                require(allowedCurrencies[currency],"Invalid currency");
                IERC20(currency).transferFrom(msg.sender, voucher.seller, voucher.pricePerFraction);
                IERC20(currency).transferFrom(msg.sender, admin, platformAmount);
                IERC20(currency).transferFrom(msg.sender, receiver, royaltyAmount);
            }
                IERC20(INoCapTemplate(voucher.NFTAddress).getSTOForTokenId(voucher.tokenId)).transferFrom(voucher.seller,msg.sender,voucher.fractions);
                
            }
    }

    function setPlatformFeePercent(uint96 _newPlatformFee) external {
        platformFeePercent = _newPlatformFee;
    }

    function setAdmin(address _newAdmin) external {
        admin  = _newAdmin;
    }

    




}