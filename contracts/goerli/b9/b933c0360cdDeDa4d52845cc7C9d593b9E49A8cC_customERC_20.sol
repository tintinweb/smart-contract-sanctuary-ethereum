// SPDX-License-Identifier: MIT

// Version
pragma solidity ^0.8.4;

import "./ERC_20.sol";

contract customERC_20 is ERC20{
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){
        _mint(msg.sender, _totalSupply * (uint256(10) ** 18));
    }
}