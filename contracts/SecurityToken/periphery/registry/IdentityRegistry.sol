// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "contracts/SecurityToken/interface/IClaimIssuer.sol";
import "contracts/SecurityToken/interface/IIdentity.sol";
import "contracts/SecurityToken/interface/IClaimTopicsRegistry.sol";
import "contracts/SecurityToken/interface/ITrustedIssuersRegistry.sol";
import "contracts/SecurityToken/interface/IIdentityRegistry.sol";
import "../roles/AgentRole.sol";
import "contracts/SecurityToken/interface/IIdentityRegistryStorage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract IdentityRegistry is IIdentityRegistry, AgentRole, Initializable {
    /// @dev Address of the ClaimTopicsRegistry Contract
    IClaimTopicsRegistry private tokenTopicsRegistry;

    /// @dev Address of the TrustedIssuersRegistry Contract
    ITrustedIssuersRegistry private tokenIssuersRegistry;

    /// @dev Address of the IdentityRegistryStorage Contract
    IIdentityRegistryStorage private tokenIdentityStorage;

    /**
     *  @dev the constructor initiates the Identity Registry smart contract
     *  @param _trustedIssuersRegistry the trusted issuers registry linked to the Identity Registry
     *  @param _claimTopicsRegistry the claim topics registry linked to the Identity Registry
     *  @param _identityStorage the identity registry storage linked to the Identity Registry
     *  emits a `ClaimTopicsRegistrySet` event
     *  emits a `TrustedIssuersRegistrySet` event
     *  emits an `IdentityStorageSet` event
     */
    function init(
        address _trustedIssuersRegistry,
        address _claimTopicsRegistry,
        address _identityStorage
    ) external initializer{
        _transferOwnership(msg.sender);
        tokenTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        tokenIssuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        tokenIdentityStorage = IIdentityRegistryStorage(_identityStorage);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
        emit IdentityStorageSet(_identityStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-identity}.
     */
    function identity(address _userAddress) public view override returns (IIdentity) {
        return tokenIdentityStorage.storedIdentity(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistry-investorCountry}.
     */
    function investorCountry(address _userAddress) external view override returns (uint16) {
        return tokenIdentityStorage.storedInvestorCountry(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistry-issuersRegistry}.
     */
    function issuersRegistry() external view override returns (ITrustedIssuersRegistry) {
        return tokenIssuersRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-topicsRegistry}.
     */
    function topicsRegistry() external view override returns (IClaimTopicsRegistry) {
        return tokenTopicsRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-identityStorage}.
     */
    function identityStorage() external view override returns (IIdentityRegistryStorage) {
        return tokenIdentityStorage;
    }

    /**
     *  @dev See {IIdentityRegistry-registerIdentity}.
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) public override onlyAgent {
        tokenIdentityStorage.addIdentityToStorage(_userAddress, _identity, _country);
        emit IdentityRegistered(_userAddress, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-batchRegisterIdentity}.
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            registerIdentity(_userAddresses[i], _identities[i], _countries[i]);
        }
    }

    /**
     *  @dev See {IIdentityRegistry-updateIdentity}.
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        IIdentity oldIdentity = identity(_userAddress);
        tokenIdentityStorage.modifyStoredIdentity(_userAddress, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-updateCountry}.
     */
    function updateCountry(address _userAddress, uint16 _country) external override onlyAgent {
        tokenIdentityStorage.modifyStoredInvestorCountry(_userAddress, _country);
        emit CountryUpdated(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistry-deleteIdentity}.
     */
    function deleteIdentity(address _userAddress) external override onlyAgent {
        tokenIdentityStorage.removeIdentityFromStorage(_userAddress);
        emit IdentityRemoved(_userAddress, identity(_userAddress));
    }

    /**
     *  @dev See {IIdentityRegistry-isVerified}.
     */
    function isVerified(address _userAddress) external view override returns (bool) {
        if (address(identity(_userAddress)) == address(0)) {
            return false;
        }

        uint256[] memory requiredClaimTopics = tokenTopicsRegistry.getClaimTopics();
        if (requiredClaimTopics.length == 0) {
            return true;
        }
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < requiredClaimTopics.length; claimTopic++) {
            bytes32[] memory claimIds = identity(_userAddress).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = identity(_userAddress).getClaim(claimIds[j]);

                try IClaimIssuer(issuer).isClaimValid(identity(_userAddress), requiredClaimTopics[claimTopic], sig,
                data) returns(bool _validity){
                    if (
                        _validity
                        && tokenIssuersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                        && tokenIssuersRegistry.isTrustedIssuer(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!tokenIssuersRegistry.isTrustedIssuer(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!tokenIssuersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    /**
     *  @dev See {IIdentityRegistry-setIdentityRegistryStorage}.
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external override onlyOwner {
        tokenIdentityStorage = IIdentityRegistryStorage(_identityRegistryStorage);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-setClaimTopicsRegistry}.
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external override onlyOwner {
        tokenTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-setTrustedIssuersRegistry}.
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external override onlyOwner {
        tokenIssuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-contains}.
     */
    function contains(address _userAddress) external view override returns (bool) {
        if (address(identity(_userAddress)) == address(0)) {
            return false;
        }
        return true;
    }

    /**
     *  @dev See {IIdentityRegistry-transferOwnershipOnIdentityRegistryContract}.
     */
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    /**
     *  @dev See {IIdentityRegistry-addAgentOnIdentityRegistryContract}.
     */
    function addAgentOnIdentityRegistryContract(address _agent) external override {
        addAgent(_agent);
    }

    /**
     *  @dev See {IIdentityRegistry-removeAgentOnIdentityRegistryContract}.
     */
    function removeAgentOnIdentityRegistryContract(address _agent) external override {
        removeAgent(_agent);
    }

    function isAgentOnIdentityRegistry(address _agent) external view override returns(bool){
        return isAgent(_agent);
    }

    function addSubAdminOnIR(address _userAddress) external override{
        addSubAdmin(_userAddress);
        addAgent(_userAddress);
    }

    function revokeSubAdminOnIR(address _SubAdmin) external override{
        revokeSubAdmin(_SubAdmin);
        removeAgent(_SubAdmin);
    }
}
