// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract GoerliINU is ERC20 {
    constructor() ERC20("GoerliINU", "GINU") {
        _mint(msg.sender, 105000000000 * 10 ** decimals());
    }
}