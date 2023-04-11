//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interfaces/INoCapTemplate.sol";


contract NoCapFactory is Initializable, OwnableUpgradeable {

    address templateAddress;
    address admin;
    address marketPlace;
    address securityTokenFactory;

    struct Collection {
       uint totalCollections;
       mapping(uint => address) collectionAddress; // Address of every collection i.e. totalCollection(Number) => address.
    }

    mapping(address => Collection) public collections;

    mapping(address=>bool) public isNoCapNFT;

    event NFTCreated(uint _collectionNumber, address _NFT, address _creator);

    modifier onlyAdmin{
        require(msg.sender==admin, "You are not the admin.");
        _;
    }

    function initialize(address _templateAddress, address _admin, address _marketPlace,  address _securityTokenFactory) external initializer{
        require(_templateAddress!= address(0),"Zero address.");
        require(_admin!= address(0),"Zero address.");
        require(_marketPlace!= address(0),"Zero address.");
        templateAddress = _templateAddress;
        admin = _admin;
        marketPlace = _marketPlace;
        securityTokenFactory = _securityTokenFactory;
    }

    function deployNFTCollection(string memory _name, string memory _symbol, address _creator, uint96 _royalty) external returns(address){
        
        require(_creator!=address(0),"Zero address.");
        Collection storage col = collections[msg.sender];
        col.totalCollections++;
        bytes32 salt = keccak256(abi.encodePacked(col.totalCollections,_creator));
        address NFT = ClonesUpgradeable.cloneDeterministic(templateAddress, salt);
        col.collectionAddress[col.totalCollections] = NFT;
        INoCapTemplate(NFT).initialize(_name, _symbol, _creator, _royalty, marketPlace, securityTokenFactory);
        emit NFTCreated(col.totalCollections, NFT, _creator);
        isNoCapNFT[NFT] = true;
        return NFT;
    }

    function updateTemplateAddress(address _newTemplate) external onlyAdmin {
        require(_newTemplate!=address(0),"Zero address.");
        templateAddress = _newTemplate;
    }

    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    function getCollectionAddress(address owner, uint collectionNumber) external view returns(address) {
        return collections[owner].collectionAddress[collectionNumber];
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        pure
        override(ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    function checkNoCapNFT(address _NFT) external view returns(bool) {
        return isNoCapNFT[_NFT];
    }

}