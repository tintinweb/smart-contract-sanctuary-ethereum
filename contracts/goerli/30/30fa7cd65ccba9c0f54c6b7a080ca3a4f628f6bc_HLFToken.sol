// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

//标准的ERC20代币
contract HLFToken is ERC20 {
    // "lfhuangToken","HLF","1000000000"
    constructor(
    ) ERC20("Test1", "TEST") {
        _mint(msg.sender, 1000 * 10**uint256(decimals()));
    }
}