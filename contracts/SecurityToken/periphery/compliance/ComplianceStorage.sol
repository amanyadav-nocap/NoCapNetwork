pragma solidity ^0.8.0;

import "contracts/SecurityToken/interface/IToken.sol";
import "contracts/SecurityToken/interface/IIdentityRegistry.sol";

contract ComplianceStorage {
    /// @dev Mapping of tokens linked to the compliance contract
    mapping(address => bool) internal _tokensBound;
    mapping(uint16 => bool) internal _authorizedCountries;
    /// @dev the amount of shareholders per country
    mapping(uint16 => uint256) internal _countryShareHolders;
    /// @dev the index of each shareholder in the array `shareholders`
    mapping(address => uint256) internal _holderIndices;
    /// @dev Mapping between agents and their statuses
    mapping(address => bool) internal _tokenAgentsList;
    /// @dev the addresses of all shareholders
    address[] internal _shareholders;
    /// @dev the hold release timestamp
    uint256 internal _holdRelease;
    /// @dev the maximum amount of tokens a user can own
    uint256 internal _tokenLimit;
    /// @dev the token on which this compliance contract is applied
    IToken public token;
    /// @dev the Identity registry contract linked to `token`
    IIdentityRegistry internal _identityRegistry;
}