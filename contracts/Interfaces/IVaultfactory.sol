//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IVaultfactory {
    function initialize(address _vault) external;

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
    ) external returns (address _vault);

    function updateVault(address _vault) external;

    function viewVault(uint256 _tokenID) external;
}
