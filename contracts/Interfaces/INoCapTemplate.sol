//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface INoCapTemplate {
    
   function initialize(string memory _name, 
                       string memory _symbol, 
                       address _admin, 
                       uint96 _royaltyAmount, 
                       address _marketPlace,
                       address _securityTokenFactory) 
                       external;
   
   function MintNft(address _to, uint _tokenId, string memory _tokenURI, address _royaltyKeeper,uint256 _maxFractions, uint256 _fractions, uint96 _royaltyFees) external returns(address);

   function checkExist(uint _tokenId) external view returns(bool);

   function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);

   function getSTOForTokenId(uint256 _tokenId) external view returns(address);



}