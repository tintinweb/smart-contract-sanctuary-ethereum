// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract Token is ERC20 {
     uint256 public _totalSupply;  
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _totalSupply = 5000000000000;  //gwei
        _mint(msg.sender, 80 * 10**uint(decimals()));
    }
}