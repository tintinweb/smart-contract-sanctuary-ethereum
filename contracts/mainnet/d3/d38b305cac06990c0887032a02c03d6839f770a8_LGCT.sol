// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract LGCT is ERC20 {
    constructor() ERC20("LEGACY TOKEN", "LGCT") {
        _mint(msg.sender, 720000000 ether);
    }
}