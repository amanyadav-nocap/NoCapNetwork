//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NoCapDAO is OwnableUpgradeable {

    address public admin;
    address public marketplace;
    address public noCapFactory;

    struct Proposal {
        uint proposalNumber;
        uint proposer;
        string proposalString;
        uint totalVotes;
        uint totalYes;
        uint startTime;
        uint endTime;
        bool active;
    }

    mapping(address=> mapping(address=>Proposal)) public NoCapNFTProposal;


}