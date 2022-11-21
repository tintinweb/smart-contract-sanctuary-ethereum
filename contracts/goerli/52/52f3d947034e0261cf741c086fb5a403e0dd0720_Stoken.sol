// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Stoken is ERC20 {
    constructor() ERC20("Stoken", "ST") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}