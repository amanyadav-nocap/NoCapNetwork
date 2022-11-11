// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IVaultfactory.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ChronNFT is ERC721URIStorageUpgradeable, Ownable {
    address private vaultFactory;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _vaultfactory
    ) external initializer {
        require(_vaultfactory != address(0), "ZA"); //Zero Address
        __ERC721_init_unchained(_name, _symbol);
        vaultFactory = _vaultfactory;
    }

    function safeMint(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 _tokenId,
        uint256 _fractionSupply,
        uint256 _fractionPrice,
        address _usdt,
        address _admin,
        address _taxWallet,
        address _marketFeeWallet
    ) external {
        address vault = IVaultfactory(vaultFactory).createVault(
            name,
            symbol,
            _fractionSupply,
            address(this),
            _tokenId,
            _fractionPrice,
            _usdt,
            _admin,
            _taxWallet,
            _marketFeeWallet
        );
        _safeMint(vault, _tokenId);
        _setTokenURI(_tokenId, uri);
    }

    function burn(uint256 _tokenId) external onlyOwner {
        require(_exists(_tokenId));
        _burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, Context)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, Context)
        returns (bytes calldata)
    {
        return msg.data;
    }
}
