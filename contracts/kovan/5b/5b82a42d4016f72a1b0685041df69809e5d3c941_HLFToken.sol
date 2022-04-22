// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20.sol";

contract HLFToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply * 10**uint256(decimals()));
    }
}