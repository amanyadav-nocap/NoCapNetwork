//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "Interfaces/IVaultfactory.sol";
import "Interfaces/IVault.sol";

contract Marketplace is EIP712Upgradeable
{
    address owner;
    address NFTAddress;

    struct ChronceptSeller {
        address nftAddress;
        address owner;
        uint256 tokenID;
        uint256 fractionAmount;
        uint256 fractionPrice;
        bytes signature;
    }

    function initialize(address _owner, address _token) external initializer {
        require(_owner != address(0), "ZA"); //Zero Address
        require(_token != address(0), "ZA"); //Zero Address
        __EIP712_init("Chroncept_MarketItem", "1");
        owner = _owner;
        NFTAddress = _token;
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
                            "address nftAddress,address owner,uint256 tokenID,uint256 fractionAmount,uint256 fractionPrice"
                        ),
                        seller.nftAddress,
                        seller.owner,
                        seller.tokenID,
                        seller.fractionAmount,
                        seller.fractionPrice
                    )
                )
            );
    }

    function verifySeller(ChronceptSeller memory seller) internal view returns(address){
        bytes32 digest = hashSeller(seller);
        return ECDSAUpgradeable.recover(digest, seller.signature);
    }


}
