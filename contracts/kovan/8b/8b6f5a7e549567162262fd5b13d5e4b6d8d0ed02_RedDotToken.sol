// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

// import "./Ownable.sol";

contract RedDotToken is ERC20("RedDot Token", "RDX") {
    constructor() {
        _mint(msg.sender, 10000000 * 10**12);
    }
}