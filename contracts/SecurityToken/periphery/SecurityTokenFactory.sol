//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/Interfaces/ITokenST.sol";
import "contracts/Interfaces/ICompliance.sol";
import "contracts/Interfaces/INoCapFactory.sol";
import "hardhat/console.sol";

contract NoCapSecurityTokenFactory is Initializable, OwnableUpgradeable {

    address tokenTemplate;
    address complianceTemplate;
    address admin;
    address identityRegistry;
    address noCapFactory;
    address marketplace;
    uint16[] authorizedCountries;

    mapping(address=>bool) public isNoCapNFT;
    
    mapping(address=> mapping(uint=>address)) public NFTOwnerTokenContracts;

    mapping(address=>mapping(uint=>address)) public NFTTokenCompliance;

    modifier onlyAdmin {
        require(msg.sender==admin,"Not the admin.");
        _;
    }

    function init(address _tokenTemplate,address _complianceTemplate, address _admin,address _identityRegistry, address _marketplace,address _noCapFactroy) external {
        require(_tokenTemplate!=address(0),"Zero Address.");
        require(_admin!=address(0),"Zero Address.");
        tokenTemplate = _tokenTemplate;
        admin = _admin;
        identityRegistry = _identityRegistry;
        marketplace = _marketplace;
        complianceTemplate = _complianceTemplate;
        noCapFactory = _noCapFactroy;
    } 

    function deployTokenForNFT(string memory _name, string memory _symbol,uint8 _decimals, uint256 _tokenId,uint256 _maxFractions) external returns(address) {
        require(INoCapFactory(noCapFactory).checkNoCapNFT(msg.sender),"Only NoCap NFT allowed to call!");
        bytes32 salt = keccak256(abi.encodePacked(msg.sender,_tokenId));
        address tokenST = ClonesUpgradeable.cloneDeterministic(tokenTemplate, salt);
        bytes32 salt2 = keccak256((abi.encodePacked(tokenST,_tokenId)));
        address compliance = ClonesUpgradeable.cloneDeterministic(complianceTemplate, salt2);
        NFTOwnerTokenContracts[msg.sender][_tokenId] = tokenST;
        NFTTokenCompliance[msg.sender][_tokenId] = compliance;
        ITokenST(tokenST).init(identityRegistry, compliance, _name, _symbol, _decimals, tokenST, _maxFractions,marketplace,msg.sender,address(this));
        ICompliance(compliance).init(tokenST, block.timestamp, _maxFractions);
        ICompliance(compliance).addAgentOnComplianceContract(address(this));
        ICompliance(compliance).authorizeCountries(authorizedCountries);
        // ICompliance(compliance).addTokenAgent(msg.sender);
       
        return tokenST;
        
    }

    function addAuthorizedCountries(uint16[] memory _countries) external onlyAdmin {
         uint length = _countries.length;
         for(uint i= 0; i<length; i++){
            authorizedCountries.push(_countries[i]);
         }
    }

    
}