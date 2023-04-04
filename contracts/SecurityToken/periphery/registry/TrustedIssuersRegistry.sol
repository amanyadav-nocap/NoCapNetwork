// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "contracts/SecurityToken/interface/IClaimIssuer.sol";
import "contracts/SecurityToken/interface/ITrustedIssuersRegistry.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TrustedIssuersRegistry is ITrustedIssuersRegistry, Ownable, Initializable{
    /// @dev Array containing all TrustedIssuers identity contract address.
    IClaimIssuer[] private trustedIssuers;

    /// @dev Mapping between a trusted issuer index and its corresponding claimTopics.
    mapping(address => uint256[]) private trustedIssuerClaimTopics;

    function init() public initializer{
        _transferOwnership(msg.sender);
    }
    /**
     *  @dev See {ITrustedIssuersRegistry-addTrustedIssuer}.
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length == 0, "trusted Issuer already exists");
        require(_claimTopics.length > 0, "trusted claim topics cannot be empty");
        trustedIssuers.push(_trustedIssuer);
        trustedIssuerClaimTopics[address(_trustedIssuer)] = _claimTopics;
        emit TrustedIssuerAdded(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-removeTrustedIssuer}.
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, "trusted Issuer doesn\"t exist");
        uint256 length = trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (trustedIssuers[i] == _trustedIssuer) {
                trustedIssuers[i] = trustedIssuers[length - 1];
                trustedIssuers.pop();
                break;
            }
        }
        delete trustedIssuerClaimTopics[address(_trustedIssuer)];
        emit TrustedIssuerRemoved(_trustedIssuer);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-updateIssuerClaimTopics}.
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, "trusted Issuer doesn\"t exist");
        require(_claimTopics.length > 0, "claim topics cannot be empty");
        trustedIssuerClaimTopics[address(_trustedIssuer)] = _claimTopics;
        emit ClaimTopicsUpdated(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-getTrustedIssuers}.
     */
    function getTrustedIssuers() external view override returns (IClaimIssuer[] memory) {
        return trustedIssuers;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-isTrustedIssuer}.
     */
    function isTrustedIssuer(address _issuer) external view override returns (bool) {
        uint256 length = trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (address(trustedIssuers[i]) == _issuer) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-getTrustedIssuerClaimTopics}.
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view override returns (uint256[] memory) {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, "trusted Issuer doesn\"t exist");
        return trustedIssuerClaimTopics[address(_trustedIssuer)];
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-hasClaimTopic}.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view override returns (bool) {
        uint256 length = trustedIssuerClaimTopics[_issuer].length;
        uint256[] memory claimTopics = trustedIssuerClaimTopics[_issuer];
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-transferOwnershipOnIssuersRegistryContract}.
     */
    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}
