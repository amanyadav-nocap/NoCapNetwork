//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    address public admin;

    constructor() ERC20("USDT", "USDT") {
        _mint(msg.sender, (10 * 10**6) * 10**6);
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    receive() payable external {

    }
}
