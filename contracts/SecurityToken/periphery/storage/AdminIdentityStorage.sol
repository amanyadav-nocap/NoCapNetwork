// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../interface/IAdminIdentityInit.sol";

contract AdminIdentityStorage{

    address public token;
    uint256 internal executionNonce;
    uint256 internal executionExpiry;
    uint256 internal sigReq;
    mapping(bytes32 => IAdminIdentityInit.Key) internal keys;
    mapping(uint256 => bytes32[]) internal keysByPurpose;
    mapping(uint256 => IAdminIdentityInit.Execution) internal executions;
    mapping(bytes32 => IAdminIdentityInit.Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic;

}