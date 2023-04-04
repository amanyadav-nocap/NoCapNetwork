// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "contracts/SecurityToken/interface/IClaimTopicsRegistry.sol";

contract ClaimTopicsRegistry is IClaimTopicsRegistry, Ownable, Initializable {
    /// @dev All required Claim Topics
    uint256[] private claimTopics;

    function init() public initializer{
        _transferOwnership(msg.sender);
    }

    /**
     *  @dev See {IClaimTopicsRegistry-addClaimTopic}.
     */
    function addClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            require(claimTopics[i] != _claimTopic, "claimTopic already exists");
        }
        claimTopics.push(_claimTopic);
        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     *  @dev See {IClaimTopicsRegistry-removeClaimTopic}.
     */
    function removeClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                claimTopics[i] = claimTopics[length - 1];
                claimTopics.pop();
                emit ClaimTopicRemoved(_claimTopic);
                break;
            }
        }
    }

    /**
     *  @dev See {IClaimTopicsRegistry-getClaimTopics}.
     */
    function getClaimTopics() external view override returns (uint256[] memory) {
        return claimTopics;
    }

    /**
     *  @dev See {IClaimTopicsRegistry-transferOwnershipOnClaimTopicsRegistryContract}.
     */
    function transferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}
