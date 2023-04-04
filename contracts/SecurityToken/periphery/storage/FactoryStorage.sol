//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract FactoryStorage {

    address public identityRegistryImpl;
    address public claimTopicsRegistryImpl;
    address public trustedIssuersRegistryImpl;
    address public identityRegistryStorageImpl;
    address public complianceImpl;
    address public implAuthorithyToken;
    address public implAuthorithyIdentity;
    address public implAuthorityAdminIdentity;
    address public implAuthorityIssuerIdentity;

    address[] public tokens;
    address[] public claimIssuerIdentities;
    address[] public userIdentities;
    mapping(address => uint256) public userIdentityId;
    mapping(address => uint256) public claimIssuerIdentityId;   
    mapping(address => uint256) public tokenId;
    mapping(address => address) public adminIdentityMinter;

    bytes32 public constant Operator_Role = keccak256("Operator_Role");
    bytes32 public constant Minter_Role = keccak256("Minter_Role");

    bytes32 salt;

    event tokenCreated(address _tokenProxy, address _tokenImpl, address identityRegistry,
     string mappingValue, uint timestamp);
    event whiteListed(address _userAddress);
    event identityCreated(address _userAddress, address _identityContract);
}