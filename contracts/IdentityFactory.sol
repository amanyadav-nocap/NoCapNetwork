// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/Interfaces/IIdentity.sol";

contract IdentityFactory is Initializable{

    address identityTemplate;
    address identityRegistry;
    uint totalIdentitiesDeployed;

    mapping(address=>address) public identityAddress;

    function init(address _identityTemplate, address _identityRegistry) external initializer {
        identityTemplate = _identityTemplate;
        identityRegistry = _identityRegistry;
    }

    function createAndRegisterIdentity() external {
        totalIdentitiesDeployed++;
        bytes32 salt = keccak256(abi.encodePacked(totalIdentitiesDeployed, msg.sender, identityTemplate));
        address identity = ClonesUpgradeable.cloneDeterministic(identityTemplate, salt);
        identityAddress[msg.sender] = identity;
        
    }




}