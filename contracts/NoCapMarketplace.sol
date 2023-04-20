// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/INoCapTemplate.sol";
import "./Library/Voucher.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NoCapMarketplace is Ownable, Initializable, EIP712Upgradeable, ReentrancyGuardUpgradeable {

    
    address public admin;

    uint96 public platformFeePercent; // in BP 10000.

    address NFTContract;

    address tether;

    struct FractionsLeft{
        uint256 totalFractions;
        uint256 fractionsLeft;
    }

    struct PerSale{
    address collectionAddress;
    address seller;
    uint tokenId;
    uint fractions;
    uint amount;
    uint sellerShare;
    address currency;
    bool refundIssued;
    }

    struct SaleReceipt {
    uint totalTransactions;
    mapping(uint=>PerSale) receiptPerTransaction;
    }

    struct SellerReceipt {
        address currencyAddress;
        uint amount;
    }

    mapping(address => mapping (uint256 => bool) ) public nftMinted;

    mapping(address => mapping(uint256 => FractionsLeft)) public fractionsNFT;

    mapping(address => bool) public allowedCurrencies;

    mapping(address=>SaleReceipt) public SaleReceiptForBuyer;

    mapping(address=>mapping(address=>mapping(uint=>SellerReceipt))) public SellerAmounts;

    mapping(address=>mapping(uint=>bool)) public refundEnabled;

    mapping(address => uint) public platformCollection;

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
        address _currency) external payable nonReentrant returns(address){
        
        address sellerAddress = verifyVoucher(voucher);

        require(sellerAddress==voucher.seller,"Invalid seller.");
        if(isPrimary) {
            uint platformAmount = (platformFeePercent*voucher.pricePerFraction*voucher.fractions)/10000;
            uint totalAmount = platformAmount+(voucher.pricePerFraction)*voucher.fractions;
            
            if(_currency==address(1)){
                require(msg.value == totalAmount,"Invalid amount.");
                // (bool sentAmount,) = payable(voucher.seller).call{value:(voucher.pricePerFraction)*voucher.fractions}("");
                // require(sentAmount,"Amount transfer failed.");
                saleTransaction(voucher.NFTAddress, voucher.seller, voucher.tokenId,voucher.fractions, msg.value, (voucher.pricePerFraction)*voucher.fractions, _currency);

            } else{
                require(allowedCurrencies[_currency],"Currency not allowed.");
                IERC20(_currency).transferFrom(msg.sender, address(this), totalAmount);
                saleTransaction(voucher.NFTAddress,voucher.seller,voucher.tokenId,voucher.fractions,totalAmount,(voucher.pricePerFraction)*voucher.fractions, _currency);
                // IERC20(_currency).transferFrom(msg.sender, voucher.seller, (voucher.pricePerFraction)*voucher.fractions);

            }
            address STO = INoCapTemplate(voucher.NFTAddress).MintNft(msg.sender, voucher.tokenId, voucher.tokenURI,voucher.seller,voucher.maxFractions, voucher.fractions, voucher.royaltyFees);
            platformCollection[_currency]+= platformAmount;
            if(fractionsNFT[voucher.NFTAddress][voucher.tokenId].totalFractions==0){ 
            fractionsNFT[voucher.NFTAddress][voucher.tokenId].totalFractions= voucher.maxFractions;
            fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft = voucher.maxFractions - voucher.fractions;}
            else{
            fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft -= voucher.fractions;
            }
            return STO;
                        //emit event for nft creation
        }
        else{
            require(INoCapTemplate(voucher.NFTAddress).checkExist(voucher.tokenId),"NFT does not exist.");
            require(fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft==0,"Sale not allowed until all fractions are issued.");
            uint platformAmount = (platformFeePercent*voucher.pricePerFraction*voucher.fractions)/10000;
            (address receiver, uint royaltyAmount) = INoCapTemplate(voucher.NFTAddress).royaltyInfo(voucher.tokenId, voucher.pricePerFraction);
            uint totalAmount = platformAmount+((voucher.pricePerFraction)*voucher.fractions)+royaltyAmount;
            if(_currency==address(1)) {
                require(msg.value == totalAmount,"Invalid amount.");
                (bool sentToSeller,) = payable(voucher.seller).call{value: voucher.pricePerFraction}("");
                platformCollection[_currency] += platformAmount;
                (bool royaltySent,) = payable(receiver).call{value: royaltyAmount}("");
                require(sentToSeller && royaltySent,"Ether transfer failed.");
            } else {
                require(allowedCurrencies[_currency],"Invalid currency");
                IERC20(_currency).transferFrom(msg.sender, voucher.seller, voucher.pricePerFraction);
                IERC20(_currency).transferFrom(msg.sender, address(this), platformAmount);
                platformCollection[_currency] += platformAmount;
                IERC20(_currency).transferFrom(msg.sender, receiver, royaltyAmount);
            }
                IERC20(INoCapTemplate(voucher.NFTAddress).getSTOForTokenId(voucher.tokenId)).transferFrom(voucher.seller,msg.sender,voucher.fractions);
                
            }
    }

    function enableRefundForSale(address _collectionAddress, uint _tokenId) external onlyAdmin{
         refundEnabled[_collectionAddress][_tokenId]=true;
    }

    function setPlatformFeePercent(uint96 _newPlatformFee) external onlyAdmin{
        platformFeePercent = _newPlatformFee;
    }

    function setAdmin(address _newAdmin) external onlyAdmin{
        admin  = _newAdmin;
    }

    function saleTransaction(address _collection, address _seller, uint _tokenId, uint _fractions, uint _totalAmount, uint _sellerAmount, address _currencyAddress) internal {
        SaleReceipt storage saleReceipt = SaleReceiptForBuyer[msg.sender];
        SellerAmounts[_seller][_collection][_tokenId].currencyAddress = _currencyAddress;
        SellerAmounts[_seller][_collection][_tokenId].amount += _sellerAmount;
        saleReceipt.totalTransactions++;
        PerSale storage perSale = saleReceipt.receiptPerTransaction[saleReceipt.totalTransactions];
        perSale.collectionAddress = _collection;
        perSale.amount = _totalAmount;
        perSale.seller = _seller;
        perSale.tokenId = _tokenId;
        perSale.fractions = _fractions;
        perSale.currency = _currencyAddress;
        perSale.sellerShare = _sellerAmount;
    }
 
    function getRefund(uint _transactionId) external nonReentrant returns(bool) {
        SaleReceipt storage saleReceipt = SaleReceiptForBuyer[msg.sender];
        address collection = saleReceipt.receiptPerTransaction[_transactionId].collectionAddress;
        uint tokenID = saleReceipt.receiptPerTransaction[_transactionId].tokenId;
        uint amount = saleReceipt.receiptPerTransaction[_transactionId].amount;
        address currency = saleReceipt.receiptPerTransaction[_transactionId].currency;
       
        require(!saleReceipt.receiptPerTransaction[_transactionId].refundIssued,"Refund already issued for this transaction.");
        require(refundEnabled[collection][tokenID],"Refund is not enable on this sale.");
        SellerAmounts[saleReceipt.receiptPerTransaction[_transactionId].seller][collection][tokenID].amount-=saleReceipt.receiptPerTransaction[_transactionId].sellerShare;
        saleReceipt.receiptPerTransaction[_transactionId].refundIssued = true;
        if(currency==address(1)) {
            (bool sent,) = payable(msg.sender).call{value:amount}("");
            require(sent);
            return sent; 
        }
        else {
            (bool sent) = IERC20(currency).transfer(msg.sender,amount);
            return sent;
        }
        
    }

    function viewSaleReceipt(address _address, uint _transactionNo) external view returns(PerSale memory) {
        return SaleReceiptForBuyer[_address].receiptPerTransaction[_transactionNo];
    }

    function withdrawSellerAmount(address _collectionAddress, uint256 _tokenId) external nonReentrant{
        require(fractionsNFT[_collectionAddress][_tokenId].fractionsLeft==0,"Sale of all fractions is still pending!");
        require(!refundEnabled[_collectionAddress][_tokenId], "Refund has been issued on this tokenId.");
        uint amount = SellerAmounts[msg.sender][_collectionAddress][_tokenId].amount;
        address currency = SellerAmounts[msg.sender][_collectionAddress][_tokenId].currencyAddress;
        require(currency!=address(0),"ZA");
        if(currency==address(1)) {
            (bool sent,) = msg.sender.call{value:amount}("");
            require(sent);
        }
        else{
            IERC20(currency).transfer(msg.sender,amount);
        }
    }

    function viewSellerAmounts(address _seller, address _collectionAddress, uint _tokenId) external view returns(uint, address) {
        return (SellerAmounts[_seller][_collectionAddress][_tokenId].amount,SellerAmounts[_seller][_collectionAddress][_tokenId].currencyAddress);
    }

    

    




}