// SPDX-License-Identifier: MIT

// Version
pragma solidity ^0.8.4;

import "./ERC_20.sol";

contract customERC_20 is ERC20{
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
        _mint(msg.sender, 3333333333000000000000000000);
    }
}