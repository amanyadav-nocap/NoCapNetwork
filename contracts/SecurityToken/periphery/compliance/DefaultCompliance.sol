// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/SecurityToken/interface/ICompliance.sol";
import "contracts/SecurityToken/periphery/roles/AgentRole.sol";
import "./ComplianceStorage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract DefaultCompliance is ICompliance, AgentRole, ComplianceStorage, Initializable {

    /**
     * @dev Throws if called by any address that is not a token bound to the compliance.
     */
    modifier onlyToken() {
        require(isToken(), "error : this address is not a token bound to the compliance contract");
        _;
    }

    /**
     *  this event is emitted when the holder limit is set.
     *  the event is emitted by the setHolderLimit function and by the constructor
     *  `_holderLimit` is the holder limit for this token
     */
    event ReleaseTimestampSet(uint256 _holdRelease);

    /**
     *  @dev the constructor initiates the smart contract with the initial state variables
     *  @param _token the address of the token concerned by the rules of this compliance contract
     *  @param _holdReleaseTime the holding period before transfers are allowed between accounts (minting is still allowed during this time)
     *  @param _tokenLimitPerUser the holder limit for the token concerned
     *  emits a `HolderLimitSet` event
     */
    function init(address _token, uint256 _holdReleaseTime, uint256 _tokenLimitPerUser) external initializer{
        _transferOwnership(msg.sender);
        token = IToken(_token);
        bindToken(_token);
        addSubAdmin(msg.sender);
        _tokenLimit = _tokenLimitPerUser;
        _identityRegistry = token.identityRegistry();
        _holdRelease = _holdReleaseTime;
        emit ReleaseTimestampSet(_holdRelease);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function isTokenAgent(address _user) public view override returns (bool) {
        return hasRole(Agent_Role, _user);
    }

    /**
     *  @dev See {ICompliance-isTokenBound}.
     */
    function isTokenBound(address _token) public view override returns (bool) {
        return (_tokensBound[_token]);
    }

    /**
     *  @dev See {ICompliance-addTokenAgent}.
     */
    function addTokenAgent(address _user) external override onlyAdmins {
        require(!isTokenAgent(_user), "This Agent is already registered");
        addAgent(_user);
        emit TokenAgentAdded(_user);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function removeTokenAgent(address _user) external override onlyAdmins {
        require(isTokenAgent(_user), "This Agent is not registered yet");
        removeAgent(_user);
        emit TokenAgentRemoved(_user);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function bindToken(address _token) public override onlyAdmins {
        require(!_tokensBound[_token], "This token is already bound");
        _tokensBound[_token] = true;
        emit TokenBound(_token);
    }

    /**
     *  @dev See {ICompliance-isTokenAgent}.
     */
    function unbindToken(address _token) public override onlyAdmins {
        require(_tokensBound[_token], "This token is not bound yet");
        _tokensBound[_token] = false;
        emit TokenUnbound(_token);
    }

    /**
     *  @dev Returns true if the sender corresponds to a token that is bound with the Compliance contract
     */
    function isToken() internal view returns (bool) {
        return isTokenBound(msg.sender);
    }

    /**
     *  @dev returns the amount of token holders
     */
    function holderCount() public view returns (uint256) {
        return _shareholders.length;
    }

    /**
     *  @dev By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return `address` the address of the token holder with the given index.
     */
    function holderAt(uint256 index) external view returns (address) {
        require(index < _shareholders.length, "shareholder doesn\"t exist");
        return _shareholders[index];
    }

    /**
     *  @dev If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it"s not already.
     */
    function updateShareholders(address addr) internal {
        if (_holderIndices[addr] == 0) {
            _shareholders.push(addr);
            _holderIndices[addr] = _shareholders.length;
            uint16 country = _identityRegistry.investorCountry(addr);
            _countryShareHolders[country]++;
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     *  @dev see https://ethereum.stackexchange.com/a/39311
     */
    function pruneShareholders(address addr) internal {
        require(_holderIndices[addr] != 0, "Shareholder does not exist");
        uint256 balance = token.balanceOf(addr);
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = _holderIndices[addr] - 1;
        uint256 lastIndex = _shareholders.length - 1;
        address lastHolder = _shareholders[lastIndex];
        _shareholders[holderIndex] = lastHolder;
        _holderIndices[lastHolder] = _holderIndices[addr];
        _shareholders.pop();
        _holderIndices[addr] = 0;
        uint16 country = _identityRegistry.investorCountry(addr);
        _countryShareHolders[country]--;
    }

    /**
     *  @dev get the amount of shareholders in a country
     *  @param index the index of the country, following ISO 3166-1
     */
    function getShareholderCountByCountry(uint16 index) external view returns (uint256) {
        return _countryShareHolders[index];
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     *  @return true if the amount of holders post-transfer is less or
     *  equal to the maximum amount of token holders
     */
    function canTransfer(
        address /* _from */,
        address _to,
        uint256 _value
    ) external view override returns (bool) {
        uint16 country = _identityRegistry.investorCountry(_to);
        if(!isAuthorizedCountry(country)) {
            return false;
        }
        if(_holdRelease <= block.timestamp) {
            if(_tokenLimit > 0) {
                if(token.balanceOf(_to) + _value > _tokenLimit) {
                    return false;
                }
            }
        } else {
            return false;
        }
        return true;
    }

    /**
     * @dev See {ICompliance-canMint}.
     * @return true if the mint is allowed
     */
    function canMint(
        address /* _from */,
        address _to,
        uint256 _value
    ) external view override returns (bool) {
        uint16 country = _identityRegistry.investorCountry(_to);
        if(!isAuthorizedCountry(country)) {
            return false;
        }
        if(_tokenLimit > 0) {
            if(token.balanceOf(_to) + _value > _tokenLimit) {
                return false;
            }
        }
        return true;
    }

    /**
     *  @dev See {ICompliance-transferred}.
     *  updates the counter of shareholders if necessary
     */
    function transferred(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyToken {
        if(_value>0){
         updateShareholders(_to);
        }
         pruneShareholders(_from);
    }

    /**
     *  @dev See {ICompliance-created}.
     *  updates the counter of shareholders if necessary
     */
    function created(address _to, uint256 _value) external override onlyToken {
        require(_value > 0, "No token created");
        updateShareholders(_to);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     *  updates the counter of shareholders if necessary
     */
    function destroyed(address _from, uint256 /* _value */) external override onlyToken {
        pruneShareholders(_from);
    }

    /**
     *  @dev See {ICompliance-transferOwnershipOnComplianceContract}.
     */
    function transferOwnershipOnComplianceContract(address newOwner) external override onlyAdmins {
        transferOwnership(newOwner);
    }

    function updateReleaseTimestamp(uint256 _timestamp) public override onlyAdmins {
        require(_timestamp > block.timestamp, "invalid timestamp");
        _holdRelease = _timestamp;
    }

    function updateHolderLimit(uint256 _newHolderLimit) public override onlyAdmins {
        _tokenLimit = _newHolderLimit;
    }

    function authorizeCountry(uint16 _countryToWhitelist) public onlyAgent {
        _authorizedCountries[_countryToWhitelist] = true;
    }

    function authorizeCountries(uint16[] calldata _countries) public onlyAgent {
        uint length = _countries.length;
        require(length > 0, "invalid country data");
        for (uint i; i < length; i++) {
            _authorizedCountries[_countries[i]] = true;
        }
    }

    function removeAuthorizedCountry(uint16 _countryToRemove) public onlyAgent {
        _authorizedCountries[_countryToRemove] = false;
    }

    function isAuthorizedCountry(uint16 _countryCode) public view returns(bool) {
        return _authorizedCountries[_countryCode];
    }

    function addAgentOnComplianceContract(address _agent) external override onlyAdmins {
        addAgent(_agent);
    }

    function removeAgentOnComplianceContract(address _agent) external override onlyAdmins {
        removeAgent(_agent);
    }

    function addSubAdminOnCompliance(address _userAddress) external override onlyAdmins {
        addSubAdmin(_userAddress);
        addAgent(_userAddress);
    }

    function revokeSubAdminOnCompliance(address _SubOwner) external override onlyAdmins {
        revokeSubAdmin(_SubOwner);
        removeAgent(_SubOwner);
    }

}
