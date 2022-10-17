//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./Interfaces/IVault.sol";

contract vaultFactory is OwnableUpgradeable {

    address vault;
    mapping(uint256=>address) public vaultAddress;
    event vaultcreated(address _vault, uint256 _tokenID, address _admin);

    function  initialize(address _vault) external onlyOwner {
        require(_vault != address(0),"ZA");//Zero Address
        vault = _vault;

    }

    function createVault(string memory _name, string memory _symbol,uint256 _tokenSupply,address _token721,uint256 _tokenID,uint256 _fractionPrice,address _usdt,address _admin)external virtual onlyOwner returns(address _vault){
        require(vaultAddress[_tokenID] == address(0),"VE");//Vault already exists for the token ID
        bytes32 salt = keccak256(abi.encodePacked(_name,_symbol,_admin));
        _vault = ClonesUpgradeable.cloneDeterministic(vault, salt);
        VCount++;
        vaultAddress[_tokenID] = _vault;
        IVault(_vault).initialize(_name,_symbol,_tokenSupply,_token721,_tokenID,_fractionPrice,_usdt,_admin);
        emit vaultcreated(_vault, _tokenID, _admin);
        return _vault;

    }

    function predictVaultAddress(
        string memory _name,
        address implementation,
        address _symbol,
        uint256 _admin
    ) external view returns (address predicted) {
        bytes32 salt = keccak256(abi.encodePacked(_name,_symbol,_admin));
        return
            ClonesUpgradeable.predictDeterministicAddress(
                implementation,
                salt,
                address(this)
            );
    }

    function updateVault(address _vault) external virtual onlyOwner{
        require(_vault != address(0),"ZA");//Zero Address
        vault = _vault;
    }

    function viewVault(uint256 _tokenID) external view virtual returns(address){
        return vaultAddress[_tokenID];
    }

    function vaultNumber()
}