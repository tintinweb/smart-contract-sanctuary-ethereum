// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";

contract Token is ERC20 {

    uint256 public constant MulByDec = 10**18;

    constructor(
        string memory name, 
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(_msgSender(), initialSupply*MulByDec);
    }
}