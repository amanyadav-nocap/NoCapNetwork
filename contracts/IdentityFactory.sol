// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/SecurityToken/interface/IIdentityRegistry.sol";
import "contracts/Interfaces/Iid.sol";
import "contracts/SecurityToken/interface/IIdentity.sol";

contract IdentityFactory is Initializable{

    address identityTemplate;
    address admin;
    address identityRegistry;
    uint totalIdentitiesDeployed;

    mapping(address=>address) public identityAddress;

    modifier onlyAdmin() {
        require(msg.sender==admin);
        _;
    }

    function init(address _identityTemplate, address _identityRegistry, address _admin) external initializer {
        identityTemplate = _identityTemplate;
        identityRegistry = _identityRegistry;
    }

    function createAndRegisterIdentity(uint16 _countryCode) external returns(address){
        totalIdentitiesDeployed++;
        bytes32 salt = keccak256(abi.encodePacked(totalIdentitiesDeployed, msg.sender, identityTemplate, _countryCode));
        address identity = ClonesUpgradeable.cloneDeterministic(identityTemplate, salt);
        identityAddress[msg.sender] = identity;
        IID(identity).init(msg.sender, false);
        IIdentityRegistry(identityRegistry).registerIdentity(msg.sender,IIdentity(identity), _countryCode);
        return identity;    
    }

    function revoleIdentity(address _userAddress) external onlyAdmin {
        IIdentityRegistry(identityRegistry).deleteIdentity(_userAddress);
    }




}