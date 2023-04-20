//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20{

    constructor(string memory name, string memory symbol, uint amount) ERC20(name,symbol) {
         
         _mint(msg.sender, amount*10**18);
    }

    function burn(address _from, uint amount) external {
        _burn(_from, amount);
    }
}