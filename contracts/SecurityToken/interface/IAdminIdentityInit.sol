 //SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IIdentity.sol";

interface IAdminIdentityInit is IIdentity{

    /**
    * @dev Definition of the structure of a Key.
    *
    * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
    * The structure should be as follows:
    *   - key: A public key owned by this identity
    *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
    *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
    */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    struct Execution {
        bytes32 proposer;
        address to;
        uint256 value;
        uint256 timestamp;
        bytes data;
        bool executed;
        bytes32[] approvals;
    }

   /**
    * @dev Definition of the structure of a Claim.
    *
    * Specification: Claims are information an issuer has about the identity holder.
    * The structure should be as follows:
    *   - claim: A claim published for the Identity.
    *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
    *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
    *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
    *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
    *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
    *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /**
     * @dev Emitted when an approval was added for a queued execution.
     *  
     * Specification: MUST be triggered when approval was successfully added for execution.
     */
    event ApprovalAdded(uint256 indexed _id, bytes32 indexed _key);

    /**
     * @dev Emitted when an approval is cancelled for an execution.
     *  
     * Specification: MUST be triggered when a previous approval was cancelled.
     */
    event ApprovalCancelled(uint256 indexed _id, bytes32 indexed _key);

    /**
     * @dev Emitted when an execution is cancelled by an operator
     *  
     * Specification: MUST be triggered when execution is cancelled.
     */
    event ExecutionCancelled(uint256 indexed _id, bytes32 indexed _key);

    /**
     * @dev Emitted when a mint execution is requested and added to the queue.
     *  
     * Specification: MUST be triggered when initiateMultisigMint() function is called.
     */
    event MintExecutionRequested(uint256 indexed _id, address indexed _to, uint256 _value, bytes32 indexed _key);
    
    function cancelApproval(uint256 _id) external returns (bool);
    function cancelExecution(uint256 _id) external;
    function cancelCheck(uint256 _id) external view returns (bool);
    function setSigRequirement(uint256 _sigs) external;
    function setExecutionExpiry(uint256 _expiry) external;
    function getExecution(uint256 _id) external view returns(Execution memory);
    function getCurrentExecution() external view returns(Execution memory);
    function getNonce() external view returns(uint256);
    function initiateMultisigMint(address _to, uint256 _value) external;

}
