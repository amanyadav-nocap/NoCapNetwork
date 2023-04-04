// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "contracts/SecurityToken/interface/IToken.sol";
import "contracts/SecurityToken/interface/IERC734.sol";
import "contracts/SecurityToken/interface/IERC735.sol";
import "contracts/SecurityToken/interface/IIdentity.sol";
import "contracts/SecurityToken/interface/IClaimTopicsRegistry.sol";
import "contracts/SecurityToken/interface/IIdentityRegistry.sol";
import "contracts/SecurityToken/interface/ICompliance.sol";
import "contracts/SecurityToken/periphery/storage/TokenStorage.sol";
import "contracts/SecurityToken/periphery/roles/AgentRoleUpgradeable.sol";

contract TokenST is IToken, AgentRoleUpgradeable, TokenStorage {
     
    address public NFTMarketplace;
    address public ownedNftAddress;

    /**
     *  @dev the constructor initiates the token contract
     *  msg.sender is set automatically as the owner of the smart contract
     *  @param _identityRegistry the address of the Identity registry linked to the token
     *  @param _compliance the address of the compliance contract linked to the token
     *  @param _name the name of the token
     *  @param _symbol the symbol of the token
     *  @param _decimals the decimals of the token
     *  @param _cap the maxSupply of the token
     *  emits an `UpdatedTokenInformation` event
     *  emits an `IdentityRegistryAdded` event
     *  emits a `ComplianceAdded` event
     */
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
    ) public initializer{
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        maxSupply = _cap;
        tokenIdentity = _tokenIdentity;
        tokenIdentityRegistry = IIdentityRegistry(_identityRegistry);
        NFTMarketplace = _nftMarketplace;
        ownedNftAddress = _ownedNftAddress;
        emit IdentityRegistryAdded(_identityRegistry);
        tokenCompliance = ICompliance(_compliance);
        _setAdminRole(_admin);
        emit ComplianceAdded(_compliance);
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenIdentity, maxSupply);
        __Ownable_init_unchained();
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!tokenPaused, "Pausable: paused");
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(tokenPaused, "Pausable: not paused");
        _;
    }

    /**
     *  @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     *  @dev See {circulationSupply}.
     */
    function circulationSupply() external view returns(uint256) {
        return _totalSupply - frozenTokensCount;
    }

    /**
     *  @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address _userAddress) public view override returns (uint256) {
        return _balances[_userAddress];
    }

    /**
     *  @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address _spender) external view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /**
     *  @dev See {IERC20-approve}.
     */
    function approve(address _spender, uint256 _amount) external virtual override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     *  @dev See {ERC20-increaseAllowance}.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external virtual returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + (_addedValue));
        return true;
    }

    /**
     *  @dev See {ERC20-decreaseAllowance}.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] - _subtractedValue);
        return true;
    }

    /**
     *  @dev See {ERC20-_mint}.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        _balances[_from] = _balances[_from] - _amount;
        _balances[_to] = _balances[_to] + _amount;
        emit Transfer(_from, _to, _amount);
    }

    /**
     *  @dev See {ERC20-_mint}.
     */
    function _mint(address _userAddress, uint256 _amount) internal virtual {
        require(_userAddress != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), _userAddress, _amount);

        _totalSupply = _totalSupply + _amount;
        _balances[_userAddress] = _balances[_userAddress] + _amount;
        emit Transfer(address(0), _userAddress, _amount);
    }

    /**
     *  @dev See {ERC20-_burn}.
     */
    function _burn(address _userAddress, uint256 _amount) internal virtual {
        require(_userAddress != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(_userAddress, address(0), _amount);

        _balances[_userAddress] = _balances[_userAddress] - _amount;
        _totalSupply = _totalSupply - _amount;
        emit Transfer(_userAddress, address(0), _amount);
    }

    /**
     *  @dev See {ERC20-_approve}.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     *  @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {}

    /**
     *  @dev See {IToken-decimals}.
     */
    function decimals() external view override returns (uint8) {
        return tokenDecimals;
    }

    /**
     *  @dev See {IToken-name}.
     */
    function name() external view override returns (string memory) {
        return tokenName;
    }

    /**
     *  @dev See {IToken-onchainID}.
     */
    function getTokenIdentity() external view override returns (address) {
        return tokenIdentity;
    }

    /**
     *  @dev See {IToken-symbol}.
     */
    function symbol() external view override returns (string memory) {
        return tokenSymbol;
    }

    /**
     *  @dev See {IToken-setName}.
     */
    function setName(string calldata _name) external override onlyAdmins {
        tokenName = _name;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenIdentity, maxSupply);
    }

    /**
     *  @dev See {IToken-setSymbol}.
     */
    function setSymbol(string calldata _symbol) external override onlyAdmins {
        tokenSymbol = _symbol;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenIdentity, maxSupply);
    }

    /**
     *  @dev See {IToken-setOnchainID}.
     */
    function setTokenIdentity(address _tokenIdentity) external override onlyAdmins {
        tokenIdentity = _tokenIdentity;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenIdentity, maxSupply);
    }

    /**
     *  @dev See {IToken-setMaxSupply}.
     */
    function setMaxSupply(uint256 _maxCap) external onlyAdmins {
        require(_maxCap >= _totalSupply, "Cannot be less than Total Supply");
        maxSupply = _maxCap;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, tokenIdentity, maxSupply);
    }

    /**
     *  @dev See {IToken-paused}.
     */
    function paused() external view override returns (bool) {
        return tokenPaused;
    }

    /**
     *  @dev See {IToken-isFrozen}.
     */
    function isFrozen(address _userAddress) external view override returns (bool) {
        return frozen[_userAddress];
    }

    /**
     *  @dev See {IToken-getFrozenTokens}.
     */
    function getFrozenTokens(address _userAddress) external view override returns (uint256) {
        return frozenTokens[_userAddress];
    }

    /**
     *  @notice ERC-20 overridden function that include logic to check for trade validity.
     *  Require that the msg.sender and to addresses are not frozen.
     *  Require that the value should not exceed available balance .
     *  Require that the to address is a verified address
     *  @param _to The address of the receiver
     *  @param _amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     */
    function transfer(address _to, uint256 _amount) public override whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[msg.sender], "wallet is frozen");
        require(_amount <= balanceOf(msg.sender) - (frozenTokens[msg.sender]), "Insufficient Balance");
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(msg.sender, _to, _amount)) {
            tokenCompliance.transferred(msg.sender, _to, _amount);
            _transfer(msg.sender, _to, _amount);
            return true;
        }
        revert("Transfer not possible");
    }

    /**
     *  @dev See {IToken-pause}.
     */
    function pause() external override onlyAdmins whenNotPaused {
        tokenPaused = true;
        emit Paused(msg.sender);
    }

    /**
     *  @dev See {IToken-unpause}.
     */
    function unpause() external override onlyAdmins whenPaused {
        tokenPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     *  @dev See {IToken-identityRegistry}.
     */
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return tokenIdentityRegistry;
    }

    /**
     *  @dev See {IToken-compliance}.
     */
    function compliance() external view override returns (ICompliance) {
        return tokenCompliance;
    }

    /**
     *  @dev See {IToken-batchTransfer}.
     */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _toList.length; i++) {
            transfer(_toList[i], _amounts[i]);
        }
    }

    /**
     *  @notice ERC-20 overridden function that include logic to check for trade validity.
     *  Require that the from and to addresses are not frozen.
     *  Require that the value should not exceed available balance .
     *  Require that the to address is a verified address
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[_from], "wallet is frozen");
        require(_amount <= balanceOf(_from) - (frozenTokens[_from]), "Insufficient Balance");
        
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(_from, _to, _amount)) {
            tokenCompliance.transferred(_from, _to, _amount);
            _transfer(_from, _to, _amount);
            _approve(_from, msg.sender, _allowances[_from][msg.sender] - (_amount));
            return true;
        }

        revert("Transfer not possible");
    }

    /**
     *  @dev See {IToken-forcedTransfer}.
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public override onlyRole(ForceTransfer_Role) returns (bool) {
        uint256 freeBalance = balanceOf(_from) - (frozenTokens[_from]);
        if (_amount > freeBalance) {
            uint256 tokensToUnfreeze = _amount - (freeBalance);
            frozenTokens[_from] = frozenTokens[_from] - (tokensToUnfreeze);
            emit TokensUnfrozen(_from, tokensToUnfreeze);
        }
        if (tokenIdentityRegistry.isVerified(_to)) {
            tokenCompliance.transferred(_from, _to, _amount);
            _transfer(_from, _to, _amount);
            return true;
        }
        revert("Transfer not possible");
    }

    /**
     *  @dev See {IToken-batchForcedTransfer}.
     */
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override {
        for (uint256 i = 0; i < _fromList.length; i++) {
            forcedTransfer(_fromList[i], _toList[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-mint}.
     */
    function mint(address _to, uint256 _amount) public override {
        require(msg.sender==ownedNftAddress,"Invalid call only Collection allowed.");
        require(tokenIdentityRegistry.isVerified(_to), "Identity is not verified.");
        require(tokenCompliance.canMint(msg.sender, _to, _amount), "Compliance not followed");
        require(maxSupply == 0 || (maxSupply - _totalSupply) >= _amount, "Cannot go over maximum supply");

        _mint(_to, _amount);
        tokenCompliance.created(_to, _amount);
    }

    /**
     *  @dev See {IToken-batchMint}.
     */
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _toList.length; i++) {
            mint(_toList[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-burn}.
     */
    function burn(address _userAddress, uint256 _amount) public override onlyRole(Burner_Role) {
        uint256 freeBalance = balanceOf(_userAddress) - frozenTokens[_userAddress];
        if (_amount > freeBalance) {
            uint256 tokensToUnfreeze = _amount - (freeBalance);
            frozenTokens[_userAddress] = frozenTokens[_userAddress] - (tokensToUnfreeze);
            emit TokensUnfrozen(_userAddress, tokensToUnfreeze);
        }
        _burn(_userAddress, _amount);
        tokenCompliance.destroyed(_userAddress, _amount);
    }

    /**
     *  @dev See {IToken-batchBurn}.
     */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            burn(_userAddresses[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-setAddressFrozen}.
     */
    function setAddressFrozen(address _userAddress, bool _freeze) public override onlyAdmins {
        frozen[_userAddress] = _freeze;

        emit AddressFrozen(_userAddress, _freeze, msg.sender);
    }

    /**
     *  @dev See {IToken-batchSetAddressFrozen}.
     */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            setAddressFrozen(_userAddresses[i], _freeze[i]);
        }
    }

    /**
     *  @dev See {IToken-freezePartialTokens}.
     */
    function freezePartialTokens(address _userAddress, uint256 _amount) public override onlyRole(Freezer_Role) {
        uint256 balance = balanceOf(_userAddress);
        require(balance >= frozenTokens[_userAddress] + _amount, "Amount exceeds available balance");
        frozenTokens[_userAddress] = frozenTokens[_userAddress] + (_amount);
        frozenTokensCount += _amount; 
        emit TokensFrozen(_userAddress, _amount);
    }

    /**
     *  @dev See {IToken-batchFreezePartialTokens}.
     */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            freezePartialTokens(_userAddresses[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-unfreezePartialTokens}.
     */
    function unfreezePartialTokens(address _userAddress, uint256 _amount) public override onlyRole(UnFreezer_Role) {
        require(frozenTokens[_userAddress] >= _amount, "Amount should be less than or equal to frozen tokens");
        frozenTokens[_userAddress] = frozenTokens[_userAddress] - (_amount);
        frozenTokensCount -= _amount;
        emit TokensUnfrozen(_userAddress, _amount);
    }

    /**
     *  @dev See {IToken-batchUnfreezePartialTokens}.
     */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            unfreezePartialTokens(_userAddresses[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-setIdentityRegistry}.
     */
    function setIdentityRegistry(address _identityRegistry) external override onlyAdmins {
        tokenIdentityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
    }

    /**
     *  @dev See {IToken-setCompliance}.
     */
    function setCompliance(address _compliance) external override onlyAdmins {
        tokenCompliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    /**
     *  @dev See {IToken-recoveryAddress}.
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external override onlyAdmins returns (bool) {
        require(balanceOf(_lostWallet) != 0, "no tokens to recover");
        IIdentity _onchainID = IIdentity(_investorOnchainID);
        bytes32 _key = keccak256(abi.encode(_newWallet));
        if (_onchainID.keyHasPurpose(_key, 1)) {
            uint256 investorTokens = balanceOf(_lostWallet);
            uint256 _frozenTokens = frozenTokens[_lostWallet];
            tokenIdentityRegistry.registerIdentity(_newWallet, _onchainID, tokenIdentityRegistry.investorCountry(_lostWallet));
            tokenIdentityRegistry.deleteIdentity(_lostWallet);
            forcedTransfer(_lostWallet, _newWallet, investorTokens);
            if (_frozenTokens > 0) {
                freezePartialTokens(_newWallet, _frozenTokens);
            }
            if (frozen[_lostWallet] == true) {
                setAddressFrozen(_newWallet, true);
            }
            emit RecoverySuccess(_lostWallet, _newWallet, _investorOnchainID);
            return true;
        }
        revert("Recovery not possible");
    }

    function authorizeCountryForToken(uint16 _countryToWhitelist) public onlyAdmins{
        ICompliance(tokenCompliance).authorizeCountry(_countryToWhitelist);
    }

    function authorizeCountriesForToken(uint16[] calldata _countries) public onlyAdmins{
            ICompliance(tokenCompliance).authorizeCountries(_countries);
    }

    function removeAuthorizedCountryForToken(uint16 _countryToRemove) public onlyAdmins {
        ICompliance(tokenCompliance).removeAuthorizedCountry(_countryToRemove);
    }

    function isAuthorizedCountry(uint16 _countryCode) public view returns(bool) {
        return ICompliance(tokenCompliance).isAuthorizedCountry(_countryCode);
    }

    /**
     *  @dev See {IToken-transferOwnershipOnTokenContract}.
     */
    function transferOwnershipOnTokenContract(address _newOwner) external override onlyAdmins {
        transferOwnership(_newOwner);
    }

    function addAdmin(address _agent) external override{
        addSubAdmin(_agent);
    }

    function revokeAdmin(address _agent) external override{
        revokeSubAdmin(_agent);
    }

    function addTokenizationAgentOnToken(address _userAddress) external override{
        addTokenizationAgent(_userAddress);
    }

    function removeTokenizationAgentOnToken(address _userAddress) external override{
        removeTokenizationAgent(_userAddress);
    }

    function addTransferAgentOnToken(address _userAddress) external override{
        addTransferAgent(_userAddress);
    }

    function removeTransferAgentOnToken(address _userAddress) external override{
        removeTransferAgent(_userAddress);
    }

    function setRolesToTokenAgent(address _userAddress, bytes32[] memory roles) external override {
        setRolesToAgent(_userAddress, roles);
    }

    function revokeRolesOnTokenAgent(address _userAddress, bytes32[] memory roles) external override {
        revokeRolesOnAgent(_userAddress, roles);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}
