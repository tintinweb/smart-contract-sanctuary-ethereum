// SPDX-License-Identifier: MIT
import "./ERC20.sol";
pragma solidity >=0.8.0;


contract MyERC20 is ERC20 {
    constructor() ERC20("test", unicode"👋") {
        _mint(msg.sender, 1000000000000);
    }
}