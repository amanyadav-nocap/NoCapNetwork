//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ISecurityTokenFactory {
    function deployTokenForNFT(string memory _name, string memory _symbol,uint8 _decimals, uint256 _tokenId,uint256 _maxFractions) external returns(address);
}