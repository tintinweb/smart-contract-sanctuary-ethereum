// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract HANKYPANKY is ERC20 {
    constructor(uint256 initialSupply) ERC20("HANKY", "PANKY") {
        _mint(msg.sender, initialSupply);
    }
}

// (3,3) Together