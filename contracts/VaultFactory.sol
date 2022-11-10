//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./Interfaces/IVault.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract vaultFactory is Ownable, Initializable {
    address vault;
    mapping(uint256 => address) public vaultAddress;
    mapping(address => bool) private operators;
    event vaultcreated(address _vault, uint256 _tokenID, address _admin);

    modifier onlyOperator() {
        require(operators[msg.sender], "NO"); //Not Operator
        _;
    }

    function initialize(address _vault) external onlyOwner {
        require(_vault != address(0), "ZA"); //Zero Address
        vault = _vault;
    }

    function createVault(
        string memory _name,
        string memory _symbol,
        uint256 _tokenSupply,
        address _token721,
        uint256 _tokenID,
        uint256 _fractionPrice,
        address _usdt,
        address _admin,
        address _taxWallet,
        address _marketFeeWallet
    ) external onlyOperator returns (address) {
        require(vaultAddress[_tokenID] == address(0), "VE"); //Vault already exists for the token ID
        require(_admin != address(0), "ZAA"); //Zero address for admin
        require(_token721 != address(0), "ZAT"); //Zero address for token
        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol, _admin));
        address _vault = ClonesUpgradeable.cloneDeterministic(vault, salt);
        // VCount++;
        vaultAddress[_tokenID] = _vault;
        IVault(_vault).initialize(
            _name,
            _symbol,
            _tokenSupply,
            _token721,
            _tokenID,
            _fractionPrice,
            _usdt,
            _admin,
            _taxWallet,
            _marketFeeWallet
        );
        emit vaultcreated(_vault, _tokenID, _admin);
        return _vault;
    }

    function predictVaultAddress(
        string memory _name,
        address implementation,
        address _symbol,
        uint256 _admin
    ) external view returns (address predicted) {
        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol, _admin));
        return
            ClonesUpgradeable.predictDeterministicAddress(
                implementation,
                salt,
                address(this)
            );
    }

    function updateVault(address _vault) external onlyOwner {
        require(_vault != address(0), "ZA"); //Zero Address
        vault = _vault;
    }

    function viewVault(uint256 _tokenID) external view returns (address) {
        return vaultAddress[_tokenID];
    }

    function addOperator(address account, bool status) external onlyOwner {
        require(account != address(0), "ZA"); //Zero Address
        operators[account] = status;
    }

    function _msgSender() internal view override(Context) returns (address) {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        override(Context)
        returns (bytes calldata)
    {
        return msg.data;
    }
}
