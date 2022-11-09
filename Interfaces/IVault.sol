//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

interface IVault {
    function initialize(
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
    ) external;

    function _transfer(address _from,address _to, uint256 _amount) external;

    function buyFractions(uint256 _fractionAmount) external;

    function makeOffer(uint256 offerredPrice) external;

    function voteOffer(uint256 _offerNumber, bool vote) external;

    function claim(uint256 _offerNumber) external;
}
