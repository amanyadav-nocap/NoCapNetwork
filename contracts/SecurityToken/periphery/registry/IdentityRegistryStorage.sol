// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "contracts/SecurityToken/interface/IIdentity.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../roles/AgentRole.sol";
import "contracts/SecurityToken/interface/IIdentityRegistryStorage.sol";

contract IdentityRegistryStorage is IIdentityRegistryStorage, AgentRole, Initializable {
    /// @dev struct containing the identity contract and the country of the user
    struct Identity {
        IIdentity identityContract;
        uint16 investorCountry;
    }
    
    /// @dev mapping between a user address and the corresponding identity
    mapping(address => Identity) private identities;

    /// @dev array of Identity Registries linked to this storage
    address[] private identityRegistries;

    function init() public initializer {
        _transferOwnership(msg.sender);
        addSubAdmin(msg.sender);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-linkedIdentityRegistries}.
     */
    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return identityRegistries;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedIdentity}.
     */
    function storedIdentity(address _userAddress) external view override returns (IIdentity) {
        return identities[_userAddress].identityContract;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedInvestorCountry}.
     */
    function storedInvestorCountry(address _userAddress) external view override returns (uint16) {
        return identities[_userAddress].investorCountry;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-addIdentityToStorage}.
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external override onlyAgent {
        require(address(_identity) != address(0), "contract address can\"t be a zero address");
        require(address(identities[_userAddress].identityContract) == address(0), "identity contract already exists, please use update");
        identities[_userAddress].identityContract = _identity;
        identities[_userAddress].investorCountry = _country;
        emit IdentityStored(_userAddress, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredIdentity}.
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), "this user has no identity registered");
        require(address(_identity) != address(0), "contract address can\"t be a zero address");
        IIdentity oldIdentity = identities[_userAddress].identityContract;
        identities[_userAddress].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredInvestorCountry}.
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), "this user has no identity registered");
        identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-removeIdentityFromStorage}.
     */
    function removeIdentityFromStorage(address _userAddress) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), "you haven\"t registered an identity yet");
        delete identities[_userAddress];
        emit IdentityUnstored(_userAddress, identities[_userAddress].identityContract);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-transferOwnershipOnIdentityRegistryStorage}.
     */
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-bindIdentityRegistry}.
     */
    function bindIdentityRegistry(address _identityRegistry) external override {
        addAgent(_identityRegistry);
        identityRegistries.push(_identityRegistry);
        emit IdentityRegistryBound(_identityRegistry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-unbindIdentityRegistry}.
     */
    function unbindIdentityRegistry(address _identityRegistry) external override {
        require(identityRegistries.length > 0, "identity registry is not stored");
        uint256 length = identityRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (identityRegistries[i] == _identityRegistry) {
                identityRegistries[i] = identityRegistries[length - 1];
                identityRegistries.pop();
                break;
            }
        }
        removeAgent(_identityRegistry);
        emit IdentityRegistryUnbound(_identityRegistry);
    }
}
