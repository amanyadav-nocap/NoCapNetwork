//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ICompliance {

    function init(address _token, uint256 _holdReleaseTime, uint256 _tokenLimitPerUser) external;

    function addTokenAgent(address _user) external;

    function addAgent(address _user) external;

    function authorizeCountries(uint16[] calldata _countries) external;

    function addAgentOnComplianceContract(address _agent) external;

}