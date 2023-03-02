// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract USDTD is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100000000 * 10 ** uint(decimals()));
    }
}