// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract X5_v0 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        // ERC20 tokens have N decimals 
        // number of tokens minted = initialSupply * 10^N
        _mint(msg.sender, initialSupply * 10**uint(decimals()));
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
}