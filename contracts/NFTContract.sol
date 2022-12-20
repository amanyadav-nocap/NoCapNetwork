// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract ChronNFT is ERC1155URIStorageUpgradeable, ERC2981Upgradeable, Ownable {
    address usdt;
    struct singleOffer {
        address offeredTo;
        uint256 offeredAmount;
        uint256 offeredFor;
    }
    struct offer {
        uint256 _globalOfferNo;
        uint256 _singleOfferNo;
        mapping(uint256 => uint256) globalOffers;
        mapping(uint256 => singleOffer) singleOffers;
    }
    struct tokenDetails {
        uint256 supply;
        uint256 price;
    }
    mapping(uint256 => mapping(address => offer)) public Offers;
    mapping(address => bool) internal operators;
    mapping(uint256 => tokenDetails) public tokenDet;

    function initialize(
        string memory _uri,
        address _admin,
        uint96 _defaultRoyalty,
        address _usdt
    ) external initializer {
        __ERC1155_init_unchained(_uri);
        __ERC2981_init_unchained();
        _setDefaultRoyalty(_admin, _defaultRoyalty);
        operators[_admin] = true;
        usdt = _usdt;
    }

    function makeGlobalOffer(uint256 _tokenId, uint256 _offeredPrice) external {
        require(_offeredPrice > tokenDet[_tokenId].price, "PL"); //Price too low
        IERC20Upgradeable(usdt).transferFrom(
            msg.sender,
            address(this),
            _offeredPrice * tokenDet[_tokenId].supply
        );
        offer storage offered = Offers[_tokenId][msg.sender];
        offered._globalOfferNo++;
        offered.globalOffers[
            Offers[_tokenId][msg.sender]._globalOfferNo
        ] = _offeredPrice;
    }

    function makeSingleOffer(
        uint256 _tokenId,
        address _account,
        uint256 _amount,
        uint256 _offeredPrice
    ) external {
        require(_offeredPrice > tokenDet[_tokenId].price, "PL"); //Price too low
        IERC20Upgradeable(usdt).transferFrom(
            msg.sender,
            address(this),
            _offeredPrice * _amount
        );
        offer storage offered = Offers[_tokenId][msg.sender];
        offered._singleOfferNo++;
        offered
            .singleOffers[Offers[_tokenId][msg.sender]._singleOfferNo]
            .offeredTo = _account;
        offered
            .singleOffers[Offers[_tokenId][msg.sender]._singleOfferNo]
            .offeredAmount = _offeredPrice;
        offered
            .singleOffers[Offers[_tokenId][msg.sender]._singleOfferNo]
            .offeredFor = _amount;
    }

    function upgradeOffer(
        uint256 _tokenId,
        uint256 _globalOfferNo,
        uint256 _singleOfferNo,
        uint256 _newOfferedPrice,
        bool _isGlobal
    ) external {
        if (_isGlobal) {
            Offers[_tokenId][msg.sender].globalOffers[
                _globalOfferNo
            ] = _newOfferedPrice;
        } else {
            Offers[_tokenId][msg.sender]
                .singleOffers[_singleOfferNo]
                .offeredAmount = _newOfferedPrice;
        }
    }

    function transferFractions(
        address _offerer,
        uint256 _tokenId,
        uint256 _globalOfferNo,
        uint256 _singleOfferNo,
        bool _isGlobal
    ) external {
        if (_isGlobal) {
            uint256 price = Offers[_tokenId][_offerer].globalOffers[
                _globalOfferNo
            ];
            uint256 transferAmount = balanceOf(msg.sender, _tokenId);
            IERC20Upgradeable(usdt).transfer(
                msg.sender,
                price * transferAmount
            );
            _safeTransferFrom(
                msg.sender,
                _offerer,
                _tokenId,
                transferAmount,
                ""
            );
        } else {
            uint256 price = Offers[_tokenId][_offerer]
                .singleOffers[_singleOfferNo]
                .offeredAmount;
            uint256 transferAmount = Offers[_tokenId][_offerer]
                .singleOffers[_singleOfferNo]
                .offeredFor;
            IERC20Upgradeable(usdt).transfer(
                msg.sender,
                price * transferAmount
            );
            _safeTransferFrom(
                msg.sender,
                _offerer,
                _tokenId,
                transferAmount,
                ""
            );
        }
    }

    function MintNFT(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        string memory _uri,
        address _royaltyKeeper,
        uint96 _royalty
    ) external {
        _mint(_to, _tokenId, _amount, "");
        _setURI(_tokenId, _uri);
        _setTokenRoyalty(_tokenId, _royaltyKeeper, _royalty);
        tokenDet[_tokenId].supply = _amount;
        tokenDet[_tokenId].price = _price;
    }

    function setRoyalty(
        uint256 _tokenId,
        address _royaltyKeeper,
        uint96 _royalty
    ) external {
        _setTokenRoyalty(_tokenId, _royaltyKeeper, _royalty);
    }

    function addOperator(address _account, bool _status) external {
        require(_account != address(0), "ZA"); //Zero Addresss
        operators[_account] = _status;
    }

    function burn(
        address _account,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        // require(_exists(_tokenId));
        _burn(_account, _tokenId, _amount);
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return super.uri(tokenId);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
