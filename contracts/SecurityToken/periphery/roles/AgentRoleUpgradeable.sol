// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AgentRoleUpgradeable is OwnableUpgradeable, AccessControl {

    bytes32 public constant SubAdmin_Role = keccak256("SubAdmin_Role");
    bytes32 public constant Minter_Role = keccak256("Minter_Role");
    bytes32 public constant Burner_Role = keccak256("Burner_Role");
    bytes32 public constant Freezer_Role = keccak256("Freezer_Role");
    bytes32 public constant UnFreezer_Role = keccak256("UnFreezer_Role");
    bytes32 public constant ForceTransfer_Role = keccak256("ForceTransfer_Role");
    bytes32 public constant Issuer_Role = keccak256("Issuer_Role");
    bytes32 public constant TransferAgent_Role = keccak256("TransferAgent_Role");
    bytes32 public constant TokenizationAgent_Role = keccak256("TokenizationAgent_Role");

    mapping(address => bool) public blockedAgents;

    event AgentAdded(address indexed _user);
    event AgentRemoved(address indexed _user);
    event TokenizationAgentAdded(address indexed _user);
    event TokenizationAgentRemoved(address indexed _user);
    event TransferAgentAdded(address indexed _user);
    event TransferAgentRemoved(address indexed _user);
    event IssuerAdded(address indexed _user);
    event IssuerRemoved(address indexed _user);

    modifier onlyAdmins{
        require(hasRole(SubAdmin_Role, msg.sender) || owner() == msg.sender, "You Dont Have Admin Role");
        _;
    }

    function _msgSender() internal view virtual override(Context, ContextUpgradeable) returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual override(Context, ContextUpgradeable) returns (bytes calldata) {
        return msg.data;
    }

    function _setAdminRole(address _user) internal {
        _setupRole(SubAdmin_Role, _user);    }

    function addSubAdmin(address _user) public onlyAdmins {
        require(!isSubAdmin(_user), "Already have SunAdmin Role");
        _setupRole(SubAdmin_Role, _user);
    }

    function revokeSubAdmin(address _user) public onlyAdmins {
        require(isSubAdmin(_user), "Doesn't have Owner Role");
        _revokeRole(SubAdmin_Role, _user);
    }

    function isSubAdmin (address _user) public view returns (bool){
        return hasRole(SubAdmin_Role, _user);
    }

    function setRolesToAgent(address _user, bytes32[] memory roles) public onlyAdmins{
        for(uint i = 0; i < roles.length; i++)
        {
            _setupRole(roles[i], _user);
        }
    }

    function revokeRolesOnAgent(address _user, bytes32[] memory roles) public onlyAdmins{
        for(uint i = 0; i < roles.length; i++)
        {
            _revokeRole(roles[i], _user); 
        }
    }

     function addIssuer(address _user) public onlyAdmins{
        require(!isIssuer(_user), "Already have Issuer Role");
        bytes32[] memory array = new bytes32[](6);
        array[0] = Minter_Role;
        array[1] = Burner_Role;
        array[2] = Freezer_Role;
        array[3] = UnFreezer_Role;
        array[4] = ForceTransfer_Role;
        array[5] = Issuer_Role;
        setRolesToAgent(_user, array);
        emit IssuerAdded(_user);
    }

    function revokeIssuer(address _user) public onlyAdmins{
        require(isIssuer(_user), "Doesn't have Issuer Role");
        bytes32[] memory array = new bytes32[](6);
        array[0] = Minter_Role;
        array[1] = Burner_Role;
        array[2] = Freezer_Role;
        array[3] = UnFreezer_Role;
        array[4] = ForceTransfer_Role;
        array[5] = Issuer_Role;
        revokeRolesOnAgent(_user, array);
        emit IssuerRemoved(_user);
    }

    function addTransferAgent(address _user) public onlyAdmins {
        require(!hasRole(TransferAgent_Role, _user), "transfer agent role active");
        bytes32[] memory array = new bytes32[](4);
        array[0] = Freezer_Role;
        array[1] = UnFreezer_Role;
        array[2] = ForceTransfer_Role;
        array[3] = TransferAgent_Role;
        setRolesToAgent(_user, array);
        emit TransferAgentAdded(_user);
    }

    function removeTransferAgent(address _user) public onlyAdmins {
        require(hasRole(TransferAgent_Role, _user), "non transfer agent");
        bytes32[] memory array = new bytes32[](4);
        array[0] = Freezer_Role;
        array[1] = UnFreezer_Role;
        array[2] = ForceTransfer_Role;
        array[3] = TransferAgent_Role;
        revokeRolesOnAgent(_user, array);
        emit TransferAgentRemoved(_user);
    }

    function isIssuer (address _user) public view returns (bool) {
        return hasRole(Issuer_Role, _user);
    }

    function isTransferAgent(address _user) public view returns (bool) {
        return hasRole(TransferAgent_Role, _user);
    }

    function isTokenizationAgent(address _user) public view returns (bool) {
        return hasRole(TokenizationAgent_Role, _user);
    }

    function addTokenizationAgent(address _user) public onlyAdmins {
        require(!isTokenizationAgent(_user), "tokenization role active");
        bytes32[] memory array = new bytes32[](3);
        array[0] = Minter_Role;
        array[1] = Burner_Role;
        array[2] = TokenizationAgent_Role;
        setRolesToAgent(_user, array);
        emit TokenizationAgentAdded(_user);
    }

    function removeTokenizationAgent(address _user) public onlyAdmins {
        require(isTokenizationAgent(_user), "non tokenization agent");
        bytes32[] memory array = new bytes32[](3);
        array[0] = Minter_Role;
        array[1] = Burner_Role;
        array[2] = TokenizationAgent_Role;
        revokeRolesOnAgent(_user, array);
        emit TokenizationAgentRemoved(_user);
    }


}
