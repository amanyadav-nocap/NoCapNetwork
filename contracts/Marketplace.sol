//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
// import "Interfaces/IVaultfactory.sol";
import "Interfaces/IVault.sol";
import "Interfaces/IUSDT.sol";

contract Marketplace is EIP712Upgradeable {
    address owner;
    address usdt;

    struct fractionSeller {
        address seller;
        address fractionVault;
        uint256 fractionSellAmount;
        uint256 fractionPrice;
        uint256 counter;
        bytes signature;
    }
    struct fractionBuyer {
        address buyer;
        address fractionVault;
        uint256 fractionBuyAmount;
        uint256 pricePaid;
        bytes signature;
    }
    struct NFTSeller {
        address nftAddress;
        address owner;
        uint256 tokenID;
        uint256 NFTPrice;
        bytes signature;
    }
    mapping(uint256 => bool) public usedCounters;
    mapping(uint256 => uint256) public amountLeft;

    function initialize(address _owner, address _usdt) external initializer {
        require(_owner != address(0), "ZA"); //Zero Address
        __EIP712_init("Chroncept_MarketItem", "1");
        owner = _owner;
        usdt = _usdt;
    }

    function hashNFTSeller(NFTSeller memory seller)
        internal
        
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "address nftAddress,address owner,uint256 tokenID,uint256 NFTPrice"
                        ),
                        seller.nftAddress,
                        seller.owner,
                        seller.tokenID,
                        seller.NFTPrice
                    )
                )
            );
    }

    function verifyNFTSeller(NFTSeller memory seller)
        internal
        view
        returns (address)
    {
        bytes32 digest = hashNFTSeller(seller);
        return ECDSAUpgradeable.recover(digest, seller.signature);
    }

    function hashFractionSeller(fractionSeller memory seller)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "address seller,address fractionVault,uint256 fractionSellAmount,uint256 fractionPrice,uint256 counter"
                        ),
                        seller.seller,
                        seller.fractionVault,
                        seller.fractionSellAmount,
                        seller.fractionPrice,
                        seller.counter
                    )
                )
            );
    }

    function verifyFractionSeller(fractionSeller memory seller)
        internal
        view
        returns (address)
    {
        bytes32 digest = hashFractionSeller(seller);
        return ECDSAUpgradeable.recover(digest, seller.signature);
    }

    function hashFractionBuyer(fractionBuyer memory buyer)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "address buyer,address fractionVault,uint256 fractionBuyAmount,uint256 pricePaid"
                        ),
                        buyer.buyer,
                        buyer.fractionVault,
                        buyer.fractionBuyAmount,
                        buyer.pricePaid
                    )
                )
            );
    }

    function verifyFractionBuyer(fractionBuyer memory buyer)
        internal
        view
        returns (address)
    {
        bytes32 digest = hashFractionBuyer(buyer);
        return ECDSAUpgradeable.recover(digest, buyer.signature);
    }

    function buyNFT(NFTSeller memory seller) external {
        address signer = verifyNFTSeller(seller);
        require(
            signer ==
                IERC721Upgradeable(seller.nftAddress).ownerOf(seller.tokenID),
            "IS"
        ); //Invalid Signer
        IUSDT(usdt).transferFrom(msg.sender, seller.owner, seller.NFTPrice);
        IERC721Upgradeable(seller.nftAddress).safeTransferFrom(
            seller.owner,
            msg.sender,
            seller.tokenID
        );
    }

    function fractionTrade(
        fractionBuyer memory buyer,
        fractionSeller memory seller
    ) external {
        require(seller.fractionVault == buyer.fractionVault, "IV"); // Invalid Vault
        require(
            buyer.pricePaid >= buyer.fractionBuyAmount * seller.fractionPrice,
            "IP"
        ); //Invalid Price
        address sellerSigner = verifyFractionSeller(seller);
        address buyerSigner = verifyFractionBuyer(buyer);
        require(sellerSigner == seller.seller, "SI"); //Seller Invalid
        require(buyerSigner == buyer.buyer, "BI"); //Buyer Invalid

        setCounter(buyer, seller);
        IUSDT(usdt).transferFrom(
            buyer.buyer,
            seller.seller,
            buyer.fractionBuyAmount * seller.fractionPrice
        );
        IVault(seller.fractionVault)._transfer(
            seller.seller,
            buyer.buyer,
            buyer.fractionBuyAmount
        );
    }

    function setCounter(
        fractionBuyer memory buyer,
        fractionSeller memory seller
    ) internal {
        //Counter used
        require(!usedCounters[seller.counter], "CU");
        uint256 leftCounter = amountLeft[seller.counter];
        if (leftCounter == 0) {
            leftCounter = seller.fractionSellAmount - buyer.fractionBuyAmount;
        } else {
            leftCounter = leftCounter - buyer.fractionBuyAmount;
        }
        require(leftCounter >= 0, "ALZ"); //Amount left less than zero

        amountLeft[seller.counter] = leftCounter;
        if (leftCounter == 0) usedCounters[seller.counter] = true;
    }
}
