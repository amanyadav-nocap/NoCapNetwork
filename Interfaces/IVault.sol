//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IVault{

    function initialize(string memory _name, string memory _symbol,uint256 _tokenSupply,address _token721,uint256 _tokenID,uint256 _fractionPrice,address _usdt,address _admin)external;
    function transfer(address _to, uint256 _amount) external virtual;
    function makeOffer(uint256 offerredPrice) external virtual;
    function voteOffer(uint256 _offerNumber, bool vote) external virtual;
    function claim(uint256 _offerNumber) external virtual;
    
}