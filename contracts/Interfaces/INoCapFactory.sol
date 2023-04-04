//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface INoCapFactory {
    function checkNoCapNFT(address _NFT) external view returns(bool);
}