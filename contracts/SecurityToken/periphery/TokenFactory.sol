 //SPDX-License-Identifier: GPL-3.0

import 'contracts/SecurityToken/core/ProxyV1.sol';
import 'contracts/SecurityToken/core/ImplementationAuthority.sol';
import 'contracts/SecurityToken/interface/IToken.sol';
import 'contracts/SecurityToken/interface/IIdentityRegistry.sol';
import 'contracts/SecurityToken/interface/IAdminIdentityInit.sol';
import 'contracts/SecurityToken/periphery/storage/FactoryStorage.sol';
import 'contracts/SecurityToken/interface/ITrustedIssuersRegistry.sol';
import 'contracts/SecurityToken/interface/IClaimTopicsRegistry.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

pragma solidity ^0.8.0;

contract TokenFactory is AccessControl, OwnableUpgradeable, FactoryStorage{

    function init() public initializer {
        _setupRole(Operator_Role, msg.sender);
        __Ownable_init_unchained();
    }

    function addSubAdmin(address _user) external onlyOwner {
        require(!isOperator(_user), "existing operator");
        _setupRole(Operator_Role, _user);
    }

    function revokeSubAdmin(address _user) external onlyOwner {
        require(isOperator(_user), "Is not SubAdmin");
        _revokeRole(Operator_Role, _user);
    }

    function isOperator (address _user) public view returns (bool){
        return hasRole(Operator_Role, _user);
    }

    function _msgSender() internal view virtual override(Context, ContextUpgradeable) returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual override(Context, ContextUpgradeable) returns (bytes calldata) {
        return msg.data;
    }

    function _clone(address impl, bytes32 _salt) internal returns (address _cloned) {
        require(tx.origin == msg.sender,"Only owner can call");
       assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, impl))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _cloned := create2(0, ptr, 0x37, _salt)
        }
        return _cloned;
    }

            // --------------------------Set Implementation-------------------------------------

    function setImplementation (
        address _identityRegistry, address _claimTopicsRegistry,
         address _trustIssuerRegistry, address _identityRegistryStorage, address _complianceaddress, 
         address _implAuthorithyToken,
         address _implAuthorithyIdentity,
         address _implAuthorityAdminIdentity,
         address _implAuthorityIssuerIdentity) public onlyRole(Operator_Role){

        identityRegistryImpl = _identityRegistry;
        claimTopicsRegistryImpl = _claimTopicsRegistry;
        trustedIssuersRegistryImpl = _trustIssuerRegistry;
        identityRegistryStorageImpl = _identityRegistryStorage;
        complianceImpl = _complianceaddress;
        implAuthorithyToken = _implAuthorithyToken;
        implAuthorithyIdentity = _implAuthorithyIdentity;
        implAuthorityAdminIdentity = _implAuthorityAdminIdentity;
        implAuthorityIssuerIdentity = _implAuthorityIssuerIdentity;
    }

            // --------------------------Creating new Token-------------------------------------


    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _cap,
        string memory mappingValue,
        bytes32 _salt, uint256 _holdReleaseTimestamp, uint256 _tokenLimitPerUser, uint16[] memory _countries, 
        address _issuer, address _transferAgent, address _tokenizationAgent) external onlyRole(Operator_Role){

        salt = _salt;
        address identityRegistry = _clone(identityRegistryImpl,_salt);
        _initIdentityRegistry(identityRegistry);
        IIdentityRegistry(identityRegistry).addAgentOnIdentityRegistryContract(address(this));

        string memory name = _name;
        string memory symbol = _symbol;
        uint8 decimals = _decimals;
        uint256 cap = _cap;
        string memory mapValue = mappingValue;
        uint256 holdRelease = _holdReleaseTimestamp;
        uint256 tokenLimit = _tokenLimitPerUser;
        address issuer = _issuer;
        address transferAgent = _transferAgent;
        uint16[] memory countries = _countries;
        address tokenizeAgent = _tokenizationAgent;
        
        _initCompliance(identityRegistry, name, symbol, decimals, cap, mapValue, holdRelease, tokenLimit, countries, issuer, transferAgent, tokenizeAgent);
        IIdentityRegistry(identityRegistry).addAgentOnIdentityRegistryContract(issuer);
        IIdentityRegistry(identityRegistry).addAgentOnIdentityRegistryContract(_tokenizationAgent);
    }


    function _initCompliance(address identityRegistry,string memory _name,string memory _symbol,uint8 _decimals,uint _cap, string memory mappingValue, 
                uint256 _holdReleaseTimestamp, uint256 _tokenLimitPerUser, uint16[] memory _countries, address _issuer, address _transferAgent, address _tokenizeAgent) internal{
        (address compliance,address proxy) = _initProxy(identityRegistry, _name, _symbol, _decimals, _cap, mappingValue, _holdReleaseTimestamp, _tokenLimitPerUser);
        (bool success,) = compliance.call(abi.encodeWithSelector(0xc5ce23c2, address(this)));
        require(success, "Compliance Agent Factory Failed");
        success = false;
        ( success,) = compliance.call(abi.encodeWithSelector(0xb6184ccd, _countries));
        require(success, "Compliance countries Auth Failed");
        success = false;
        (success,) = proxy.call(abi.encodeWithSelector(0x20694db0, _issuer));
        require(success, "Adding Issuer Roles Failed");
        success = false;
        ( success,) = proxy.call(abi.encodeWithSelector(0xb0314599, _transferAgent));
        require(success, "Adding Transfer Agent Failed");
        success = false;
        (success, ) = proxy.call(abi.encodeWithSelector(0xadccbc3c, _tokenizeAgent));
        require(success, "Adding Tokenization Agent Failed");
    }

    function _initProxy(address identityRegistry, string memory _name, string memory _symbol, uint8 _decimals, uint _cap, string memory mappingValue, 
                uint256 _holdReleaseTimestamp, uint256 _tokenLimitPerUser) internal returns(address compliance, address proxy){
        compliance = _clone(complianceImpl,salt);
        proxy = address(new ProxyV1());

        tokens.push(proxy);
        tokenId[proxy] = tokens.length;

        address _tokenIdentity = _deployIdentity();

        (bool success,) = proxy.call(abi.encodeWithSelector(0x3659cfe6, implAuthorithyToken));
        require(success,"upgrade failed");
        success = false;
        (success,) = proxy.call(abi.encodeWithSelector(0xd44526bc, identityRegistry, compliance, _name, _symbol, _decimals, _tokenIdentity, _cap));
        require(success, "Token Intiatialization Failed");
        success = false;
        (success,) = proxy.call(abi.encodeWithSelector(0x70480275, owner()));
        require(success, "Add Admin Role Failed");
        success = false;
        (success,) = compliance.call(abi.encodeWithSelector(0xa4a2a9f6, proxy, _holdReleaseTimestamp, _tokenLimitPerUser));
        require(success, "Compliance Intiatialization Failed");
        
        emit tokenCreated(proxy, implAuthorithyToken, identityRegistry, mappingValue, block.timestamp);
    }

    function _initProxyCompliance(address proxy, address compliance, uint256 _holdReleaseTimestamp, uint256 _tokenLimitPerUser) internal {
        (bool success,) = proxy.call(abi.encodeWithSelector(0xf2fde38b, address(this)));
        require(success, "token ownership Failed");
        success = false;
        (success,) = compliance.call(abi.encodeWithSelector(0xa4a2a9f6, proxy, _holdReleaseTimestamp, _tokenLimitPerUser));
        require(success, "Compliance Intiatialization Failed");
        success = false;
        (success,) = compliance.call(abi.encodeWithSelector(0x32119257, owner()));
        require(success, "Compliance Roles Failed");
    }

    function _initIdentityRegistry(address identityRegistry) internal{
        address claimTopicsRegistry = _clone(claimTopicsRegistryImpl,salt);
        address trustedIssuersRegistry = _clone(trustedIssuersRegistryImpl,salt);
        address identityRegistryStorage = _clone(identityRegistryStorageImpl,salt);
        (bool success,) = identityRegistry.call(abi.encodeWithSelector(0x184b9559, trustedIssuersRegistry, claimTopicsRegistry, identityRegistryStorage));
        require(success, "identity Intiatialization Failed");
        success = false;
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0xe1c7392a));
        require(success, "Identity Registry Storage Initialization Failed");
        success = false;
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0x690a49f9, identityRegistry));
        require(success, "identityRegistryStorage bind Failed");
        success = false;
        (success,) = claimTopicsRegistry.call(abi.encodeWithSelector(0xe1c7392a));
        require(success, "claimTopicsRegistry init failure");
        success = false;
        (success,) = trustedIssuersRegistry.call(abi.encodeWithSelector(0xe1c7392a));
        require(success, "trustedIssuersRegistry init failure");
    }

    function _deployIdentity() internal returns (address) {
        address identityProxy = address(new ProxyV1());

        (bool success,) = identityProxy.call(abi.encodeWithSelector(0x3659cfe6, implAuthorithyIdentity));
        require(success,"upgrade failed");
        success = false;
    
        (success,) = identityProxy.call(abi.encodeWithSelector(0x19ab453c, address(this)));
        require(success, "Identity Intiatialization Failed");
        success = false;
        return identityProxy;
    }

            // --------------------------Deploying MultiSig for Token-------------------------------------

    function deployAdminIdentity(uint256 executionBuffer, uint256 reqSig, address tokenizationAgent , address _issuer, address _token) public onlyRole(Operator_Role) returns (address) {
        address adminIdentityProxy = address(new ProxyV1());

        (bool success,) = adminIdentityProxy.call(abi.encodeWithSelector(0x3659cfe6, implAuthorityAdminIdentity));
        require(success," Upgrade failed");
        success = false;
    
        (success,) = adminIdentityProxy.call(abi.encodeWithSelector(0xc0aa2852, address(this), executionBuffer, reqSig, _token));
        require(success, "Admin Identity Intiatialization Failed");
        success = false;

        (success,) = adminIdentityProxy.call(abi.encodeWithSelector(0x1d381240, keccak256(abi.encode(tokenizationAgent)), 2, 1));
        require(success, "Tokenize Addkey failure");
        success = false;

        (success,) = adminIdentityProxy.call(abi.encodeWithSelector(0x1d381240, keccak256(abi.encode(_issuer)), 2, 1));
        require(success, "Issuer Addkey failure");

        bytes32[] memory role = new bytes32[](1);
        role[0]=Minter_Role;

        setRolesOnToken(adminIdentityProxy, role, _token);
        revokeRolesOnToken(tokenizationAgent, role, _token);
        revokeRolesOnToken(_issuer, role, _token);

        adminIdentityMinter[_token] = adminIdentityProxy;

        return adminIdentityProxy;
    }

            // --------------------------Functions for Token-------------------------------------

    function addAgents(address _transferAgent, address _tokenizationAgent, address _token) external onlyRole(Operator_Role) {
        addTokenizationAgentOnToken(_tokenizationAgent, _token);
        addTransferAgentOnToken(_transferAgent, _token);
    }

    function whitelistUser(address _token, address _userAddress, uint16 _countryCode, address _userIdentity) internal {
        IIdentityRegistry iR = IToken(_token).identityRegistry();
        require(iR.isAgentOnIdentityRegistry(msg.sender),"Not an Agent on Token Identity Registry");
        IIdentityRegistry(iR).registerIdentity(_userAddress, IIdentity(_userIdentity), _countryCode);
        emit whiteListed(_userAddress);
    }

    function deployAndWhitelist(address _token, address _userAddress, uint16 _CountryCode) public {
        if(userIdentityId[_userAddress] == 0){
        address userIdentity = _deployIdentity();
        userIdentities.push(userIdentity);
        userIdentityId[_userAddress] = userIdentities.length;
        whitelistUser(_token, _userAddress, _CountryCode, userIdentity);
        }
        else{
            address userIdentity = userIdentities[userIdentityId[_userAddress] - 1];
            whitelistUser(_token, _userAddress, _CountryCode, userIdentity);
        }
    }

    function batchDeployAndWhitelist(address _token, address[] calldata _userAddress, uint16[] calldata _countrycodes) external {
        for(uint i=0; i < _userAddress.length; i++)
        {
            deployAndWhitelist( _token,  _userAddress[i],  _countrycodes[i]);
        }
    }

    function getIdentityOf(address _userAddress) public view returns(address){
        return userIdentities[userIdentityId[_userAddress] - 1];
    }

    function setRolesOnToken(address _userAddress, bytes32[] memory roles, address _token) public onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.setRolesToTokenAgent(_userAddress, roles);
    }

    function revokeRolesOnToken(address _userAddress, bytes32[] memory roles, address _token) public onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.revokeRolesOnTokenAgent(_userAddress, roles);
    }

    function addSubAdminOnToken(address _userAddress, address _token) external onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.addAdmin(_userAddress);
    }

    function revokeSubAdminOnToken(address _userAddress, address _token) external onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.revokeAdmin(_userAddress);
    }

    function addTokenizationAgentOnToken(address _agent, address _token) public onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.addTokenizationAgentOnToken(_agent);
        IIdentityRegistry iR = token.identityRegistry();
        iR.addAgentOnIdentityRegistryContract(_agent);
    } 

    function revokeTokenizationAgentOnToken(address _agent, address _token) external onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.removeTokenizationAgentOnToken(_agent);
        IIdentityRegistry iR = token.identityRegistry();
        iR.removeAgentOnIdentityRegistryContract(_agent);
    }

    function addTransferAgentOnToken(address _agent, address _token) public onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.addTokenizationAgentOnToken(_agent);
    }

    function removeTransferAgentOnToken(address _agent, address _token) external onlyRole(Operator_Role){
        IToken token = IToken(_token);
        token.removeTransferAgentOnToken(_agent);
    }

    function updateReleaseTimestampForToken(address _token, uint256 _timestamp) external onlyRole(Operator_Role){
        IToken token = IToken(_token);
        ICompliance compliance = token.compliance();
        compliance.updateReleaseTimestamp(_timestamp);
    }

    function updateHolderLimitForToken(address _token, uint256 _newHolderLimit) external onlyRole(Operator_Role){
        IToken token = IToken(_token);
        ICompliance compliance = token.compliance();
        compliance.updateHolderLimit(_newHolderLimit);
    }

            // --------------------------Functions for Identity Registry-------------------------------------

    function addSubAdminOnIdentityRegistry(address _userAddress, address _identityRegistry) external onlyRole(Operator_Role){
        IIdentityRegistry iR = IIdentityRegistry(_identityRegistry);
        iR.addSubAdminOnIR(_userAddress);
    }

    function revokeSubAdminOnIdentityRegistry(address _SubAdminAddress, address _identityRegistry) external onlyRole(Operator_Role){
        IIdentityRegistry iR = IIdentityRegistry(_identityRegistry);
        iR.revokeSubAdminOnIR(_SubAdminAddress);
    }

            // --------------------------Functions for Compliance-------------------------------------


    function addSubAdminOnCompliance(address _userAddress, address _compliance) external onlyRole(Operator_Role){
        ICompliance compliance = ICompliance(_compliance);
        compliance.addSubAdminOnCompliance(_userAddress);
    }

    function revokeSubAdminOnCompliance(address _SubOwner, address _compliance) external onlyRole(Operator_Role){
        ICompliance compliance = ICompliance(_compliance);
        compliance.revokeSubAdminOnCompliance(_SubOwner);
    }

            // --------------------------Function for MultiSig-------------------------------------

    function addAdminIdentitySigner(address _signer, address _token)public onlyRole(Operator_Role){
        address multiSig = getAdminIdentityMinter(_token);
        IAdminIdentityInit(multiSig).addKey(keccak256(abi.encode(_signer)), 2, 1);

        bytes32[] memory role = new bytes32[](1);
        role[0]=Minter_Role;

        revokeRolesOnToken(_signer, role, _token);
    }

    function removeMultiSigSigner(address _signer, address _token)public onlyRole(Operator_Role){
        address multiSig = getAdminIdentityMinter(_token);
        IAdminIdentityInit(multiSig).removeKey(keccak256(abi.encode(_signer)), 2);
    }

    function setSigRequirementOnMultiSig(uint256 _sigReq, address _token) public onlyRole(Operator_Role){
        address multiSig = getAdminIdentityMinter(_token);
        IAdminIdentityInit(multiSig).setSigRequirement(_sigReq);
    }

    function getAdminIdentityMinter(address _token) public view returns(address){
        return adminIdentityMinter[_token];
    }

    function getTrustedIssuersRegistry(address _token) public view returns(address) {
        return address((IToken(_token).identityRegistry()).issuersRegistry());
    }

    function getClaimTopicsRegistry(address _token) public view returns(address) {
        return address((IToken(_token).identityRegistry()).topicsRegistry());
    }


        // --------------------------UNRESTRICTED ADMIN FUNCTIONS-------------------------------------
    /**
     * @dev function to execute a low level call to any contracts owned by the factory
     */
    function adminCallUnrestricted(address _to, uint256 _value, bytes calldata _data) external onlyRole(Operator_Role) returns(bool success){
        (success,) = _to.call{value: _value}(_data);
    } 

}