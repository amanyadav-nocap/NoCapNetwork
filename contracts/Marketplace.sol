//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "Interfaces/IVaultfactory.sol";
import "Interfaces/IVault.sol";
import "Interfaces/IUSDT.sol";

contract Marketplace is EIP712Upgradeable {
    address owner;
    address usdt;

    struct ChronceptSeller {
        address nftAddress;
        address owner;
        uint256 tokenID;
        uint256 NFTPrice;
        bytes signature;
    }

    function initialize(address _owner, address _usdt) external initializer {
        require(_owner != address(0), "ZA"); //Zero Address
        __EIP712_init("Chroncept_MarketItem", "1");
        owner = _owner;
        usdt = _usdt;
    }

    function hashSeller(ChronceptSeller memory seller)
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

    function verifySeller(ChronceptSeller memory seller)
        internal
        view
        returns (address)
    {
        bytes32 digest = hashSeller(seller);
        return ECDSAUpgradeable.recover(digest, seller.signature);
    }

    function buy(ChronceptSeller memory seller) external {
        address signer = verifySeller(seller);
        require(signer == seller.owner, "IS"); //Invalid Signer
        // IUSDT(usdt)._transferFrom(msg.sender, to, amount);
        IUSDT(usdt)._transferFrom(msg.sender, seller.owner, seller.NFTPrice);
        IERC721Upgradeable(seller.nftAddress).safeTransferFrom(
            seller.owner,
            msg.sender,
            seller.tokenID
        );
    }


}
