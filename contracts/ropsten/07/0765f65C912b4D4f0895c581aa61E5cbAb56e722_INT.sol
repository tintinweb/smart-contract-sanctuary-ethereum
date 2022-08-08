// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract INT is ERC20{
    constructor(uint initialSupply) ERC20("Intern token", "INT"){
        mint(owner, initialSupply);
    }
}