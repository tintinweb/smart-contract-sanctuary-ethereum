// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract REC20Token is ERC20 {
    constructor(uint256 initialSupply) ERC20(unicode"IDChats", "IDC") {
        _mint(msg.sender, initialSupply);
    }
}