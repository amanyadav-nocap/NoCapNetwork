//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ITokenST {

    function init(
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _tokenIdentity,
        uint256 _cap,
        address _nftMarketplace,
        address _ownedNftAddress,
        address _admin
    ) external;

    function mint(address _to, uint256 _amount) external;

    function setRolesToTokenAgent(address _userAddress, bytes32[] memory roles) external;

    

}